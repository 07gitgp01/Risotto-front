import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/realtime_client.dart';
import '../../auth/application/auth_controller.dart';
import '../data/messaging_models.dart';
import '../data/messaging_repository.dart';

const _messagingEvents = {'message:new', 'conversation:read'};

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

class ChatState {
  const ChatState({
    required this.conversation,
    required this.messages,
    this.nextCursor,
    this.otherLastReadAt,
    this.loadingMore = false,
  });

  final Conversation conversation;

  /// Newest first (the list is displayed reversed).
  final List<ChatMessage> messages;
  final String? nextCursor;
  final DateTime? otherLastReadAt;
  final bool loadingMore;

  bool get hasMore => nextCursor != null;

  ChatState copyWith({
    List<ChatMessage>? messages,
    String? nextCursor,
    bool clearCursor = false,
    DateTime? otherLastReadAt,
    bool? loadingMore,
  }) => ChatState(
    conversation: conversation,
    messages: messages ?? this.messages,
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    otherLastReadAt: otherLastReadAt ?? this.otherLastReadAt,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// One open conversation: history, live updates, sending and read receipts.
class ChatController extends AsyncNotifier<ChatState> {
  ChatController(this.conversationId);

  final String conversationId;

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
    );
  }

  Future<void> send(String body) async {
    final message = await _repository.send(conversationId, body.trim());
    _insert(message);
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
      state = AsyncData(
        current.copyWith(
          messages: [...current.messages, ...page.messages],
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          loadingMore: false,
        ),
      );
    } on Object {
      state = AsyncData(current.copyWith(loadingMore: false));
      rethrow;
    }
  }

  void _onEvent(RealtimeEvent event) {
    if (event.data['conversationId'] != conversationId) {
      return;
    }
    switch (event.name) {
      case 'message:new':
        final message = ChatMessage.fromJson(event.data);
        if (_insert(message) && message.senderId != _myId) {
          unawaited(_markRead());
        }
      case 'conversation:read':
        final current = state.value;
        if (current != null && event.data['userId'] != _myId) {
          state = AsyncData(
            current.copyWith(
              otherLastReadAt: DateTime.parse(event.data['readAt'] as String),
            ),
          );
        }
    }
  }

  /// The same message can arrive from the HTTP response and the socket.
  /// Returns false when it was already there.
  bool _insert(ChatMessage message) {
    final current = state.value;
    if (current == null || current.messages.any((m) => m.id == message.id)) {
      return false;
    }
    state = AsyncData(
      current.copyWith(messages: [message, ...current.messages]),
    );
    return true;
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
