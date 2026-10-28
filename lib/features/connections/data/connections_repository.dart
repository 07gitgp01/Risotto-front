import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../profile/data/profile_models.dart';
import 'connections_models.dart';

/// Search, connection requests and blocks. Every method throws [ApiException].
abstract interface class ConnectionsRepository {
  Future<List<Profile>> search(String query);

  /// Exactly one of [userId] or [qrPayload].
  Future<Connection> request({
    String? userId,
    String? qrPayload,
    String? message,
  });

  Future<Connection> accept(String connectionId);

  Future<void> decline(String connectionId);

  /// Cancels my pending request or removes a connection.
  Future<void> remove(String connectionId);

  Future<List<Connection>> connections();

  Future<List<Connection>> requests(RequestDirection direction);

  Future<void> block(String userId);

  Future<void> unblock(String userId);

  Future<List<BlockedUser>> blocked();
}

class DioConnectionsRepository implements ConnectionsRepository {
  DioConnectionsRepository(this._dio);

  final Dio _dio;

  List<Connection> _parseConnections(List<dynamic>? data) => data!
      .map((json) => Connection.fromJson(json as Map<String, dynamic>))
      .toList();

  @override
  Future<List<Profile>> search(String query) => guardApi(() async {
    final response = await _dio.get<List<dynamic>>(
      '/users/search',
      queryParameters: {'q': query},
    );
    return response.data!
        .map((json) => Profile.fromJson(json as Map<String, dynamic>))
        .toList();
  });

  @override
  Future<Connection> request({
    String? userId,
    String? qrPayload,
    String? message,
  }) => guardApi(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/connections',
      data: {
        'userId': ?userId,
        'qrPayload': ?qrPayload,
        if (message != null && message.trim().isNotEmpty) 'message': message,
      },
    );
    return Connection.fromJson(response.data!);
  });

  @override
  Future<Connection> accept(String connectionId) => guardApi(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/connections/$connectionId/accept',
    );
    return Connection.fromJson(response.data!);
  });

  @override
  Future<void> decline(String connectionId) =>
      guardApi(() => _dio.post<void>('/connections/$connectionId/decline'));

  @override
  Future<void> remove(String connectionId) =>
      guardApi(() => _dio.delete<void>('/connections/$connectionId'));

  @override
  Future<List<Connection>> connections() => guardApi(() async {
    final response = await _dio.get<List<dynamic>>('/connections');
    return _parseConnections(response.data);
  });

  @override
  Future<List<Connection>> requests(RequestDirection direction) =>
      guardApi(() async {
        final response = await _dio.get<List<dynamic>>(
          '/connections/requests',
          queryParameters: {'direction': direction.name},
        );
        return _parseConnections(response.data);
      });

  @override
  Future<void> block(String userId) =>
      guardApi(() => _dio.post<void>('/blocks', data: {'userId': userId}));

  @override
  Future<void> unblock(String userId) =>
      guardApi(() => _dio.delete<void>('/blocks/$userId'));

  @override
  Future<List<BlockedUser>> blocked() => guardApi(() async {
    final response = await _dio.get<List<dynamic>>('/blocks');
    return response.data!
        .map((json) => BlockedUser.fromJson(json as Map<String, dynamic>))
        .toList();
  });
}

final connectionsRepositoryProvider = Provider<ConnectionsRepository>(
  (ref) => DioConnectionsRepository(ref.watch(dioProvider)),
);
