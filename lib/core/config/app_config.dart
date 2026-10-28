import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Build-time configuration, injected with `--dart-define`. Never holds secrets.
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  /// Reads `--dart-define=API_BASE_URL=...`, falling back to the local API as seen
  /// from the Android emulator (10.0.2.2) or the iOS simulator (localhost).
  factory AppConfig.fromEnvironment({TargetPlatform? platform}) {
    const defined = String.fromEnvironment('API_BASE_URL');
    return AppConfig(
      apiBaseUrl: resolveApiBaseUrl(
        defined: defined,
        platform: platform ?? defaultTargetPlatform,
      ),
    );
  }

  final String apiBaseUrl;

  static String resolveApiBaseUrl({
    required String defined,
    required TargetPlatform platform,
  }) {
    final url = defined.isNotEmpty
        ? defined
        : platform == TargetPlatform.android
        ? 'http://10.0.2.2:3000/api'
        : 'http://localhost:3000/api';
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
