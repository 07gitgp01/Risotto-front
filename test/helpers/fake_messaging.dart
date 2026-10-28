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
  Future<ChatMessage> send(String conversationId, String body) async {
    calls.add('send');
    final failure = failSendWith;
    if (failure != null) {
      throw failure;
    }
    final message = chatMessage(
      'm${_ids++}',
      'user-1',
      body,
      at: DateTime(2026, 1, 1, 11),
    );
    messages.insert(0, message);
    return message;
  }

  @override
  Future<void> markRead(String conversationId) async {
    calls.add('markRead');
    unread = 0;
  }
}
