import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../config/app_config.dart';
import '../offline/connectivity.dart';
import '../offline/offline_interceptor.dart';
import '../offline/response_cache.dart';
import '../storage/session_storage.dart';
import 'auth_interceptor.dart';

BaseOptions _baseOptions(AppConfig config) => BaseOptions(
  baseUrl: config.apiBaseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 15),
  sendTimeout: const Duration(seconds: 15),
  contentType: Headers.jsonContentType,
  responseType: ResponseType.json,
);

/// Shared HTTP client: adds the bearer token, refreshes the session on 401 and
/// serves the last known data when offline.
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(_baseOptions(config));
  // Separate client for /auth/refresh, so a failing refresh never re-enters the interceptor.
  final refreshDio = Dio(_baseOptions(config));

  dio.interceptors.add(
    AuthInterceptor(
      storage: ref.watch(sessionStorageProvider),
      dio: dio,
      refreshDio: refreshDio,
      // Read lazily: the controller itself depends on this client.
      onSessionExpired: () =>
          ref.read(authControllerProvider.notifier).onSessionExpired(),
    ),
  );
  dio.interceptors.add(
    OfflineInterceptor(
      cache: ref.watch(responseCacheProvider),
      storage: ref.watch(sessionStorageProvider),
      onOffline: () => ref.read(offlineProvider.notifier).markOffline(),
      onOnline: () => ref.read(offlineProvider.notifier).markOnline(),
    ),
  );

  ref.onDispose(() {
    dio.close();
    refreshDio.close();
  });
  return dio;
});
