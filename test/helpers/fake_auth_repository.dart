import 'package:risotto/core/network/api_exception.dart';
import 'package:risotto/features/auth/data/auth_models.dart';
import 'package:risotto/features/auth/data/auth_repository.dart';

import 'in_memory_session_storage.dart';

/// Scriptable AuthRepository: set [failWith] to make the next calls throw.
class FakeAuthRepository implements AuthRepository {
  ApiException? failWith;
  AuthUser user = testUser;
  final List<String> calls = [];
  Map<String, String> lastArgs = {};

  Future<T> _run<T>(String name, Map<String, String> args, T Function() ok) {
    calls.add(name);
    lastArgs = args;
    final failure = failWith;
    return failure != null ? Future.error(failure) : Future.value(ok());
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) => _run(
    'register',
    {'email': email, 'password': password},
    () => testSession(
      user: AuthUser(id: user.id, email: email),
    ),
  );

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) => _run(
    'login',
    {'email': email, 'password': password},
    () => testSession(
      user: AuthUser(id: user.id, email: email),
    ),
  );

  @override
  Future<void> logout(String refreshToken) =>
      _run('logout', {'refreshToken': refreshToken}, () {});

  @override
  Future<void> requestPasswordReset(String email) =>
      _run('requestPasswordReset', {'email': email}, () {});

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _run('resetPassword', {
    'email': email,
    'code': code,
    'newPassword': newPassword,
  }, () {});

  @override
  Future<AuthUser> currentUser() => _run('currentUser', {}, () => user);
}
