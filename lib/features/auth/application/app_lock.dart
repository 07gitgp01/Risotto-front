import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Fingerprint / face / device PIN check, behind an interface (faked in tests).
abstract interface class BiometricAuthenticator {
  /// True when the phone has a fingerprint, face or screen lock configured.
  Future<bool> isAvailable();

  /// Shows the system prompt; false when cancelled or failed.
  Future<bool> authenticate(String reason);
}

class LocalBiometricAuthenticator implements BiometricAuthenticator {
  LocalBiometricAuthenticator([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      // The device PIN stays allowed as a fallback (wet finger, lockout).
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } on Object {
      return false;
    }
  }
}

final biometricAuthenticatorProvider = Provider<BiometricAuthenticator>(
  (ref) => LocalBiometricAuthenticator(),
);

/// Whether the app lock is on, per device (never synced to the server).
abstract interface class AppLockSettings {
  Future<bool> isEnabled();
  Future<void> setEnabled(bool enabled);
}

class SecureAppLockSettings implements AppLockSettings {
  SecureAppLockSettings([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'risotto.app_lock';

  final FlutterSecureStorage _storage;

  @override
  Future<bool> isEnabled() async => await _storage.read(key: _key) == 'on';

  @override
  Future<void> setEnabled(bool enabled) => enabled
      ? _storage.write(key: _key, value: 'on')
      : _storage.delete(key: _key);
}

final appLockSettingsProvider = Provider<AppLockSettings>(
  (ref) => SecureAppLockSettings(),
);

class AppLockState {
  const AppLockState({
    required this.loaded,
    required this.enabled,
    required this.locked,
  });

  /// False until the setting is read: the app stays covered meanwhile.
  final bool loaded;
  final bool enabled;
  final bool locked;

  /// The signed-in content must be hidden.
  bool get covers => !loaded || locked;
}

enum AppLockToggleResult { done, unavailable, cancelled }

/// Asks for the fingerprint when the app opens, or comes back after
/// [idleTimeout] in the background. The session itself stays in secure storage.
class AppLockController extends Notifier<AppLockState> {
  static const idleTimeout = Duration(minutes: 1);
  static const _reason = 'Déverrouillez Risotto';

  bool _authenticating = false;

  /// True while the system prompt is shown (it may pause the app).
  bool get isAuthenticating => _authenticating;

  AppLockSettings get _settings => ref.read(appLockSettingsProvider);
  BiometricAuthenticator get _biometrics =>
      ref.read(biometricAuthenticatorProvider);

  @override
  AppLockState build() {
    unawaited(_load());
    return const AppLockState(loaded: false, enabled: false, locked: false);
  }

  Future<void> _load() async {
    var enabled = false;
    try {
      enabled = await _settings.isEnabled();
    } on Object {
      // Unreadable setting: never lock the user out.
    }
    state = AppLockState(loaded: true, enabled: enabled, locked: enabled);
  }

  Future<bool> unlock() async {
    if (!state.locked || _authenticating) {
      return !state.locked;
    }
    _authenticating = true;
    try {
      final ok = await _biometrics.authenticate(_reason);
      if (ok) {
        state = AppLockState(
          loaded: true,
          enabled: state.enabled,
          locked: false,
        );
      }
      return ok;
    } finally {
      _authenticating = false;
    }
  }

  /// Called when the app comes back to the foreground.
  void onResumed(Duration away) {
    if (state.enabled && !state.locked && away >= idleTimeout) {
      state = const AppLockState(loaded: true, enabled: true, locked: true);
    }
  }

  /// Turning the lock on asks for the fingerprint once, to prove it works.
  Future<AppLockToggleResult> setEnabled(bool enabled) async {
    if (enabled) {
      if (!await _biometrics.isAvailable()) {
        return AppLockToggleResult.unavailable;
      }
      _authenticating = true;
      try {
        if (!await _biometrics.authenticate(
          'Confirmez pour activer le déverrouillage',
        )) {
          return AppLockToggleResult.cancelled;
        }
      } finally {
        _authenticating = false;
      }
    }
    await _settings.setEnabled(enabled);
    state = AppLockState(loaded: true, enabled: enabled, locked: false);
    return AppLockToggleResult.done;
  }

  /// A password sign-in already proves who is there.
  void onSignedIn() {
    if (state.locked) {
      state = AppLockState(loaded: true, enabled: state.enabled, locked: false);
    }
  }

  /// The next account on this phone chooses for itself.
  Future<void> onSignedOut() async {
    try {
      await _settings.setEnabled(false);
    } on Object {
      // Best effort.
    }
    state = const AppLockState(loaded: true, enabled: false, locked: false);
  }
}

final appLockProvider = NotifierProvider<AppLockController, AppLockState>(
  AppLockController.new,
);
