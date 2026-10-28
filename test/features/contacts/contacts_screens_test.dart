import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:risotto/features/contacts/data/contacts_models.dart';

import '../../helpers/fake_contacts_repository.dart';
import '../../helpers/in_memory_session_storage.dart';
import '../../helpers/test_app.dart';

void main() {
  late FakeContactsRepository contacts;
  late FakeCardSharer sharer;

  setUp(() {
    contacts = FakeContactsRepository();
    sharer = FakeCardSharer();
  });

  Future<void> start(
    WidgetTester tester, {
    List<String> scannerPayloads = const [],
  }) => pumpRisottoApp(
    tester,
    storage: InMemorySessionStorage(testSession()),
    contacts: contacts,
    cardSharer: sharer,
    scannerPayloads: scannerPayloads,
  );

  group('my card', () {
    testWidgets('shows my QR code and my card', (tester) async {
      await start(tester);
      await tapText(tester, 'Ma carte');

      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qr.size, 240);
      expect(find.text('Alice Martin'), findsOneWidget);
      expect(find.text('alice@example.com'), findsOneWidget);
    });

    testWidgets('shares my card as a vCard', (tester) async {
      await start(tester);
      await tapText(tester, 'Ma carte');
      await tapText(tester, 'Partager ma carte (vCard)');
      expect(sharer.shared.single.userId, 'user-1');
    });

    testWidgets('rotating the QR code asks for confirmation', (tester) async {
      await start(tester);
      await tapText(tester, 'Ma carte');
      await tester.tap(find.byTooltip('Générer un nouveau QR code'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Annuler');
      expect(contacts.calls, isNot(contains('rotateQrCode')));

      await tester.tap(find.byTooltip('Générer un nouveau QR code'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Générer');
      expect(contacts.calls, contains('rotateQrCode'));
      expect(find.text('Nouveau QR code généré.'), findsOneWidget);
    });
  });

  group('scan', () {
    testWidgets('a scanned card can be saved', (tester) async {
      contacts.scannable[validPayload] = bobCard;
      await start(tester, scannerPayloads: [validPayload]);
      await tapText(tester, 'Scanner');
      await tapText(tester, 'scan:$validPayload');

      expect(find.text('Bob Durand'), findsOneWidget);
      expect(find.text('Lead designer · Basilic'), findsOneWidget);
      await tapText(tester, 'Enregistrer le contact');

      expect(contacts.calls, contains('scanAndSave'));
      expect(find.text('Voir dans mes contacts'), findsOneWidget);
      expect(contacts.saved.single.card.userId, 'bob');
    });

    testWidgets('a foreign QR code is rejected without calling the API', (
      tester,
    ) async {
      await start(tester, scannerPayloads: ['https://example.com']);
      await tapText(tester, 'Scanner');
      await tapText(tester, 'scan:https://example.com');

      expect(
        find.text('Ce QR code n’est pas un QR code Risotto.'),
        findsOneWidget,
      );
      expect(contacts.calls, isNot(contains('scan')));
    });

    testWidgets('an unknown or rotated QR code shows a message', (
      tester,
    ) async {
      await start(tester, scannerPayloads: [validPayload]);
      await tapText(tester, 'Scanner');
      await tapText(tester, 'scan:$validPayload');
      expect(find.text('QR code inconnu ou expiré.'), findsOneWidget);
    });

    testWidgets('scanning my own code says so', (tester) async {
      contacts.scannable[validPayload] = myCardFixture;
      await start(tester, scannerPayloads: [validPayload]);
      await tapText(tester, 'Scanner');
      await tapText(tester, 'scan:$validPayload');
      expect(find.text('C’est votre propre QR code.'), findsOneWidget);
      expect(find.text('Enregistrer le contact'), findsNothing);
    });
  });

  group('contacts', () {
    final savedBob = SavedContact(card: bobCard, savedAt: DateTime(2026));

    testWidgets('empty state invites to scan', (tester) async {
      await start(tester);
      await tapText(tester, 'Contacts');
      expect(find.textContaining('Aucun contact'), findsOneWidget);
    });

    testWidgets('lists saved contacts and opens a detail', (tester) async {
      contacts.saved.add(savedBob);
      await start(tester);
      await tapText(tester, 'Contacts');
      expect(find.text('Bob Durand'), findsOneWidget);

      await tapText(tester, 'Bob Durand');
      expect(find.text('+33612345678'), findsOneWidget);
    });

    testWidgets('saves a private note', (tester) async {
      contacts.saved.add(savedBob);
      await start(tester);
      await tapText(tester, 'Contacts');
      await tapText(tester, 'Bob Durand');

      await tester.enterText(
        find.widgetWithText(TextField, 'Note privée'),
        'Salon VivaTech',
      );
      await tapText(tester, 'Enregistrer la note');

      expect(contacts.saved.single.note, 'Salon VivaTech');
      expect(find.text('Note enregistrée.'), findsOneWidget);
    });

    testWidgets('exports a contact as a vCard', (tester) async {
      contacts.saved.add(savedBob);
      await start(tester);
      await tapText(tester, 'Contacts');
      await tapText(tester, 'Bob Durand');
      await tapText(tester, 'Exporter (vCard)');
      expect(sharer.shared.single.userId, 'bob');
    });

    testWidgets('deletes a contact after confirmation', (tester) async {
      contacts.saved.add(savedBob);
      await start(tester);
      await tapText(tester, 'Contacts');
      await tapText(tester, 'Bob Durand');
      await tester.tap(find.byTooltip('Supprimer le contact'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Supprimer');

      expect(contacts.saved, isEmpty);
      expect(find.text('Mes contacts'), findsOneWidget);
      expect(find.textContaining('Aucun contact'), findsOneWidget);
    });

    testWidgets('contacts screen meets accessibility guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      contacts.saved.add(savedBob);
      await start(tester);
      await tapText(tester, 'Contacts');
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
