import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/core/network/api_exception.dart';
import 'package:risotto/features/messaging/application/messaging_providers.dart';
import 'package:risotto/features/messaging/data/messaging_models.dart';
import 'package:risotto/features/messaging/presentation/time_format.dart';

import '../../helpers/fake_messaging.dart';
import '../../helpers/in_memory_session_storage.dart';
import '../../helpers/test_app.dart';

void main() {
  late FakeMessagingRepository messaging;
  late FakeRealtimeClient realtime;

  setUp(() {
    messaging = FakeMessagingRepository(
      messages: [
        chatMessage('m2', 'bob', 'Ça marche, à demain !'),
        chatMessage('m1', 'user-1', 'On se voit demain ?', at: DateTime.now()),
      ],
    );
    realtime = FakeRealtimeClient();
  });

  Future<void> openChat(WidgetTester tester) async {
    await pumpRisottoApp(
      tester,
      storage: InMemorySessionStorage(testSession()),
      messaging: messaging,
      realtime: realtime,
    );
    await openTab(tester, 'Messages');
    await tapText(tester, 'Bob Durand');
  }

  Future<void> longPress(WidgetTester tester, String text) async {
    await tester.longPress(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('answers a message with a quote', (tester) async {
    await openChat(tester);
    await longPress(tester, 'Ça marche, à demain !');
    await tester.tap(find.text('Répondre'));
    await tester.pumpAndSettle();
    expect(find.text('Réponse à Bob'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Super');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();

    expect(messaging.calls, contains('send:reply:m2'));
    expect(find.text('Réponse à Bob'), findsNothing);
    // The quote above my answer: the author, then the quoted text.
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Ça marche, à demain !'), findsNWidgets(2));
  });

  testWidgets('edits my recent message', (tester) async {
    await openChat(tester);
    await longPress(tester, 'On se voit demain ?');
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    expect(find.text('Modifier le message'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'On se voit jeudi ?');
    await tester.tap(find.byTooltip('Enregistrer'));
    await tester.pumpAndSettle();

    expect(messaging.calls, contains('edit:m1'));
    expect(find.text('On se voit jeudi ?'), findsOneWidget);
    expect(find.text('modifié'), findsOneWidget);
  });

  testWidgets('the other’s message cannot be edited or deleted', (
    tester,
  ) async {
    await openChat(tester);
    await longPress(tester, 'Ça marche, à demain !');
    expect(find.text('Modifier'), findsNothing);
    expect(find.text('Supprimer pour tous'), findsNothing);
    expect(find.text('Copier'), findsOneWidget);
  });

  testWidgets('deletes my message for everyone after confirmation', (
    tester,
  ) async {
    await openChat(tester);
    await longPress(tester, 'On se voit demain ?');
    await tester.tap(find.text('Supprimer pour tous'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(messaging.calls, contains('delete:m1'));
    expect(find.text('Ce message a été supprimé'), findsOneWidget);
    expect(find.text('On se voit demain ?'), findsNothing);
  });

  testWidgets('reacts, and the same emoji again removes it', (tester) async {
    await openChat(tester);
    await longPress(tester, 'Ça marche, à demain !');
    await tester.tap(find.bySemanticsLabel('Réagir avec 👍'));
    await tester.pumpAndSettle();
    expect(messaging.calls, contains('react:m2:👍'));
    expect(find.text('👍'), findsOneWidget);

    // Tapping my reaction under the bubble toggles it off.
    await tester.tap(find.text('👍'));
    await tester.pumpAndSettle();
    expect(messaging.calls, contains('react:m2:-'));
    expect(find.text('👍'), findsNothing);
  });

  testWidgets('a failed send stays, then is retried with the same id', (
    tester,
  ) async {
    await openChat(tester);
    messaging.failSendWith = const ApiException(ApiErrorKind.network);
    await tester.enterText(find.byType(TextField), 'Hors ligne');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();

    expect(find.text('Hors ligne'), findsOneWidget);
    expect(find.text('Non envoyé · Réessayer'), findsOneWidget);
    expect(find.textContaining('Pas de réseau'), findsOneWidget);
    // The input is free again at once.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );

    messaging.failSendWith = null;
    await tester.tap(find.text('Hors ligne'));
    await tester.pumpAndSettle();
    expect(find.text('Non envoyé · Réessayer'), findsNothing);
    expect(
      messaging.messages.where((m) => m.body == 'Hors ligne'),
      hasLength(1),
    );
  });

  testWidgets('a message confirmed by the socket first is not doubled', (
    tester,
  ) async {
    await openChat(tester);
    await tester.enterText(find.byType(TextField), 'Vite');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();
    final sent = messaging.messages.first;
    realtime.push('message:new', {
      'id': sent.id,
      'conversationId': 'conv-1',
      'senderId': 'user-1',
      'body': 'Vite',
      'createdAt': sent.createdAt.toIso8601String(),
      'clientId': sent.clientId,
    });
    await tester.pumpAndSettle();
    expect(find.text('Vite'), findsOneWidget);
  });

  testWidgets('shows "Écrit…" then presence, and sends typing', (tester) async {
    messaging.presence = Presence(
      online: false,
      lastSeenAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );
    await openChat(tester);
    expect(find.textContaining('Vu aujourd’hui à'), findsOneWidget);

    realtime.push('typing', {'conversationId': 'conv-1', 'userId': 'bob'});
    await tester.pump();
    await tester.pump();
    expect(find.text('Écrit…'), findsOneWidget);
    await tester.pump(ChatController.typingTimeout);
    expect(find.text('Écrit…'), findsNothing);

    realtime.push('presence', {
      'userId': 'bob',
      'presence': {'online': true, 'lastSeenAt': null},
    });
    await tester.pumpAndSettle();
    expect(find.text('En ligne'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'S');
    await tester.enterText(find.byType(TextField), 'Sa');
    expect(realtime.emitted, hasLength(1));
    expect(realtime.emitted.single.$1, 'typing');
    expect(realtime.emitted.single.$2, {'conversationId': 'conv-1'});
  });

  testWidgets('presence can be hidden from the profile tab', (tester) async {
    await pumpRisottoApp(
      tester,
      storage: InMemorySessionStorage(testSession()),
      messaging: messaging,
      realtime: realtime,
    );
    await openTab(tester, 'Profil');
    await revealFinder(tester, find.text('Statut en ligne'));
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(messaging.calls, contains('sharePresence:false'));
  });

  test('client ids are random UUID v4', () {
    final id = newClientId();
    expect(
      id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(newClientId(), isNot(id));
  });

  test('last seen wording', () {
    final now = DateTime(2026, 3, 12, 18);
    expect(
      lastSeenLabel(DateTime(2026, 3, 12, 14, 5), now: now),
      'Vu aujourd’hui à 14:05',
    );
    expect(
      lastSeenLabel(DateTime(2026, 3, 11, 9, 12), now: now),
      'Vu hier à 09:12',
    );
    expect(
      lastSeenLabel(DateTime(2026, 3, 1, 9), now: now),
      'Vu le 1 mars 2026',
    );
  });
}
