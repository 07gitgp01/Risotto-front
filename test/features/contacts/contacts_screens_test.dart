import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/features/contacts/application/qr_scanner.dart';
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
    FakeQrScanner? scanner,
  }) => pumpRisottoApp(
    tester,
    storage: InMemorySessionStorage(testSession()),
    contacts: contacts,
    cardSharer: sharer,
    scannerPayloads: scannerPayloads,
    scanner: scanner,
  );

  group('my card', () {
    testWidgets('shows my QR code and my card', (tester) async {
      await start(tester);
      await openMyCard(tester);

      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qr.size, 240);
      expect(find.text('Alice Martin'), findsOneWidget);
      expect(find.text('alice@example.com'), findsOneWidget);
    });

    testWidgets('shares my card as a vCard', (tester) async {
      await start(tester);
      await openMyCard(tester);
      await tapText(tester, 'Partager ma carte (vCard)');
      expect(sharer.shared.single.userId, 'user-1');
    });

    testWidgets('rotating the QR code asks for confirmation', (tester) async {
      await start(tester);
      await openMyCard(tester);
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
      await openMyCard(tester);
      await tapText(tester, 'Scanner un code');
      await tapText(tester, 'scan:$validPayload');

      expect(find.text('Bob Durand'), findsOneWidget);
      expect(find.text('Lead designer · Basilic'), findsOneWidget);
      await tapText(tester, 'Enregistrer le contact');

      expect(contacts.calls, contains('scanAndSave'));
      expect(find.text('Voir dans mes contacts'), findsOneWidget);
      expect(contacts.saved.single.card.userId, 'bob');
    });

    testWidgets('the meeting context is saved with the contact', (
      tester,
    ) async {
      contacts.scannable[validPayload] = bobCard;
      await start(tester, scannerPayloads: [validPayload]);
      await openMyCard(tester);
      await tapText(tester, 'Scanner un code');
      await tapText(tester, 'scan:$validPayload');

      expect(find.text('Contexte de rencontre'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Salon de Lyon');
      await tapText(tester, 'Enregistrer le contact');

      expect(contacts.calls, containsAllInOrder(['scanAndSave', 'updateNote']));
      expect(contacts.saved.single.note, 'Salon de Lyon');
    });

    testWidgets('reads a QR code from a gallery image', (tester) async {
      contacts.scannable[validPayload] = bobCard;
      final scanner = FakeQrScanner(const [])
        ..galleryResult = const GalleryScan(null);
      await start(tester, scanner: scanner);
      await openMyCard(tester);
      await tapText(tester, 'Scanner un code');

      await tapText(tester, 'Galerie');
      expect(
        find.text('Aucun QR code trouvé dans cette image.'),
        findsOneWidget,
      );

      scanner.galleryResult = GalleryScan(validPayload);
      await tapText(tester, 'Galerie');
      expect(find.text('Résultat du scan'), findsOneWidget);
      expect(find.text('Bob Durand'), findsOneWidget);
    });

    testWidgets('the torch can be switched on and off', (tester) async {
      final scanner = FakeQrScanner(const []);
      await start(tester, scanner: scanner);
      await openMyCard(tester);
      await tapText(tester, 'Scanner un code');

      await tapText(tester, 'Lampe');
      expect(scanner.torchToggles, 1);
      expect(find.text('Éteindre'), findsOneWidget);
      await tapText(tester, 'Éteindre');
      expect(scanner.torchToggles, 2);
    });

    testWidgets('a foreign QR code is rejected without calling the API', (
      tester,
    ) async {
      await start(tester, scannerPayloads: ['https://example.com']);
      await openMyCard(tester);
      await tapText(tester, 'Scanner un code');
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
      await openMyCard(tester);
      await tapText(tester, 'Scanner un code');
      await tapText(tester, 'scan:$validPayload');
      expect(find.text('QR code inconnu ou expiré.'), findsOneWidget);
    });

    testWidgets('scanning my own code says so', (tester) async {
      contacts.scannable[validPayload] = myCardFixture;
      await start(tester, scannerPayloads: [validPayload]);
      await openMyCard(tester);
      await tapText(tester, 'Scanner un code');
      await tapText(tester, 'scan:$validPayload');
      expect(find.text('C’est votre propre QR code.'), findsOneWidget);
      expect(find.text('Enregistrer le contact'), findsNothing);
    });
  });

  group('contacts', () {
    final savedBob = SavedContact(card: bobCard, savedAt: DateTime(2026));

    testWidgets('empty state invites to scan', (tester) async {
      await start(tester);
      await openContacts(tester);
      expect(find.textContaining('Aucun contact'), findsOneWidget);
    });

    testWidgets('lists saved contacts and opens a detail', (tester) async {
      contacts.saved.add(savedBob);
      await start(tester);
      await openContacts(tester);
      expect(find.text('Bob Durand'), findsOneWidget);

      await tapText(tester, 'Bob Durand');
      expect(find.text('+33612345678'), findsOneWidget);
    });

    testWidgets('saves a private note', (tester) async {
      contacts.saved.add(savedBob);
      await start(tester);
      await openContacts(tester);
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
      await openContacts(tester);
      await tapText(tester, 'Bob Durand');
      await tapText(tester, 'Exporter (vCard)');
      expect(sharer.shared.single.userId, 'bob');
    });

    testWidgets('deletes a contact after confirmation', (tester) async {
      contacts.saved.add(savedBob);
      await start(tester);
      await openContacts(tester);
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
      await openContacts(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
