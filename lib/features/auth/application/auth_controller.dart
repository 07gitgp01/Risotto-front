import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/session_storage.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

sealed class AuthState {
  const AuthState();
}

/// Startup: the stored session has not been read yet.
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class Authenticated extends AuthState {
  const Authenticated(this.user);

  final AuthUser user;
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthController extends Notifier<AuthState> {
  SessionStorage get _storage => ref.read(sessionStorageProvider);
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    unawaited(_restore());
    return const AuthUnknown();
  }

  /// Starts signed in from the stored session (works offline), then refreshes the user.
  Future<void> _restore() async {
    final session = await _storage.read();
    if (session == null) {
      state = const Unauthenticated();
      return;
    }
    state = Authenticated(session.user);

    try {
      final user = await _repository.currentUser();
      final latest = await _storage.read();
      if (latest != null) {
        await _storage.save(latest.copyWith(user: user));
        state = Authenticated(user);
      }
    } on ApiException catch (error) {
      // Network errors keep the offline session; the interceptor handles expiry.
      if (error.kind == ApiErrorKind.unauthorized) {
        await _signOutLocally();
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    final session = await _repository.login(
      email: _normalize(email),
      password: password,
    );
    await _storage.save(session);
    state = Authenticated(session.user);
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    final session = await _repository.register(
      email: _normalize(email),
      password: password,
    );
    await _storage.save(session);
    state = Authenticated(session.user);
  }

  /// Always signs out locally, even if the server cannot be reached.
  Future<void> logout() async {
    final session = await _storage.read();
    if (session != null) {
      try {
        await _repository.logout(session.tokens.refreshToken);
      } on ApiException {
        // The refresh token expires on its own; never keep the user signed in.
      }
    }
    await _signOutLocally();
  }

  /// Called by the HTTP layer when the refresh token is rejected.
  void onSessionExpired() {
    state = const Unauthenticated();
  }

  Future<void> _signOutLocally() async {
    await _storage.clear();
    state = const Unauthenticated();
  }

  static String _normalize(String email) => email.trim().toLowerCase();
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
