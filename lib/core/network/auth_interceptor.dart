import 'package:dio/dio.dart';

import '../../features/auth/data/auth_models.dart';
import '../storage/session_storage.dart';

/// Set `extra: {skipAuth: true}` on requests that must not carry or refresh a token
/// (login, register, refresh, password reset).
const skipAuthKey = 'skipAuth';
const _retriedKey = 'authRetried';

/// Adds the bearer token and, on 401, refreshes the session once then replays the request.
/// Concurrent 401s share a single refresh call (the refresh token is single-use).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SessionStorage storage,
    required Dio dio,
    required Dio refreshDio,
    required void Function() onSessionExpired,
  }) : _storage = storage,
       _dio = dio,
       _refreshDio = refreshDio,
       _onSessionExpired = onSessionExpired;

  final SessionStorage _storage;
  final Dio _dio;
  final Dio _refreshDio;
  final void Function() _onSessionExpired;

  Future<AuthSession?>? _pendingRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] != true) {
      final session = await _storage.read();
      if (session != null) {
        options.headers['Authorization'] =
            'Bearer ${session.tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        request.extra[skipAuthKey] == true ||
        request.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    final current = await _storage.read();
    if (current == null) {
      return handler.next(err);
    }

    // Another request may already have refreshed while this one was in flight.
    final sentToken = request.headers['Authorization'];
    final session = sentToken == 'Bearer ${current.tokens.accessToken}'
        ? await _refreshOnce(current)
        : current;

    if (session == null) {
      return handler.next(err);
    }

    try {
      final retry = await _dio.fetch<dynamic>(
        request.copyWith(
          headers: {
            ...request.headers,
            'Authorization': 'Bearer ${session.tokens.accessToken}',
          },
          extra: {...request.extra, _retriedKey: true},
        ),
      );
      handler.resolve(retry);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<AuthSession?> _refreshOnce(AuthSession current) {
    return _pendingRefresh ??= _refresh(current).whenComplete(() {
      _pendingRefresh = null;
    });
  }

  Future<AuthSession?> _refresh(AuthSession current) async {
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': current.tokens.refreshToken},
        options: Options(extra: {skipAuthKey: true}),
      );
      final session = current.copyWith(
        tokens: AuthTokens.fromJson(response.data!),
      );
      await _storage.save(session);
      return session;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        // Refresh token expired, revoked or reused: the session is over.
        await _storage.clear();
        _onSessionExpired();
      }
      return null;
    }
  }
}
