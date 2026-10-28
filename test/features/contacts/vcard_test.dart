import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/features/contacts/application/vcard.dart';
import 'package:risotto/features/contacts/data/contacts_models.dart';

void main() {
  test('builds a vCard 3.0 with the shared fields only', () {
    const card = ContactCard(
      userId: 'u1',
      firstName: 'Élodie',
      lastName: 'Martin',
      company: 'Risotto, SAS',
      jobTitle: 'CTO',
      email: 'elodie@example.com',
      headline: 'Line 1\nLine 2; more',
    );
    final vcard = buildVCard(card);

    expect(vcard, startsWith('BEGIN:VCARD\r\nVERSION:3.0\r\n'));
    expect(vcard, contains('N:Martin;Élodie;;;'));
    expect(vcard, contains('FN:Élodie Martin'));
    expect(vcard, contains(r'ORG:Risotto\, SAS'));
    expect(vcard, contains('EMAIL;TYPE=INTERNET:elodie@example.com'));
    expect(vcard, contains(r'NOTE:Line 1\nLine 2\; more'));
    expect(vcard, isNot(contains('TEL')));
    expect(vcard, endsWith('END:VCARD\r\n'));
  });

  test('file name is a safe slug', () {
    const card = ContactCard(
      userId: 'u',
      firstName: 'Bob',
      lastName: "D'Urand",
    );
    expect(vCardFileName(card), 'bob-d-urand.vcf');
  });

  test('looksLikeRisottoQr filters foreign codes', () {
    expect(looksLikeRisottoQr('risotto://u/${'a' * 43}'), isTrue);
    expect(looksLikeRisottoQr('https://example.com'), isFalse);
    expect(looksLikeRisottoQr('risotto://u/short'), isFalse);
  });
}
