import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/features/auth/application/auth_validators.dart';

void main() {
  group('email', () {
    test('accepts valid addresses, trimmed', () {
      expect(AuthValidators.email(' alice@example.com '), isNull);
    });

    test('rejects empty and malformed addresses', () {
      expect(AuthValidators.email(''), isNotNull);
      expect(AuthValidators.email(null), isNotNull);
      expect(AuthValidators.email('alice'), isNotNull);
      expect(AuthValidators.email('alice@example'), isNotNull);
      expect(AuthValidators.email('a b@example.com'), isNotNull);
    });
  });

  group('newPassword (same policy as the API)', () {
    test('accepts 8+ characters with a letter and a digit', () {
      expect(AuthValidators.newPassword('risotto1'), isNull);
      expect(AuthValidators.newPassword('épinard9'), isNull);
    });

    test('rejects weak passwords', () {
      expect(AuthValidators.newPassword('abc1'), isNotNull);
      expect(AuthValidators.newPassword('onlyletters'), isNotNull);
      expect(AuthValidators.newPassword('1234567890'), isNotNull);
      expect(AuthValidators.newPassword('a1${'x' * 127}'), isNotNull);
    });
  });

  test('requiredPassword only checks presence', () {
    expect(AuthValidators.requiredPassword('x'), isNull);
    expect(AuthValidators.requiredPassword(''), isNotNull);
  });

  test('confirmation compares with the current password', () {
    var password = 'risotto1';
    final validator = AuthValidators.confirmation(() => password);
    expect(validator('risotto1'), isNull);
    password = 'changed1';
    expect(validator('risotto1'), isNotNull);
  });

  test('resetCode requires exactly 6 digits', () {
    expect(AuthValidators.resetCode('042517'), isNull);
    expect(AuthValidators.resetCode('12345'), isNotNull);
    expect(AuthValidators.resetCode('12345a'), isNotNull);
  });
}
