import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/offline/connectivity.dart';
import '../../../core/realtime/realtime_client.dart';
import '../../auth/application/auth_controller.dart';
import '../data/messaging_models.dart';
import '../data/messaging_repository.dart';

const _messagingEvents = {
  'message:new',
  'message:updated',
  'conversation:read',
  'presence',
};

/// My conversations, refreshed on every realtime messaging event.
class ConversationsController extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    if (ref.watch(authControllerProvider) is! Authenticated) {
      return const [];
    }
    ref.listen(realtimeEventsProvider, (_, next) {
      final event = next.value;
      if (event != null && _messagingEvents.contains(event.name)) {
        unawaited(refresh());
      }
    });
    return ref.read(messagingRepositoryProvider).conversations();
  }

  Future<void> refresh() async {
    final conversations = await AsyncValue.guard(
      () => ref.read(messagingRepositoryProvider).conversations(),
    );
    // Keep the current list if the refresh fails (offline).
    if (conversations.hasValue) {
      state = conversations;
    }
  }
}

final conversationsProvider =
    AsyncNotifierProvider<ConversationsController, List<Conversation>>(
      ConversationsController.new,
    );

final unreadMessagesCountProvider = Provider<int>(
  (ref) =>
      ref
          .watch(conversationsProvider)
          .value
          ?.fold<int>(0, (sum, c) => sum + c.unreadCount) ??
      0,
);

