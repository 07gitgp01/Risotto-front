import '../data/contacts_models.dart';

/// vCard 3.0, readable by the Android and iOS address books.
String buildVCard(ContactCard card) {
  String escape(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('\n', r'\n')
      .replaceAll(',', r'\,')
      .replaceAll(';', r'\;');

  final lines = <String>[
    'BEGIN:VCARD',
    'VERSION:3.0',
    'N:${escape(card.lastName)};${escape(card.firstName)};;;',
    'FN:${escape(card.fullName)}',
    if (card.company != null) 'ORG:${escape(card.company!)}',
    if (card.jobTitle != null) 'TITLE:${escape(card.jobTitle!)}',
    if (card.email != null) 'EMAIL;TYPE=INTERNET:${escape(card.email!)}',
    if (card.phone != null) 'TEL;TYPE=CELL:${escape(card.phone!)}',
    if (card.website != null) 'URL:${escape(card.website!)}',
    if (card.location != null) 'ADR;TYPE=WORK:;;;${escape(card.location!)};;;',
    if (card.headline != null) 'NOTE:${escape(card.headline!)}',
    'END:VCARD',
  ];
  return '${lines.join('\r\n')}\r\n';
}

/// File name for the shared vCard, e.g. `alice-martin.vcf`.
String vCardFileName(ContactCard card) {
  final slug = card.fullName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return '${slug.isEmpty ? 'contact' : slug}.vcf';
}
