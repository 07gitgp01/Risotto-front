import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'admin_models.dart';

/// Administration endpoints. The API checks the admin role on every call.
/// Every method throws [ApiException].
abstract interface class AdminRepository {
  Future<AdminStats> stats();

  Future<AdminAccountPage> accounts({
    String query = '',
    AccountFilter filter = AccountFilter.all,
    int offset = 0,
  });

  Future<void> suspend(String userId);

  Future<void> reactivate(String userId);
}

class DioAdminRepository implements AdminRepository {
  DioAdminRepository(this._dio);

  final Dio _dio;

  static const pageSize = 20;

  @override
  Future<AdminStats> stats() => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>('/admin/stats');
    return AdminStats.fromJson(response.data!);
  });

  @override
  Future<AdminAccountPage> accounts({
    String query = '',
    AccountFilter filter = AccountFilter.all,
    int offset = 0,
  }) => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/users',
      queryParameters: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        if (filter != AccountFilter.all) 'status': filter.name,
        'limit': pageSize,
        'offset': offset,
      },
    );
    return AdminAccountPage.fromJson(response.data!);
  });

  @override
  Future<void> suspend(String userId) =>
      guardApi(() => _dio.post<void>('/admin/users/$userId/suspend'));

  @override
  Future<void> reactivate(String userId) =>
      guardApi(() => _dio.post<void>('/admin/users/$userId/reactivate'));
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => DioAdminRepository(ref.watch(dioProvider)),
);

final adminStatsProvider = FutureProvider.autoDispose<AdminStats>(
  (ref) => ref.watch(adminRepositoryProvider).stats(),
);
