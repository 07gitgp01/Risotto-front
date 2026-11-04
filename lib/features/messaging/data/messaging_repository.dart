import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'messaging_models.dart';

/// Conversations and messages. Every method throws [ApiException] on failure.
/// Messages are sent over HTTP (retried and refreshed by dio); new messages and
/// read receipts arrive in real time over the WebSocket.
abstract interface class MessagingRepository {
  Future<List<Conversation>> conversations();

  Future<Conversation> start(String userId);

  Future<Conversation> get(String conversationId);

  Future<MessagePage> history(String conversationId, {String? before});

  /// [clientId] makes a retry safe: the server stores the message once.
  Future<ChatMessage> send(
    String conversationId,
    String body, {
    String? replyToId,
    String? clientId,
  });

  Future<ChatMessage> edit(
    String conversationId,
    String messageId,
    String body,
  );

  /// Deletes for everyone; returns the emptied message.
  Future<ChatMessage> delete(String conversationId, String messageId);

  /// Sets my reaction, or removes it when [emoji] is null.
  Future<ChatMessage> react(
    String conversationId,
    String messageId,
    String? emoji,
  );

  Future<void> markRead(String conversationId);

  /// Whether my online status and last seen are shared (reciprocal).
  Future<bool> sharePresence();

  Future<bool> setSharePresence(bool share);
}

class DioMessagingRepository implements MessagingRepository {
  DioMessagingRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Conversation>> conversations() => guardApi(() async {
    final response = await _dio.get<List<dynamic>>('/conversations');
    return response.data!
        .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
        .toList();
  });

  @override
  Future<Conversation> start(String userId) => guardApi(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/conversations',
      data: {'userId': userId},
    );
    return Conversation.fromJson(response.data!);
  });

  @override
  Future<Conversation> get(String conversationId) => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/conversations/$conversationId',
    );
    return Conversation.fromJson(response.data!);
  });

  @override
  Future<MessagePage> history(String conversationId, {String? before}) =>
      guardApi(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/conversations/$conversationId/messages',
          queryParameters: {'limit': 30, 'before': ?before},
        );
        return MessagePage.fromJson(response.data!);
      });

  @override
  Future<ChatMessage> send(
    String conversationId,
    String body, {
    String? replyToId,
    String? clientId,
  }) => guardApi(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/conversations/$conversationId/messages',
      data: {'body': body, 'replyToId': ?replyToId, 'clientId': ?clientId},
    );
    return ChatMessage.fromJson(response.data!);
  });

  @override
  Future<ChatMessage> edit(
    String conversationId,
    String messageId,
    String body,
  ) => guardApi(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/conversations/$conversationId/messages/$messageId',
      data: {'body': body},
    );
    return ChatMessage.fromJson(response.data!);
  });

  @override
  Future<ChatMessage> delete(String conversationId, String messageId) =>
      guardApi(() async {
        final response = await _dio.delete<Map<String, dynamic>>(
          '/conversations/$conversationId/messages/$messageId',
        );
        return ChatMessage.fromJson(response.data!);
      });

  @override
  Future<ChatMessage> react(
    String conversationId,
    String messageId,
    String? emoji,
  ) => guardApi(() async {
    final path = '/conversations/$conversationId/messages/$messageId/reaction';
    final response = emoji == null
        ? await _dio.delete<Map<String, dynamic>>(path)
        : await _dio.put<Map<String, dynamic>>(path, data: {'emoji': emoji});
    return ChatMessage.fromJson(response.data!);
  });

  @override
  Future<bool> sharePresence() => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>('/presence/settings');
    return response.data!['sharePresence'] as bool;
  });

  @override
  Future<bool> setSharePresence(bool share) => guardApi(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/presence/settings',
      data: {'sharePresence': share},
    );
    return response.data!['sharePresence'] as bool;
  });

  @override
  Future<void> markRead(String conversationId) =>
      guardApi(() => _dio.post<void>('/conversations/$conversationId/read'));
}

final messagingRepositoryProvider = Provider<MessagingRepository>(
  (ref) => DioMessagingRepository(ref.watch(dioProvider)),
);
