import 'package:flutter/material.dart';
import 'package:risotto/core/network/api_exception.dart';
import 'package:risotto/features/contacts/application/contacts_providers.dart';
import 'package:risotto/features/contacts/data/contacts_models.dart';
import 'package:risotto/features/contacts/data/contacts_repository.dart';
import 'package:risotto/features/contacts/presentation/scan_screen.dart';

const myCardFixture = ContactCard(
  userId: 'user-1',
  firstName: 'Alice',
  lastName: 'Martin',
  headline: 'Cheffe de projet',
  company: 'Risotto SAS',
  email: 'alice@example.com',
);

const bobCard = ContactCard(
  userId: 'bob',
  firstName: 'Bob',
  lastName: 'Durand',
  headline: 'Designer',
  jobTitle: 'Lead designer',
  company: 'Basilic',
  phone: '+33612345678',
);

final validPayload = 'risotto://u/${'b' * 43}';

class FakeContactsRepository implements ContactsRepository {
  FakeContactsRepository({List<SavedContact>? saved}) : saved = saved ?? [];

  final List<SavedContact> saved;
  final List<String> calls = [];
  ApiException? failWith;
  QrCode qr = QrCode(token: 'a' * 43, payload: 'risotto://u/${'a' * 43}');

  /// Payload → card returned by a scan.
  Map<String, ContactCard> scannable = {};

  Future<T> _run<T>(String name, T Function() ok) {
    calls.add(name);
    final failure = failWith;
    return failure != null ? Future.error(failure) : Future.value(ok());
  }

  @override
  Future<QrCode> getQrCode() => _run('getQrCode', () => qr);

  @override
  Future<QrCode> rotateQrCode() => _run('rotateQrCode', () {
    return qr = QrCode(token: 'c' * 43, payload: 'risotto://u/${'c' * 43}');
  });

  @override
  Future<ContactCard> getOwnCard() => _run('getOwnCard', () => myCardFixture);

  @override
  Future<ScanResult> scan(String payload, {bool saveContact = false}) =>
      _run(saveContact ? 'scanAndSave' : 'scan', () {
        final card = scannable[payload];
        if (card == null) {
          throw const ApiException(ApiErrorKind.invalidInput, statusCode: 404);
        }
        if (saveContact && !saved.any((c) => c.card.userId == card.userId)) {
          saved.add(SavedContact(card: card, savedAt: DateTime(2026)));
        }
        return ScanResult(
          card: card,
          isSelf: card.userId == 'user-1',
          saved: saved.any((c) => c.card.userId == card.userId),
        );
      });

  @override
  Future<List<SavedContact>> list() => _run('list', () => [...saved]);

  @override
  Future<void> updateNote(String contactId, String? note) =>
      _run('updateNote', () {
        final index = saved.indexWhere((c) => c.card.userId == contactId);
        saved[index] = saved[index].withNote(note);
      });

  @override
  Future<void> remove(String contactId) => _run('remove', () {
    saved.removeWhere((c) => c.card.userId == contactId);
  });
}

class FakeCardSharer implements CardSharer {
  final List<ContactCard> shared = [];

  @override
  Future<void> share(ContactCard card, {Rect? origin}) async =>
      shared.add(card);
}

/// Replaces the camera: a button per payload to "scan".
QrScannerBuilder fakeScanner(List<String> payloads) =>
    (context, onPayload) => Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (final payload in payloads)
          ElevatedButton(
            onPressed: () => onPayload(payload),
            child: Text('scan:$payload'),
          ),
      ],
    );
