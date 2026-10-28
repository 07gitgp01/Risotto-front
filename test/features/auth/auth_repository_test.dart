import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/core/network/api_exception.dart';
import 'package:risotto/core/network/auth_interceptor.dart';
import 'package:risotto/features/auth/data/auth_repository.dart';

import '../../helpers/fake_http_adapter.dart';

const sessionJson = {
  'accessToken': 'a',
  'refreshToken': 'r',
  'tokenType': 'Bearer',
  'expiresIn': 900,
  'user': {'id': 'u1', 'email': 'alice@example.com', 'createdAt': '2026-01-01'},
};

void main() {
  (DioAuthRepository, FakeHttpAdapter) build(FakeHttpAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test/api'))
      ..httpClientAdapter = adapter;
    return (DioAuthRepository(dio), adapter);
  }

  test('login posts the credentials publicly and parses the session', () async {
    final (repo, adapter) = build(FakeHttpAdapter(body: sessionJson));
    final session = await repo.login(
      email: 'alice@example.com',
      password: 'pw',
    );

    final request = adapter.requests.single;
    expect(request.path, '/auth/login');
    expect(request.data, {'email': 'alice@example.com', 'password': 'pw'});
    expect(request.extra[skipAuthKey], isTrue);
    expect(session.tokens.accessToken, 'a');
    expect(session.tokens.refreshToken, 'r');
    expect(session.user.email, 'alice@example.com');
  });

  test('register posts to /auth/register', () async {
    final (repo, adapter) = build(
      FakeHttpAdapter(statusCode: 201, body: sessionJson),
    );
    await repo.register(email: 'alice@example.com', password: 'pw');
    expect(adapter.requests.single.path, '/auth/register');
  });

  test('logout sends the refresh token with authentication', () async {
    final (repo, adapter) = build(FakeHttpAdapter(statusCode: 204));
    await repo.logout('r');
    final request = adapter.requests.single;
    expect(request.path, '/auth/logout');
    expect(request.data, {'refreshToken': 'r'});
    expect(request.extra[skipAuthKey], isNot(true));
  });

  test('password reset endpoints are public', () async {
    final (repo, adapter) = build(FakeHttpAdapter(statusCode: 204));
    await repo.requestPasswordReset('alice@example.com');
    await repo.resetPassword(
      email: 'alice@example.com',
      code: '123456',
      newPassword: 'new-pass-1',
    );
    expect(adapter.paths, ['/auth/forgot-password', '/auth/reset-password']);
    expect(adapter.requests.last.data, {
      'email': 'alice@example.com',
      'code': '123456',
      'newPassword': 'new-pass-1',
    });
    expect(
      adapter.requests.map((r) => r.extra[skipAuthKey]),
      everyElement(true),
    );
  });

  test('currentUser reads /users/me', () async {
    final (repo, _) = build(
      FakeHttpAdapter(body: {'id': 'u1', 'email': 'alice@example.com'}),
    );
    final user = await repo.currentUser();
    expect(user.id, 'u1');
  });

  group('errors become ApiException', () {
    Future<ApiErrorKind> kindFor(FakeHttpAdapter adapter) async {
      final (repo, _) = build(adapter);
      try {
        await repo.login(email: 'a@b.co', password: 'x');
        fail('should throw');
      } on ApiException catch (error) {
        return error.kind;
      }
    }

    test('401', () async {
      expect(
        await kindFor(FakeHttpAdapter(statusCode: 401, body: {})),
        ApiErrorKind.unauthorized,
      );
    });

    test('409', () async {
      expect(
        await kindFor(FakeHttpAdapter(statusCode: 409, body: {})),
        ApiErrorKind.conflict,
      );
    });

    test('400', () async {
      expect(
        await kindFor(FakeHttpAdapter(statusCode: 400, body: {})),
        ApiErrorKind.invalidInput,
      );
    });

    test('429', () async {
      expect(
        await kindFor(FakeHttpAdapter(statusCode: 429, body: {})),
        ApiErrorKind.rateLimited,
      );
    });

    test('500', () async {
      expect(
        await kindFor(FakeHttpAdapter(statusCode: 500, body: {})),
        ApiErrorKind.server,
      );
    });

    test('no connection', () async {
      expect(
        await kindFor(FakeHttpAdapter(error: DioExceptionType.connectionError)),
        ApiErrorKind.network,
      );
    });
  });
}
