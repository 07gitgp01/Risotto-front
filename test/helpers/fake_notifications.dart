import 'dart:async';

import 'package:risotto/features/notifications/application/push_service.dart';
import 'package:risotto/features/notifications/data/notifications_models.dart';
import 'package:risotto/features/notifications/data/notifications_repository.dart';

Map<String, dynamic> notificationJson(
  String id, {
  String type = 'connection_request',
  String actorId = 'bob',
  String firstName = 'Bob',
  bool read = false,
}) => {
  'id': id,
  'type': type,
  'actor': {
    'userId': actorId,
    'access': 'preview',
    'firstName': firstName,
    'lastName': 'Durand',
  },
  'data': {'actorId': actorId, 'connectionId': 'c-$id'},
  'readAt': read ? DateTime(2026).toIso8601String() : null,
  'createdAt': DateTime(2026, 1, 1, 9).toIso8601String(),
};

class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository({List<AppNotification>? notifications})
    : notifications = notifications ?? [];

  final List<AppNotification> notifications;
  final List<String> calls = [];
  final Map<String, String> devices = {};
  List<NotificationPreference> prefs = [
    const NotificationPreference(
      kind: NotificationKind.connectionRequest,
      inApp: true,
      push: true,
      supportsInApp: true,
    ),
    const NotificationPreference(
      kind: NotificationKind.connectionAccepted,
      inApp: true,
      push: true,
      supportsInApp: true,
    ),
    const NotificationPreference(
      kind: NotificationKind.message,
      inApp: false,
      push: true,
      supportsInApp: false,
    ),
  ];

  @override
  Future<NotificationsPage> list({String? before}) async {
    calls.add('list');
    return NotificationsPage(
      notifications: [...notifications],
      unreadCount: notifications.where((n) => !n.isRead).length,
    );
  }

  @override
  Future<void> markRead(String id) async {
    calls.add('markRead:$id');
    final index = notifications.indexWhere((n) => n.id == id);
    notifications[index] = notifications[index].markedRead();
  }

  @override
  Future<void> markAllRead() async {
    calls.add('markAllRead');
    for (var i = 0; i < notifications.length; i++) {
      notifications[i] = notifications[i].markedRead();
    }
  }

  @override
  Future<List<NotificationPreference>> preferences() async => [...prefs];

  @override
  Future<List<NotificationPreference>> updatePreferences(
    List<NotificationPreference> preferences,
  ) async {
    calls.add('updatePreferences');
    for (final change in preferences) {
      prefs = [for (final p in prefs) p.kind == change.kind ? change : p];
    }
    return [...prefs];
  }

  @override
  Future<void> registerDevice(String token, String platform) async {
    calls.add('registerDevice');
    devices[token] = platform;
  }

  @override
  Future<void> removeDevice(String token) async {
    calls.add('removeDevice');
    devices.remove(token);
  }
}

class FakePushService implements PushService {
  FakePushService({this.token = 'device-token-1'});

  final String? token;
  final _tokens = StreamController<String>.broadcast();
  final _opened = StreamController<Map<String, String>>.broadcast();
  bool disabled = false;

  @override
  Future<bool> enable() async {
    final value = token;
    if (value == null) {
      return false;
    }
    // Like FCM: the token arrives on the stream after registration.
    scheduleMicrotask(() => _tokens.add(value));
    return true;
  }

  @override
  Stream<String> get tokens => _tokens.stream;

  @override
  Stream<Map<String, String>> get openedNotifications => _opened.stream;

  void open(Map<String, String> data) => _opened.add(data);

  @override
  Future<void> disable() async => disabled = true;

  @override
  String get platform => 'android';
}
