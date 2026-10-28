import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/features/connections/data/connections_models.dart';
import 'package:risotto/features/profile/data/profile_models.dart';

import '../../helpers/fake_connections_repository.dart';
import '../../helpers/fake_contacts_repository.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/in_memory_session_storage.dart';
import '../../helpers/test_app.dart';

void main() {
  late FakeConnectionsRepository connections;
  late FakeProfileRepository profiles;
  final bob = member('bob', 'Bob', 'Durand', headline: 'Designer');
  final carol = member('carol', 'Carol', 'Petit', headline: 'CTO');

  setUp(() {
    connections = FakeConnectionsRepository(members: [bob, carol]);
    profiles = FakeProfileRepository(
      mine: testProfile(),
      lookup: (id) => connections.members.any((m) => m.userId == id)
          ? connections.current(id)
          : null,
    );
  });

  Future<void> start(
    WidgetTester tester, {
    FakeContactsRepository? contacts,
    List<String> scannerPayloads = const [],
  }) => pumpRisottoApp(
    tester,
    storage: InMemorySessionStorage(testSession()),
    profiles: profiles,
    connections: connections,
    contacts: contacts,
    scannerPayloads: scannerPayloads,
  );

  Future<void> searchFor(WidgetTester tester, String query) async {
    await tapText(tester, 'Rechercher');
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  group('search', () {
    testWidgets('asks for at least 2 characters', (tester) async {
      await start(tester);
      await searchFor(tester, 'b');
      expect(find.text('Saisissez au moins 2 caractères.'), findsOneWidget);
      expect(connections.calls, isNot(contains('search')));
    });

    testWidgets('finds members and sends a request', (tester) async {
      await start(tester);
      await searchFor(tester, 'bob');

      expect(find.text('Bob Durand'), findsOneWidget);
      await tapText(tester, 'Se connecter');

      expect(connections.lastArgs['userId'], 'bob');
      expect(find.text('Demande envoyée à Bob.'), findsOneWidget);
      // The list refreshes with the new state.
      expect(find.text('Annuler la demande'), findsOneWidget);
    });

    testWidgets('shows an empty result', (tester) async {
      await start(tester);
      await searchFor(tester, 'zz');
      expect(find.text('Aucun membre trouvé.'), findsOneWidget);
    });
  });

  group('network', () {
    testWidgets('accepts an incoming request', (tester) async {
      connections.addIncoming(bob, message: 'Rencontrés au salon');
      await start(tester);
      await tapText(tester, 'Réseau');
      await tapText(tester, 'Reçues (1)');

      expect(find.text('« Rencontrés au salon »'), findsOneWidget);
      await tapText(tester, 'Accepter');

      expect(connections.calls, contains('accept'));
      expect(
        find.text('Vous êtes maintenant en relation avec Bob.'),
        findsOneWidget,
      );
      await tapText(tester, 'Relations');
      expect(find.text('Bob Durand'), findsOneWidget);
    });

    testWidgets('declines an incoming request', (tester) async {
      connections.addIncoming(carol);
      await start(tester);
      await tapText(tester, 'Réseau');
      await tapText(tester, 'Reçues (1)');
      await tapText(tester, 'Refuser');

      expect(connections.calls, contains('decline'));
      expect(find.text('Aucune demande reçue.'), findsOneWidget);
    });

    testWidgets('removing a connection asks for confirmation', (tester) async {
      connections.addAccepted(bob);
      await start(tester);
      await tapText(tester, 'Réseau');
      await tapText(tester, 'Bob Durand');
      await tapText(tester, 'En relation');
      await tapText(tester, 'Retirer');

      expect(connections.calls, contains('remove'));
      expect(find.text('Relation retirée.'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });
  });

  group('member profile', () {
    Future<void> openBob(WidgetTester tester) async {
      await start(tester);
      await searchFor(tester, 'bob');
      await tapText(tester, 'Bob Durand');
    }

    testWidgets('offers to connect', (tester) async {
      await openBob(tester);
      expect(find.text('Designer'), findsOneWidget);
      await tapText(tester, 'Se connecter');
      expect(connections.calls, contains('request'));
    });

    testWidgets('blocks a member after confirmation', (tester) async {
      await openBob(tester);
      await tester.tap(find.byTooltip('Plus d’options'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Bloquer');
      // Confirmation dialog.
      await tester.tap(find.widgetWithText(FilledButton, 'Bloquer'));
      await tester.pumpAndSettle();

      expect(connections.lastArgs['userId'], 'bob');
      expect(find.text('Bob Durand est bloqué.'), findsOneWidget);
    });

    testWidgets('blocked members can be unblocked', (tester) async {
      connections.blockedUsers.add(
        const BlockedUser(userId: 'bob', firstName: 'Bob', lastName: 'Durand'),
      );
      await start(tester);
      await tapText(tester, 'Réseau');
      await tester.tap(find.byTooltip('Plus d’options'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Membres bloqués');
      await tapText(tester, 'Débloquer');

      expect(connections.calls, contains('unblock'));
      expect(find.text('Vous n’avez bloqué personne.'), findsOneWidget);
    });
  });

  testWidgets('scanning a QR code offers to connect', (tester) async {
    final contacts = FakeContactsRepository()
      ..scannable[validPayload] = bobCard;
    await start(tester, contacts: contacts, scannerPayloads: [validPayload]);
    await tapText(tester, 'Scanner');
    await tapText(tester, 'scan:$validPayload');
    await tapText(tester, 'Se connecter');

    expect(connections.lastArgs['qrPayload'], validPayload);
    expect(find.text('Demande de mise en relation envoyée.'), findsWidgets);
  });

  test('MemberConnection parses the API states', () {
    expect(
      MemberConnection.fromJson({
        'status': 'pending_incoming',
        'connectionId': 'c1',
      }).status,
      ConnectionStatus.pendingIncoming,
    );
    expect(MemberConnection.fromJson(null).status, ConnectionStatus.none);
  });
}
