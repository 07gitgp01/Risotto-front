import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Push notifications for the device. Disabled unless the app is built with
/// `--dart-define=FCM_ENABLED=true` and the Firebase config files are present
/// (android/app/google-services.json, ios/Runner/GoogleService-Info.plist).
abstract interface class PushService {
  /// Asks for permission and registers with FCM. Tokens (first one and rotations)
  /// arrive on [tokens]. Returns false if refused or unavailable.
  Future<bool> enable();

  /// Device tokens issued by FCM: the first one, then each rotation.
  Stream<String> get tokens;

  /// Data of the notification the user tapped (app opened or resumed from it).
  Stream<Map<String, String>> get openedNotifications;

  /// Unregisters this device (sign-out).
  Future<void> disable();

  String get platform;
}

String _platformName() =>
    defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

class DisabledPushService implements PushService {
  @override
  Future<bool> enable() async => false;

  @override
  Stream<String> get tokens => const Stream.empty();

  @override
  Stream<Map<String, String>> get openedNotifications => const Stream.empty();

  @override
  Future<void> disable() async {}

  @override
  String get platform => _platformName();
}

/// Lives as long as the app: its stream controllers are never closed.
class FirebasePushService implements PushService {
  // ignore: close_sinks
  final _opened = StreamController<Map<String, String>>.broadcast();
  // ignore: close_sinks
  final _tokens = StreamController<String>.broadcast();
  bool _initialized = false;

  Future<FirebaseMessaging> _messaging() async {
    if (!_initialized) {
      await Firebase.initializeApp();
      _initialized = true;
      final messaging = FirebaseMessaging.instance;
      messaging.onRegistered.listen(_tokens.add);
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _opened.add(Map<String, String>.from(message.data)),
      );
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _opened.add(Map<String, String>.from(initial.data));
      }
    }
    return FirebaseMessaging.instance;
  }

  @override
  Future<bool> enable() async {
    try {
      final messaging = await _messaging();
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return false;
      }
      await messaging.register();
      return true;
    } on Object catch (error) {
      debugPrint('Push unavailable: $error');
      return false;
    }
  }

  @override
  Stream<String> get tokens => _tokens.stream;

  @override
  Stream<Map<String, String>> get openedNotifications => _opened.stream;

  @override
  Future<void> disable() async {
    if (_initialized) {
      await FirebaseMessaging.instance.unregister();
    }
  }

  @override
  String get platform => _platformName();
}

const fcmEnabled = bool.fromEnvironment('FCM_ENABLED');

PushService createPushService() =>
    fcmEnabled ? FirebasePushService() : DisabledPushService();
