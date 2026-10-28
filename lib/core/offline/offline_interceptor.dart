import 'package:dio/dio.dart';

import '../storage/session_storage.dart';
import 'response_cache.dart';

/// Header set on responses served from the offline cache.
const offlineCacheHeader = 'x-risotto-offline-cache';

/// Keeps the last response of read-only screens and serves it when the API cannot be
/// reached, so the app stays usable offline (read-only). Also reports connectivity.
class OfflineInterceptor extends Interceptor {
  OfflineInterceptor({
    required ResponseCache cache,
    required SessionStorage storage,
    required void Function() onOffline,
    required void Function() onOnline,
  }) : _cache = cache,
       _storage = storage,
       _onOffline = onOffline,
       _onOnline = onOnline;

  final ResponseCache _cache;
  final SessionStorage _storage;
  final void Function() _onOffline;
  final void Function() _onOnline;

  /// GET routes whose last response is kept (the first page only for histories).
  static final _cacheable = [
    RegExp(r'^/dashboard$'),
    RegExp(r'^/users/me$'),
    RegExp(r'^/profiles/me$'),
    RegExp(r'^/profiles/[0-9a-fA-F-]+$'),
    RegExp(r'^/conversations$'),
    RegExp(r'^/conversations/[0-9a-fA-F-]+$'),
    RegExp(r'^/conversations/[0-9a-fA-F-]+/messages$'),
    RegExp(r'^/contacts$'),
    RegExp(r'^/contacts/card/me$'),
    RegExp(r'^/qr/me$'),
    RegExp(r'^/connections$'),
    RegExp(r'^/connections/requests$'),
    RegExp(r'^/notifications$'),
  ];

  static bool isCacheable(RequestOptions options) =>
      options.method == 'GET' &&
      options.responseType != ResponseType.bytes &&
      // Older pages are not kept: only what a screen shows first.
      !options.queryParameters.containsKey('before') &&
      _cacheable.any((pattern) => pattern.hasMatch(options.path));

  static String keyOf(RequestOptions options) {
    final query = options.queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '${options.path}?${query.map((e) => '${e.key}=${e.value}').join('&')}';
  }

  static bool isConnectivityError(DioException error) => switch (error.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => true,
    _ => false,
  };

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    _onOnline();
    final options = response.requestOptions;
    if (isCacheable(options) && response.statusCode == 200) {
      final userId = (await _storage.read())?.user.id;
      if (userId != null) {
        try {
          await _cache.write(userId, keyOf(options), response.data);
        } on Object {
          // The cache is best effort.
        }
      }
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!isConnectivityError(err)) {
      if (err.response != null) {
        _onOnline();
      }
      return handler.next(err);
    }
    _onOffline();
    final options = err.requestOptions;
    if (isCacheable(options)) {
      final userId = (await _storage.read())?.user.id;
      final cached = userId == null
          ? null
          : await _cache.read(userId, keyOf(options));
      if (cached != null) {
        return handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: cached,
            statusCode: 200,
            headers: Headers.fromMap({
              offlineCacheHeader: ['1'],
            }),
          ),
        );
      }
    }
    handler.next(err);
  }
}
