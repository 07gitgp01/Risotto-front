import 'package:risotto/features/auth/application/app_lock.dart';

class FakeBiometricAuthenticator implements BiometricAuthenticator {
  FakeBiometricAuthenticator({this.available = true, this.succeeds = true});

  bool available;
  bool succeeds;
  final List<String> prompts = [];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts.add(reason);
    return succeeds;
  }
}

class InMemoryAppLockSettings implements AppLockSettings {
  InMemoryAppLockSettings({this.enabled = false});

  bool enabled;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<void> setEnabled(bool enabled) async => this.enabled = enabled;
}
