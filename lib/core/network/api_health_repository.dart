import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_interceptor.dart';
import 'dio_provider.dart';

/// Checks that the API (and its database and Redis) is reachable.
abstract interface class ApiHealthRepository {
  Future<bool> isHealthy();
}

class DioApiHealthRepository implements ApiHealthRepository {
  DioApiHealthRepository(this._dio);

  final Dio _dio;

  @override
  Future<bool> isHealthy() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/health',
        options: Options(extra: {skipAuthKey: true}),
      );
      return response.statusCode == 200 && response.data?['status'] == 'ok';
    } on DioException {
      return false;
    }
  }
}

final apiHealthRepositoryProvider = Provider<ApiHealthRepository>(
  (ref) => DioApiHealthRepository(ref.watch(dioProvider)),
);

/// Result of the API health check; `ref.invalidate` it to retry.
final apiHealthProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(apiHealthRepositoryProvider).isHealthy(),
);
