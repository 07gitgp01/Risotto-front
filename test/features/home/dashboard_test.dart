import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/core/network/api_exception.dart';
import 'package:risotto/core/theme/risotto_colors.dart';

import '../../helpers/fake_connections_repository.dart';
import '../../helpers/fake_dashboard.dart';
import '../../helpers/fake_messaging.dart';
import '../../helpers/in_memory_session_storage.dart';
import '../../helpers/test_app.dart';

void main() {
  late FakeDashboardRepository dashboard;
  late FakeRealtimeClient realtime;
  late FakeConnectionsRepository connections;

  setUp(() {
    dashboard = FakeDashboardRepository(busyDashboardJson());
    realtime = FakeRealtimeClient();
    connections = FakeConnectionsRepository(
      members: [member('carol', 'Carol', 'Durand')],
    );
  });

  Future<void> start(WidgetTester tester) => pumpRisottoApp(
    tester,
    storage: InMemorySessionStorage(testSession()),
    dashboard: dashboard,
    realtime: realtime,
    connections: connections,
    messaging: FakeMessagingRepository(
      messages: [chatMessage('m2', 'bob', 'Tu es dispo ?')],
      unread: 2,
    ),
  );

  testWidgets('greets the user on a cream background', (tester) async {
    await start(tester);
    expect(find.text('Bonjour, Alice'), findsOneWidget);
    expect(find.text('Ma carte Risotto'), findsOneWidget);
    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).scaffoldBackgroundColor, RisottoColors.cream);
  });

  testWidgets('shows pending requests, unread messages and activity', (
    tester,
  ) async {
    await start(tester);
    // Key figures.
    expect(find.bySemanticsLabel('1 Demandes reçues'), findsOneWidget);
    expect(find.bySemanticsLabel('2 Messages non lus'), findsOneWidget);
    expect(find.bySemanticsLabel('3 Relations'), findsOneWidget);
    await revealFinder(tester, find.text('Demandes en attente (1)'));
    expect(find.text('Rencontrés au salon'), findsOneWidget);
    await revealFinder(tester, find.text('Messages non lus (2)'));
    await revealFinder(tester, find.text('Tu es dispo ?'));
    await revealFinder(tester, find.text('Bob Durand vous a écrit.'));
    expect(find.text('Bob Durand vous a écrit.'), findsOneWidget);
    expect(
      find.text('Carol Durand souhaite rejoindre votre réseau.'),
      findsOneWidget,
    );
  });

  testWidgets('a request can be accepted from the dashboard', (tester) async {
    await start(tester);
    dashboard.json = emptyDashboardJson();
    await tapText(tester, 'Accepter');

    expect(connections.calls, contains('accept'));
    expect(find.text('Demandes en attente (1)'), findsNothing);
  });

  testWidgets('an unread conversation opens the chat', (tester) async {
    await start(tester);
    await tapText(tester, 'Tu es dispo ?');
    expect(find.text('Tu es dispo ?'), findsWidgets);
    expect(find.byTooltip('Envoyer'), findsOneWidget);
  });

  testWidgets('realtime events refresh the dashboard', (tester) async {
    await start(tester);
    final before = dashboard.loads;
    dashboard.json = emptyDashboardJson();
    realtime.push('message:new', {
      'id': 'm9',
      'conversationId': 'conv-1',
      'senderId': 'bob',
      'body': 'x',
      'createdAt': DateTime(2026).toIso8601String(),
    });
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(dashboard.loads, greaterThan(before));
    await revealFinder(tester, find.text('Vous êtes à jour.'));
    expect(find.text('Vous êtes à jour.'), findsOneWidget);
  });

  testWidgets('empty states invite to act', (tester) async {
    dashboard.json = emptyDashboardJson();
    await start(tester);
    expect(find.textContaining('Demandes en attente'), findsNothing);
    await revealFinder(tester, find.text('Vous êtes à jour.'));
    await revealFinder(tester, find.textContaining('Rien de neuf'));
    expect(find.textContaining('Rien de neuf'), findsOneWidget);
  });

  testWidgets('a failure shows a retry card', (tester) async {
    dashboard.failWith = const ApiException(ApiErrorKind.network);
    await start(tester);
    expect(
      find.textContaining('Impossible de joindre le serveur'),
      findsOneWidget,
    );

    dashboard.failWith = null;
    await tapText(tester, 'Réessayer');
    expect(find.bySemanticsLabel('1 Demandes reçues'), findsOneWidget);
  });

  testWidgets('bottom bar shows counts and meets accessibility guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await start(tester);
    expect(find.byTooltip('Réseau, 1 demandes en attente'), findsOneWidget);
    expect(find.byTooltip('Ma carte'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
