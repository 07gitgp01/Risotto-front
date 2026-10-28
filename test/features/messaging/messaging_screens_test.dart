import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/core/network/api_exception.dart';
import 'package:risotto/core/realtime/realtime_client.dart';
import 'package:risotto/features/messaging/presentation/time_format.dart';
import 'package:risotto/features/profile/data/profile_models.dart';

import '../../helpers/fake_connections_repository.dart';
import '../../helpers/fake_dashboard.dart';
import '../../helpers/fake_messaging.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/in_memory_session_storage.dart';
import '../../helpers/test_app.dart';

void main() {
  late FakeMessagingRepository messaging;
  late FakeRealtimeClient realtime;

  setUp(() {
    messaging = FakeMessagingRepository(
      messages: [
        chatMessage('m2', 'bob', 'Ça marche, à demain !'),
        chatMessage('m1', 'user-1', 'On se voit demain ?'),
      ],
      unread: 1,
    );
    realtime = FakeRealtimeClient();
  });

  Future<void> start(WidgetTester tester, {FakeProfileRepository? profiles}) =>
      pumpRisottoApp(
        tester,
        storage: InMemorySessionStorage(testSession()),
        messaging: messaging,
        realtime: realtime,
        profiles: profiles,
      );

  Future<void> openChat(WidgetTester tester) async {
    await start(tester);
    await tapText(tester, 'Messages');
    await tapText(tester, 'Bob Durand');
  }

  testWidgets('home shows the unread badge', (tester) async {
    await pumpRisottoApp(
      tester,
      storage: InMemorySessionStorage(testSession()),
      messaging: messaging,
      realtime: realtime,
      dashboard: FakeDashboardRepository(busyDashboardJson()),
    );
    final badge = tester.widget<Badge>(
      find.ancestor(
        of: find.byIcon(Icons.chat_bubble_outline),
        matching: find.byType(Badge),
      ),
    );
    expect(badge.isLabelVisible, isTrue);
    expect((badge.label! as Text).data, '2');
  });

  testWidgets('lists conversations with the last message', (tester) async {
    await start(tester);
    await tapText(tester, 'Messages');
    expect(find.text('Bob Durand'), findsOneWidget);
    expect(find.text('Ça marche, à demain !'), findsOneWidget);
  });

  testWidgets('opening a conversation shows history and marks it read', (
    tester,
  ) async {
    await openChat(tester);
    expect(find.text('On se voit demain ?'), findsOneWidget);
    expect(find.text('Ça marche, à demain !'), findsOneWidget);
    expect(messaging.calls, contains('markRead'));
  });

  testWidgets('sends a message', (tester) async {
    await openChat(tester);
    await tester.enterText(find.byType(TextField), '  Parfait  ');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();

    expect(messaging.calls, contains('send'));
    expect(find.text('Parfait'), findsOneWidget);
    expect(find.text('Envoyé'), findsOneWidget);
  });

  testWidgets('does not send an empty message', (tester) async {
    await openChat(tester);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();
    expect(messaging.calls, isNot(contains('send')));
  });

  testWidgets('a message pushed by the server appears once', (tester) async {
    await openChat(tester);
    final event = {
      'id': 'm9',
      'conversationId': 'conv-1',
      'senderId': 'bob',
      'body': 'Message en direct',
      'createdAt': DateTime(2026, 1, 1, 12).toIso8601String(),
    };
    realtime
      ..push('message:new', event)
      ..push('message:new', event);
    await tester.pumpAndSettle();

    expect(find.text('Message en direct'), findsOneWidget);
    // Read immediately since the chat is open.
    expect(messaging.calls.where((c) => c == 'markRead').length, 2);
  });

  testWidgets('events of other conversations are ignored', (tester) async {
    await openChat(tester);
    realtime.push('message:new', {
      'id': 'x1',
      'conversationId': 'other',
      'senderId': 'carol',
      'body': 'Pas pour ici',
      'createdAt': DateTime(2026).toIso8601String(),
    });
    await tester.pumpAndSettle();
    expect(find.text('Pas pour ici'), findsNothing);
  });

  testWidgets('shows "Lu" when the other participant read my message', (
    tester,
  ) async {
    messaging.messages.insert(
      0,
      chatMessage('m3', 'user-1', 'Tu as vu ?', at: DateTime(2026, 1, 1, 11)),
    );
    await openChat(tester);
    expect(find.text('Envoyé'), findsOneWidget);

    realtime.push('conversation:read', {
      'conversationId': 'conv-1',
      'userId': 'bob',
      'readAt': DateTime(2026, 1, 1, 12).toIso8601String(),
    });
    await tester.pumpAndSettle();
    expect(find.text('Lu'), findsOneWidget);
  });

  testWidgets('loads older messages when scrolling up', (tester) async {
    messaging = FakeMessagingRepository(
      messages: [
        for (var i = 40; i >= 1; i--)
          chatMessage('m$i', i.isEven ? 'bob' : 'user-1', 'message $i'),
      ],
      pageSize: 30,
    );
    await openChat(tester);
    await tester.drag(find.byType(ListView), const Offset(0, 3000));
    await tester.pumpAndSettle();

    expect(messaging.calls, contains('history:m11'));
    await tester.drag(find.byType(ListView), const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(find.text('message 1'), findsOneWidget);
  });

  testWidgets('read-only once the connection is gone', (tester) async {
    messaging.canSend = false;
    await openChat(tester);
    expect(find.textContaining('lecture seule'), findsOneWidget);
    expect(find.byTooltip('Envoyer'), findsNothing);
  });

  testWidgets('explains a refused message', (tester) async {
    messaging.failSendWith = const ApiException(
      ApiErrorKind.unauthorized,
      statusCode: 403,
    );
    await openChat(tester);
    await tester.enterText(find.byType(TextField), 'Coucou');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Vous n’êtes plus en relation'), findsOneWidget);
  });

  testWidgets('a connection can be messaged from their profile', (
    tester,
  ) async {
    final connections = FakeConnectionsRepository(
      members: [
        member(
          'bob',
          'Bob',
          'Durand',
          access: ProfileAccess.full,
          connection: const MemberConnection(ConnectionStatus.connected, 'c1'),
        ),
      ],
    );
    final profiles = FakeProfileRepository(
      mine: testProfile(),
      lookup: (id) => connections.members.firstWhere((m) => m.userId == id),
    );
    messaging.messages.clear();
    messaging.unread = 0;
    await pumpRisottoApp(
      tester,
      storage: InMemorySessionStorage(testSession()),
      messaging: messaging,
      realtime: realtime,
      profiles: profiles,
      connections: connections,
    );
    await tapText(tester, 'Rechercher');
    await tester.enterText(find.byType(TextField), 'bob');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tapText(tester, 'Bob Durand');
    await tapText(tester, 'Envoyer un message');

    expect(messaging.calls, contains('start'));
    expect(find.text('Démarrez la conversation.'), findsOneWidget);
  });

  test('realtimeUrl targets the /ws namespace on the API host', () {
    expect(realtimeUrl('http://10.0.2.2:3000/api'), 'http://10.0.2.2:3000/ws');
    expect(
      realtimeUrl('https://api.risotto.app/api'),
      'https://api.risotto.app/ws',
    );
  });

  test('shortTime shows the hour today and the date otherwise', () {
    final now = DateTime(2026, 3, 12, 18);
    expect(shortTime(DateTime(2026, 3, 12, 9, 5), now: now), '09:05');
    expect(shortTime(DateTime(2026, 3, 1, 9, 5), now: now), '01/03');
  });
}
