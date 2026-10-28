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

  Future<ChatMessage> send(String conversationId, String body);

  Future<void> markRead(String conversationId);
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
  Future<ChatMessage> send(String conversationId, String body) =>
      guardApi(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/conversations/$conversationId/messages',
          data: {'body': body},
        );
        return ChatMessage.fromJson(response.data!);
      });

  @override
  Future<void> markRead(String conversationId) =>
      guardApi(() => _dio.post<void>('/conversations/$conversationId/read'));
}

final messagingRepositoryProvider = Provider<MessagingRepository>(
  (ref) => DioMessagingRepository(ref.watch(dioProvider)),
);
