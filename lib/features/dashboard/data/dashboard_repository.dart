import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import 'dashboard_models.dart';

abstract interface class DashboardRepository {
  /// Throws [ApiException].
  Future<Dashboard> load();
}

class DioDashboardRepository implements DashboardRepository {
  DioDashboardRepository(this._dio);

  final Dio _dio;

  @override
  Future<Dashboard> load() => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>('/dashboard');
    return Dashboard.fromJson(response.data!);
  });
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DioDashboardRepository(ref.watch(dioProvider)),
);
