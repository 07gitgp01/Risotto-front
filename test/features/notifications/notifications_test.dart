import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/features/notifications/data/notifications_models.dart';
import 'package:risotto/features/notifications/presentation/notification_routes.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_messaging.dart';
import '../../helpers/fake_notifications.dart';
import '../../helpers/in_memory_session_storage.dart';
import '../../helpers/test_app.dart';

void main() {
  late FakeNotificationsRepository notifications;
  late FakeRealtimeClient realtime;
  late FakePushService push;

  setUp(() {
    notifications = FakeNotificationsRepository(
      notifications: [
        AppNotification.fromJson(notificationJson('n1')),
        AppNotification.fromJson(
          notificationJson(
            'n2',
            type: 'connection_accepted',
            actorId: 'carol',
            firstName: 'Carol',
            read: true,
          ),
        ),
      ],
    );
    realtime = FakeRealtimeClient();
    push = FakePushService();
  });

  Future<void> start(
    WidgetTester tester, {
    FakeAuthRepository? auth,
    InMemorySessionStorage? storage,
  }) => pumpRisottoApp(
    tester,
    auth: auth,
    storage: storage ?? InMemorySessionStorage(testSession()),
    notifications: notifications,
    realtime: realtime,
    push: push,
  );

  Future<void> openNotifications(WidgetTester tester) async {
    await start(tester);
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
  }

  testWidgets('the bell shows the unread count', (tester) async {
    await start(tester);
    expect(find.byTooltip('Notifications, 1 non lues'), findsOneWidget);
  });

  testWidgets('lists notifications with a readable sentence', (tester) async {
    await openNotifications(tester);
    expect(
      find.text('Bob Durand souhaite rejoindre votre réseau.'),
      findsOneWidget,
    );
    expect(
      find.text('Carol Durand a accepté votre demande de mise en relation.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping marks as read and opens the related screen', (
    tester,
  ) async {
    await openNotifications(tester);
    await tapText(tester, 'Bob Durand souhaite rejoindre votre réseau.');

    expect(notifications.calls, contains('markRead:n1'));
    expect(find.text('Mon réseau'), findsOneWidget);
  });

  testWidgets('marks everything as read', (tester) async {
    await openNotifications(tester);
    await tapText(tester, 'Tout lire');
    expect(notifications.calls, contains('markAllRead'));
    expect(find.text('Tout lire'), findsNothing);
  });

  testWidgets('a real-time notification shows a banner and updates the list', (
    tester,
  ) async {
    await start(tester);
    realtime.push(
      'notification:new',
      notificationJson('n3', firstName: 'Dana'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Dana Durand souhaite rejoindre votre réseau.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Notifications, 2 non lues'), findsOneWidget);
  });

  testWidgets('preferences can be changed', (tester) async {
    await openNotifications(tester);
    await tester.tap(find.byTooltip('Préférences de notification'));
    await tester.pumpAndSettle();

    expect(find.text('Demandes de mise en relation'), findsOneWidget);
    // Messages have no in-app switch.
    expect(find.text('Dans l’application'), findsNWidgets(2));
    await tester.tap(find.text('Notification push').first);
    await tester.pumpAndSettle();

    expect(notifications.calls, contains('updatePreferences'));
    expect(notifications.prefs.first.push, isFalse);
  });

  testWidgets('the device is registered for push once signed in', (
    tester,
  ) async {
    await start(tester);
    await tester.pumpAndSettle();
    expect(notifications.devices, {'device-token-1': 'android'});
  });

  testWidgets('signing out unregisters the device', (tester) async {
    final auth = FakeAuthRepository();
    await start(tester, auth: auth);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Se déconnecter'));
    await tester.pumpAndSettle();

    expect(notifications.calls, contains('removeDevice'));
    expect(notifications.devices, isEmpty);
    expect(push.disabled, isTrue);
    // The device is unregistered before the session is revoked.
    expect(
      notifications.calls.indexOf('removeDevice'),
      greaterThanOrEqualTo(0),
    );
    expect(auth.calls, contains('logout'));
  });

  testWidgets('tapping a push opens the conversation', (tester) async {
    await start(tester);
    push.open({'type': 'message', 'conversationId': 'conv-1'});
    await tester.pumpAndSettle();
    expect(find.text('Bob Durand'), findsWidgets);
  });

  group('routeForNotification', () {
    test('maps each kind to its screen', () {
      expect(
        routeForNotification(NotificationKind.connectionRequest, {}),
        '/network?tab=1',
      );
      expect(
        routeForNotification(NotificationKind.connectionAccepted, {
          'actorId': 'bob',
        }),
        '/users/bob',
      );
      expect(
        routeForPushData({'type': 'message', 'conversationId': 'c1'}),
        '/messages/c1',
      );
      expect(routeForPushData({'type': 'weird'}), isNull);
    });
  });
}
