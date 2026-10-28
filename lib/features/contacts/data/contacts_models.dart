/// Business card shared through the personal QR code.
class ContactCard {
  const ContactCard({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.headline,
    this.jobTitle,
    this.company,
    this.location,
    this.website,
    this.email,
    this.phone,
    this.photoUrl,
  });

  factory ContactCard.fromJson(Map<String, dynamic> json) => ContactCard(
    userId: json['userId'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    headline: json['headline'] as String?,
    jobTitle: json['jobTitle'] as String?,
    company: json['company'] as String?,
    location: json['location'] as String?,
    website: json['website'] as String?,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    photoUrl: json['photoUrl'] as String?,
  );

  final String userId;
  final String firstName;
  final String lastName;
  final String? headline;
  final String? jobTitle;
  final String? company;
  final String? location;
  final String? website;
  final String? email;
  final String? phone;
  final String? photoUrl;

  String get fullName => '$firstName $lastName';

  String get initials =>
      '${firstName.isEmpty ? '' : firstName[0]}${lastName.isEmpty ? '' : lastName[0]}'
          .toUpperCase();

  String? get position {
    final parts = [jobTitle, company].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class QrCode {
  const QrCode({required this.token, required this.payload});

  factory QrCode.fromJson(Map<String, dynamic> json) => QrCode(
    token: json['token'] as String,
    payload: json['payload'] as String,
  );

  final String token;

  /// Exact string encoded in the QR code (`risotto://u/<token>`).
  final String payload;
}

class ScanResult {
  const ScanResult({
    required this.card,
    required this.isSelf,
    required this.saved,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
    card: ContactCard.fromJson(json['card'] as Map<String, dynamic>),
    isSelf: json['isSelf'] as bool,
    saved: json['saved'] as bool,
  );

  final ContactCard card;
  final bool isSelf;
  final bool saved;
}

class SavedContact {
  const SavedContact({required this.card, required this.savedAt, this.note});

  factory SavedContact.fromJson(Map<String, dynamic> json) => SavedContact(
    card: ContactCard.fromJson(json['card'] as Map<String, dynamic>),
    note: json['note'] as String?,
    savedAt: DateTime.parse(json['savedAt'] as String),
  );

  final ContactCard card;
  final String? note;
  final DateTime savedAt;

  SavedContact withNote(String? note) =>
      SavedContact(card: card, savedAt: savedAt, note: note);
}

/// Quick local check before calling the API: is this a Risotto QR code?
bool looksLikeRisottoQr(String payload) =>
    RegExp(r'^risotto://u/[A-Za-z0-9_-]{32,64}$').hasMatch(payload.trim());
