import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_repository.dart';
import 'push_service.dart';

final pushServiceProvider = Provider<PushService>((ref) => createPushService());

/// Registers this device for push while a user is signed in, and unregisters it on
/// sign-out (so the next user of the phone does not receive the previous one's alerts).
/// Driven from outside (app shell on sign-in, AuthController on sign-out): it must not
/// depend on the auth state itself, or the sign-out would be a dependency cycle.
class PushRegistration {
  PushRegistration(this._ref);

  final Ref _ref;
  String? _token;
  StreamSubscription<String>? _tokens;

  PushService get _push => _ref.read(pushServiceProvider);
  NotificationsRepository get _repository =>
      _ref.read(notificationsRepositoryProvider);

  Future<void> onSignedIn() async {
    unawaited(_tokens?.cancel());
    // Every token FCM issues (first one and rotations) is sent to the API.
    _tokens = _push.tokens.listen((token) => unawaited(_register(token)));
    await _push.enable();
  }

  /// Must run before the tokens are cleared (the API call is authenticated).
  Future<void> onSigningOut() async {
    unawaited(_tokens?.cancel());
    _tokens = null;
    final token = _token;
    _token = null;
    if (token != null) {
      try {
        await _repository.removeDevice(token);
      } on Object {
        // The server also drops tokens that FCM reports as invalid.
      }
    }
    await _push.disable();
  }

  Future<void> _register(String token) async {
    _token = token;
    try {
      await _repository.registerDevice(token, _push.platform);
    } on Object {
      // Retried at the next sign-in or token rotation.
    }
  }
}

final pushRegistrationProvider = Provider<PushRegistration>(
  PushRegistration.new,
);
