import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'notifications_models.dart';

/// In-app notifications, preferences and push device tokens. Throws [ApiException].
abstract interface class NotificationsRepository {
  Future<NotificationsPage> list({String? before});

  Future<void> markRead(String id);

  Future<void> markAllRead();

  Future<List<NotificationPreference>> preferences();

  Future<List<NotificationPreference>> updatePreferences(
    List<NotificationPreference> preferences,
  );

  Future<void> registerDevice(String token, String platform);

  Future<void> removeDevice(String token);
}

class DioNotificationsRepository implements NotificationsRepository {
  DioNotificationsRepository(this._dio);

  final Dio _dio;

  List<NotificationPreference> _parsePreferences(List<dynamic>? data) => data!
      .map((p) => NotificationPreference.fromJson(p as Map<String, dynamic>))
      .toList();

  @override
  Future<NotificationsPage> list({String? before}) => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {'before': ?before},
    );
    return NotificationsPage.fromJson(response.data!);
  });

  @override
  Future<void> markRead(String id) =>
      guardApi(() => _dio.post<void>('/notifications/$id/read'));

  @override
  Future<void> markAllRead() =>
      guardApi(() => _dio.post<void>('/notifications/read-all'));

  @override
  Future<List<NotificationPreference>> preferences() => guardApi(() async {
    final response = await _dio.get<List<dynamic>>(
      '/notifications/preferences',
    );
    return _parsePreferences(response.data);
  });

  @override
  Future<List<NotificationPreference>> updatePreferences(
    List<NotificationPreference> preferences,
  ) => guardApi(() async {
    final response = await _dio.put<List<dynamic>>(
      '/notifications/preferences',
      data: {'preferences': preferences.map((p) => p.toJson()).toList()},
    );
    return _parsePreferences(response.data);
  });

  @override
  Future<void> registerDevice(String token, String platform) => guardApi(
    () => _dio.post<void>(
      '/devices',
      data: {'token': token, 'platform': platform},
    ),
  );

  @override
  Future<void> removeDevice(String token) =>
      guardApi(() => _dio.delete<void>('/devices', data: {'token': token}));
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => DioNotificationsRepository(ref.watch(dioProvider)),
);
