import 'dart:async';

import 'package:risotto/core/network/api_exception.dart';
import 'package:risotto/core/realtime/realtime_client.dart';
import 'package:risotto/features/messaging/data/messaging_models.dart';
import 'package:risotto/features/messaging/data/messaging_repository.dart';
import 'package:risotto/features/profile/data/profile_models.dart';

/// Lets a test push server events.
class FakeRealtimeClient implements RealtimeClient {
  final _controller = StreamController<RealtimeEvent>.broadcast();

  @override
  Stream<RealtimeEvent> get events => _controller.stream;

  void push(String name, Map<String, dynamic> data) =>
      _controller.add(RealtimeEvent(name, data));

  final List<(String, Map<String, dynamic>)> emitted = [];

  @override
  void emit(String event, Map<String, dynamic> data) =>
      emitted.add((event, data));

  @override
  void dispose() {}
}

ChatMessage chatMessage(
  String id,
  String senderId,
  String body, {
  String conversationId = 'conv-1',
  DateTime? at,
}) => ChatMessage(
  id: id,
  conversationId: conversationId,
  senderId: senderId,
  body: body,
  createdAt: at ?? DateTime(2026, 1, 1, 10),
);

const bobProfile = Profile(
  userId: 'bob',
  access: ProfileAccess.full,
  firstName: 'Bob',
  lastName: 'Durand',
);

/// One conversation (`conv-1`) with Bob, history served by pages of [pageSize].
class FakeMessagingRepository implements MessagingRepository {
  FakeMessagingRepository({
    List<ChatMessage>? messages,
    this.unread = 0,
    this.canSend = true,
    this.pageSize = 30,
  }) : messages = messages ?? [];

  /// Newest first.
  final List<ChatMessage> messages;
  int unread;
  bool canSend;
  final int pageSize;
  DateTime? otherLastReadAt;
  Presence? presence;
  bool sharePresenceSetting = true;
  ApiException? failSendWith;
  final List<String> calls = [];
  int _ids = 100;

  Conversation _conversation() => Conversation(
    id: 'conv-1',
    user: bobProfile,
    unreadCount: unread,
    canSend: canSend,
    updatedAt: DateTime(2026, 1, 1, 10),
    lastMessage: messages.firstOrNull,
    otherLastReadAt: otherLastReadAt,
    presence: presence,
  );

  @override
  Future<List<Conversation>> conversations() async {
    calls.add('conversations');
    return messages.isEmpty && unread == 0 && !calls.contains('start')
        ? []
        : [_conversation()];
  }

  @override
  Future<Conversation> start(String userId) async {
    calls.add('start');
    return _conversation();
  }

  @override
  Future<Conversation> get(String conversationId) async {
    calls.add('get');
    return _conversation();
  }

  @override
  Future<MessagePage> history(String conversationId, {String? before}) async {
    calls.add(before == null ? 'history' : 'history:$before');
    final start = before == null
        ? 0
        : messages.indexWhere((m) => m.id == before) + 1;
    final page = messages.skip(start).take(pageSize).toList();
    final hasMore = start + pageSize < messages.length;
    return MessagePage(
      messages: page,
      nextCursor: hasMore ? page.last.id : null,
      otherLastReadAt: otherLastReadAt,
    );
  }

  @override
  Future<ChatMessage> send(
    String conversationId,
    String body, {
    String? replyToId,
    String? clientId,
  }) async {
    calls.add(replyToId == null ? 'send' : 'send:reply:$replyToId');
    final failure = failSendWith;
    if (failure != null) {
      throw failure;
    }
    final existing = messages.where((m) => m.clientId == clientId).firstOrNull;
    if (clientId != null && existing != null) {
      return existing;
    }
    final replied = messages.where((m) => m.id == replyToId).firstOrNull;
    final message = ChatMessage(
      id: 'm${_ids++}',
      conversationId: conversationId,
      senderId: 'user-1',
      body: body,
      createdAt: DateTime(2026, 1, 1, 11),
      clientId: clientId,
      replyTo: replied == null
          ? null
          : MessagePreview(
              id: replied.id,
              senderId: replied.senderId,
              body: replied.body,
            ),
    );
    messages.insert(0, message);
    return message;
  }

  ChatMessage _rewrite(
    String messageId,
    ChatMessage Function(ChatMessage) change,
  ) {
    final index = messages.indexWhere((m) => m.id == messageId);
    return messages[index] = change(messages[index]);
  }

  @override
  Future<ChatMessage> edit(
    String conversationId,
    String messageId,
    String body,
  ) async {
    calls.add('edit:$messageId');
    return _rewrite(
      messageId,
      (m) => ChatMessage(
        id: m.id,
        conversationId: m.conversationId,
        senderId: m.senderId,
        body: body,
        createdAt: m.createdAt,
        editedAt: DateTime(2026, 1, 1, 12),
        replyTo: m.replyTo,
        reactions: m.reactions,
        clientId: m.clientId,
      ),
    );
  }

  @override
  Future<ChatMessage> delete(String conversationId, String messageId) async {
    calls.add('delete:$messageId');
    return _rewrite(
      messageId,
      (m) => ChatMessage(
        id: m.id,
        conversationId: m.conversationId,
        senderId: m.senderId,
        body: '',
        createdAt: m.createdAt,
        deleted: true,
        clientId: m.clientId,
      ),
    );
  }

  @override
  Future<ChatMessage> react(
    String conversationId,
    String messageId,
    String? emoji,
  ) async {
    calls.add('react:$messageId:${emoji ?? '-'}');
    return _rewrite(
      messageId,
      (m) => ChatMessage(
        id: m.id,
        conversationId: m.conversationId,
        senderId: m.senderId,
        body: m.body,
        createdAt: m.createdAt,
        editedAt: m.editedAt,
        replyTo: m.replyTo,
        clientId: m.clientId,
        reactions: [
          ...m.reactions.where((r) => r.userId != 'user-1'),
          if (emoji != null) Reaction(emoji: emoji, userId: 'user-1'),
        ],
      ),
    );
  }

  @override
  Future<bool> sharePresence() async => sharePresenceSetting;

  @override
  Future<bool> setSharePresence(bool share) async {
    calls.add('sharePresence:$share');
    return sharePresenceSetting = share;
  }

  @override
  Future<void> markRead(String conversationId) async {
    calls.add('markRead');
    unread = 0;
  }
}