/// Random UUID v4, chosen by this device for each new message.
@visibleForTesting
String newClientId([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

const _unchanged = Object();

class ChatState {
  const ChatState({
    required this.conversation,
    required this.messages,
    this.nextCursor,
    this.otherLastReadAt,
    this.loadingMore = false,
    this.otherTyping = false,
    this.presence,
  });

  final Conversation conversation;

  /// Newest first (the list is displayed reversed).
  final List<ChatMessage> messages;
  final String? nextCursor;
  final DateTime? otherLastReadAt;
  final bool loadingMore;

  /// The other participant is writing (a few seconds after their last key).
  final bool otherTyping;
  final Presence? presence;

  bool get hasMore => nextCursor != null;

  ChatState copyWith({
    List<ChatMessage>? messages,
    String? nextCursor,
    bool clearCursor = false,
    DateTime? otherLastReadAt,
    bool? loadingMore,
    bool? otherTyping,
    Object? presence = _unchanged,
  }) => ChatState(
    conversation: conversation,
    messages: messages ?? this.messages,
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    otherLastReadAt: otherLastReadAt ?? this.otherLastReadAt,
    loadingMore: loadingMore ?? this.loadingMore,
    otherTyping: otherTyping ?? this.otherTyping,
    presence: identical(presence, _unchanged)
        ? this.presence
        : presence as Presence?,
  );
}

/// One open conversation: history, live updates, sending and read receipts.
class ChatController extends AsyncNotifier<ChatState> {
  ChatController(this.conversationId);

  final String conversationId;

  /// "Écrit…" disappears this long after the last typing event.
  static const typingTimeout = Duration(seconds: 6);

  /// At most one typing event per interval while the user types.
  static const typingInterval = Duration(seconds: 3);

  Timer? _typingTimer;
  DateTime _lastTypingSent = DateTime.fromMillisecondsSinceEpoch(0);

  MessagingRepository get _repository => ref.read(messagingRepositoryProvider);

  String? get _myId => switch (ref.read(authControllerProvider)) {
    Authenticated(:final user) => user.id,
    _ => null,
  };

  @override
  Future<ChatState> build() async {
    ref.listen(realtimeEventsProvider, (_, next) {
      final event = next.value;
      if (event != null) {
        _onEvent(event);
      }
    });
    // Back online: failed messages leave by themselves.
    ref.listen(offlineProvider, (previous, offline) {
      if (previous == true && !offline) {
        unawaited(retryFailed());
      }
    });
    ref.onDispose(() => _typingTimer?.cancel());

    final conversation = await _repository.get(conversationId);
    final page = await _repository.history(conversationId);
    if (conversation.unreadCount > 0) {
      unawaited(_markRead());
    }
    return ChatState(
      conversation: conversation,
      messages: page.messages,
      nextCursor: page.nextCursor,
      otherLastReadAt: page.otherLastReadAt,
      presence: conversation.presence,
    );
  }

  /// Shown at once, then confirmed by the server. On failure the message stays,
  /// marked failed, and can be retried without risk of duplicate.
  Future<void> send(String body, {ChatMessage? replyTo}) async {
    final myId = _myId;
    final text = body.trim();
    if (myId == null || text.isEmpty || state.value == null) {
      return;
    }
    final clientId = newClientId();
    final local = ChatMessage(
      id: 'local-$clientId',
      conversationId: conversationId,
      senderId: myId,
      body: text,
      createdAt: DateTime.now(),
      replyTo: replyTo == null
          ? null
          : MessagePreview(
              id: replyTo.id,
              senderId: replyTo.senderId,
              body: replyTo.body,
            ),
      clientId: clientId,
      status: SendStatus.sending,
    );
    _update((messages) => [local, ...messages]);
    await _deliver(local);
  }

  Future<void> retry(ChatMessage message) async {
    if (message.status != SendStatus.failed) {
      return;
    }
    _replace(message.id, message.copyWith(status: SendStatus.sending));
    await _deliver(message);
  }

  Future<void> retryFailed() async {
    final failed =
        state.value?.messages
            .where((m) => m.status == SendStatus.failed)
            .toList()
            .reversed ??
        const <ChatMessage>[];
    for (final message in failed) {
      try {
        await retry(message);
      } on ApiException {
        // Still failed; the bubble offers a manual retry.
      }
    }
  }

  Future<void> _deliver(ChatMessage local) async {
    try {
      final stored = await _repository.send(
        conversationId,
        local.body,
        replyToId: local.replyTo?.id,
        clientId: local.clientId,
      );
      _settle(stored);
    } on ApiException {
      _replace(local.id, local.copyWith(status: SendStatus.failed));
      rethrow;
    }
  }

  Future<void> edit(ChatMessage message, String body) async {
    final updated = await _repository.edit(
      conversationId,
      message.id,
      body.trim(),
    );
    _replace(updated.id, updated);
  }

  Future<void> delete(ChatMessage message) async {
    if (message.isLocal) {
      // Never reached the server: just drop it.
      _update((messages) => messages.where((m) => m.id != message.id).toList());
      return;
    }
    final updated = await _repository.delete(conversationId, message.id);
    _replace(updated.id, updated);
  }

  /// Same emoji again removes my reaction (like WhatsApp).
  Future<void> react(ChatMessage message, String emoji) async {
    final myId = _myId;
    final next = myId != null && message.reactionOf(myId) == emoji
        ? null
        : emoji;
    final updated = await _repository.react(conversationId, message.id, next);
    _replace(updated.id, updated);
  }

  /// Called on each keystroke; throttled.
  void notifyTyping() {
    final now = DateTime.now();
    if (now.difference(_lastTypingSent) < typingInterval) {
      return;
    }
    _lastTypingSent = now;
    ref.read(realtimeClientProvider)?.emit('typing', {
      'conversationId': conversationId,
    });
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) {
      return;
    }
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await _repository.history(
        conversationId,
        before: current.nextCursor,
      );
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(
          messages: [...latest.messages, ...page.messages],
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          loadingMore: false,
        ),
      );
    } on Object {
      state = AsyncData((state.value ?? current).copyWith(loadingMore: false));
      rethrow;
    }
  }

  void _onEvent(RealtimeEvent event) {
    final current = state.value;
    if (current == null) {
      return;
    }
    if (event.name == 'presence') {
      if (event.data['userId'] == current.conversation.user.userId) {
        final presence = event.data['presence'];
        state = AsyncData(
          current.copyWith(
            presence: presence is Map
                ? Presence.fromJson(Map<String, dynamic>.from(presence))
                : null,
          ),
        );
      }
      return;
    }
    if (event.data['conversationId'] != conversationId) {
      return;
    }
    switch (event.name) {
      case 'message:new':
        final message = ChatMessage.fromJson(event.data);
        final isNew = _settle(message);
        if (message.senderId != _myId) {
          _setTyping(false);
          if (isNew) {
            unawaited(_markRead());
          }
        }
      case 'message:updated':
        final message = ChatMessage.fromJson(event.data);
        _replace(message.id, message);
      case 'conversation:read':
        if (event.data['userId'] != _myId) {
          state = AsyncData(
            current.copyWith(
              otherLastReadAt: DateTime.parse(event.data['readAt'] as String),
            ),
          );
        }
      case 'typing':
        if (event.data['userId'] != _myId) {
          _setTyping(true);
        }
    }
  }

  void _setTyping(bool typing) {
    _typingTimer?.cancel();
    if (typing) {
      _typingTimer = Timer(typingTimeout, () => _setTyping(false));
    }
    final current = state.value;
    if (current != null && current.otherTyping != typing) {
      state = AsyncData(current.copyWith(otherTyping: typing));
    }
  }

  /// A stored message, from the HTTP response or the socket (whichever comes
  /// first): replaces its local copy or itself. Returns true when it is new.
  bool _settle(ChatMessage stored) {
    final current = state.value;
    if (current == null) {
      return false;
    }
    final index = current.messages.indexWhere(
      (m) =>
          m.id == stored.id ||
          (stored.clientId != null && m.clientId == stored.clientId),
    );
    if (index >= 0) {
      _update((messages) => [...messages]..[index] = stored);
      return false;
    }
    _update((messages) => [stored, ...messages]);
    return true;
  }

  void _replace(String id, ChatMessage message) => _update(
    (messages) => [for (final m in messages) m.id == id ? message : m],
  );

  void _update(List<ChatMessage> Function(List<ChatMessage>) change) {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(messages: change(current.messages)));
    }
  }

  Future<void> _markRead() async {
    try {
      await _repository.markRead(conversationId);
      ref.invalidate(conversationsProvider);
    } on Object {
      // Best effort: the unread badge is corrected on the next refresh.
    }
  }
}

final chatProvider = AsyncNotifierProvider.autoDispose
    .family<ChatController, ChatState, String>(ChatController.new);

/// My "share my online status" setting.
class SharePresenceController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.read(messagingRepositoryProvider).sharePresence();

  Future<void> set(bool share) async {
    final saved = await ref
        .read(messagingRepositoryProvider)
        .setSharePresence(share);
    state = AsyncData(saved);
    // What I see of others changes too (reciprocal).
    ref.invalidate(conversationsProvider);
  }
}

final sharePresenceProvider =
    AsyncNotifierProvider<SharePresenceController, bool>(
      SharePresenceController.new,
    );
