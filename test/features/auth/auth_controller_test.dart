import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/core/network/api_exception.dart';
import 'package:risotto/core/storage/session_storage.dart';
import 'package:risotto/features/auth/application/auth_controller.dart';
import 'package:risotto/features/auth/data/auth_models.dart';
import 'package:risotto/features/auth/data/auth_repository.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/in_memory_session_storage.dart';

void main() {
  late FakeAuthRepository repository;
  late InMemorySessionStorage storage;

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        sessionStorageProvider.overrideWithValue(storage),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Reads the controller and lets the startup restore complete.
  Future<AuthState> settle(ProviderContainer container) async {
    container.read(authControllerProvider);
    await pumpEventQueue();
    return container.read(authControllerProvider);
  }

  setUp(() {
    repository = FakeAuthRepository();
    storage = InMemorySessionStorage();
  });

  group('startup', () {
    test(
      'starts unknown, then unauthenticated without a stored session',
      () async {
        final container = createContainer();
        expect(container.read(authControllerProvider), isA<AuthUnknown>());
        expect(await settle(container), isA<Unauthenticated>());
      },
    );

    test('restores the stored session and refreshes the user', () async {
      storage.session = testSession();
      repository.user = const AuthUser(id: 'user-1', email: 'new@example.com');
      final state = await settle(createContainer());

      expect(state, isA<Authenticated>());
      expect((state as Authenticated).user.email, 'new@example.com');
      expect(storage.session!.user.email, 'new@example.com');
    });

    test('stays signed in offline', () async {
      storage.session = testSession();
      repository.failWith = const ApiException(ApiErrorKind.network);
      final state = await settle(createContainer());

      expect(state, isA<Authenticated>());
      expect(storage.session, isNotNull);
    });

    test('signs out when the server rejects the session', () async {
      storage.session = testSession();
      repository.failWith = const ApiException(ApiErrorKind.unauthorized);
      expect(await settle(createContainer()), isA<Unauthenticated>());
      expect(storage.session, isNull);
    });
  });

  test(
    'login normalizes the email, stores the session, authenticates',
    () async {
      final container = createContainer();
      await settle(container);

      await container
          .read(authControllerProvider.notifier)
          .login(email: '  Alice@Example.com ', password: 'risotto-2026');

      expect(repository.lastArgs['email'], 'alice@example.com');
      expect(storage.session!.tokens.refreshToken, 'refresh-1');
      expect(container.read(authControllerProvider), isA<Authenticated>());
    },
  );

  test('a failed login stays unauthenticated and stores nothing', () async {
    final container = createContainer();
    await settle(container);
    repository.failWith = const ApiException(ApiErrorKind.unauthorized);

    await expectLater(
      container
          .read(authControllerProvider.notifier)
          .login(email: 'a@b.co', password: 'x'),
      throwsA(isA<ApiException>()),
    );
    expect(container.read(authControllerProvider), isA<Unauthenticated>());
    expect(storage.session, isNull);
  });

  test('register stores the session and authenticates', () async {
    final container = createContainer();
    await settle(container);
    await container
        .read(authControllerProvider.notifier)
        .register(email: 'bob@example.com', password: 'risotto-2026');
    expect(repository.calls, contains('register'));
    expect(container.read(authControllerProvider), isA<Authenticated>());
  });

  test(
    'logout revokes the session on the server and clears it locally',
    () async {
      storage.session = testSession();
      final container = createContainer();
      await settle(container);

      await container.read(authControllerProvider.notifier).logout();

      expect(repository.calls, contains('logout'));
      expect(repository.lastArgs['refreshToken'], 'refresh-1');
      expect(storage.session, isNull);
      expect(container.read(authControllerProvider), isA<Unauthenticated>());
    },
  );

  test(
    'logout still signs out locally when the server is unreachable',
    () async {
      storage.session = testSession();
      final container = createContainer();
      await settle(container);
      repository.failWith = const ApiException(ApiErrorKind.network);

      await container.read(authControllerProvider.notifier).logout();

      expect(storage.session, isNull);
      expect(container.read(authControllerProvider), isA<Unauthenticated>());
    },
  );

  test('session expiry reported by the HTTP layer signs out', () async {
    storage.session = testSession();
    final container = createContainer();
    await settle(container);

    container.read(authControllerProvider.notifier).onSessionExpired();
    expect(container.read(authControllerProvider), isA<Unauthenticated>());
  });
}
