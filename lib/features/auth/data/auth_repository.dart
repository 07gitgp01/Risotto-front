import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../core/network/dio_provider.dart';
import 'auth_models.dart';

/// Auth endpoints of the API. Every method throws [ApiException] on failure.
abstract interface class AuthRepository {
  Future<AuthSession> register({
    required String email,
    required String password,
  });

  Future<AuthSession> login({required String email, required String password});

  Future<void> logout(String refreshToken);

  Future<void> requestPasswordReset(String email);

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<AuthUser> currentUser();
}

class DioAuthRepository implements AuthRepository {
  DioAuthRepository(this._dio);

  final Dio _dio;

  static final _public = Options(extra: {skipAuthKey: true});

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) => _openSession('/auth/register', email, password);

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) => _openSession('/auth/login', email, password);

  @override
  Future<void> logout(String refreshToken) => guardApi(
    () => _dio.post<void>('/auth/logout', data: {'refreshToken': refreshToken}),
  );

  @override
  Future<void> requestPasswordReset(String email) => guardApi(
    () => _dio.post<void>(
      '/auth/forgot-password',
      data: {'email': email},
      options: _public,
    ),
  );

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => guardApi(
    () => _dio.post<void>(
      '/auth/reset-password',
      data: {'email': email, 'code': code, 'newPassword': newPassword},
      options: _public,
    ),
  );

  @override
  Future<AuthUser> currentUser() => guardApi(() async {
    final response = await _dio.get<Map<String, dynamic>>('/users/me');
    return AuthUser.fromJson(response.data!);
  });

  Future<AuthSession> _openSession(
    String path,
    String email,
    String password,
  ) => guardApi(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: {'email': email, 'password': password},
      options: _public,
    );
    return AuthSession.fromJson(response.data!);
  });
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => DioAuthRepository(ref.watch(dioProvider)),
);
