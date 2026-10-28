import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/core/config/app_config.dart';

void main() {
  group('AppConfig.resolveApiBaseUrl', () {
    test('defaults to the host loopback seen from the Android emulator', () {
      expect(
        AppConfig.resolveApiBaseUrl(
          defined: '',
          platform: TargetPlatform.android,
        ),
        'http://10.0.2.2:3000/api',
      );
    });

    test('defaults to localhost on the iOS simulator', () {
      expect(
        AppConfig.resolveApiBaseUrl(defined: '', platform: TargetPlatform.iOS),
        'http://localhost:3000/api',
      );
    });

    test('prefers the --dart-define value and strips the trailing slash', () {
      expect(
        AppConfig.resolveApiBaseUrl(
          defined: 'http://192.168.1.20:3000/api/',
          platform: TargetPlatform.android,
        ),
        'http://192.168.1.20:3000/api',
      );
    });
  });
}
