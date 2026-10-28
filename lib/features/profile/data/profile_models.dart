enum ProfileVisibility {
  public('Public', 'Tous les membres voient votre profil complet.'),
  connections(
    'Relations',
    'Vos relations voient tout ; les autres voient votre nom, titre et photo.',
  ),
  private(
    'Privé',
    'Seul votre nom est visible et vous n’apparaissez pas dans la recherche.',
  );

  const ProfileVisibility(this.label, this.description);

  final String label;
  final String description;

  static ProfileVisibility fromName(String? name) => ProfileVisibility.values
      .firstWhere((v) => v.name == name, orElse: () => connections);
}

/// Connection between the current user and another member.
enum ConnectionStatus { none, pendingOutgoing, pendingIncoming, connected }

class MemberConnection {
  const MemberConnection(this.status, [this.connectionId]);

  factory MemberConnection.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MemberConnection(ConnectionStatus.none);
    }
    final status = switch (json['status']) {
      'pending_outgoing' => ConnectionStatus.pendingOutgoing,
      'pending_incoming' => ConnectionStatus.pendingIncoming,
      'connected' => ConnectionStatus.connected,
      _ => ConnectionStatus.none,
    };
    return MemberConnection(status, json['connectionId'] as String?);
  }

  final ConnectionStatus status;
  final String? connectionId;
}

/// How much of a profile the API returned (depends on visibility and relationship).
enum ProfileAccess { full, preview, minimal }

/// A profile as returned by the API. The privacy settings are only present on the
/// owner's own profile ([isOwn]).
class Profile {
  const Profile({
    required this.userId,
    required this.access,
    required this.firstName,
    required this.lastName,
    this.headline,
    this.jobTitle,
    this.company,
    this.bio,
    this.location,
    this.website,
    this.email,
    this.phone,
    this.photoUrl,
    this.visibility,
    this.shareEmail,
    this.sharePhone,
    this.accountEmail,
    this.connection,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    userId: json['userId'] as String,
    access: ProfileAccess.values.firstWhere(
      (a) => a.name == json['access'],
      orElse: () => ProfileAccess.minimal,
    ),
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    headline: json['headline'] as String?,
    jobTitle: json['jobTitle'] as String?,
    company: json['company'] as String?,
    bio: json['bio'] as String?,
    location: json['location'] as String?,
    website: json['website'] as String?,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    photoUrl: json['photoUrl'] as String?,
    visibility: json.containsKey('visibility')
        ? ProfileVisibility.fromName(json['visibility'] as String?)
        : null,
    shareEmail: json['shareEmail'] as bool?,
    sharePhone: json['sharePhone'] as bool?,
    accountEmail: json['accountEmail'] as String?,
    connection: json.containsKey('connection')
        ? MemberConnection.fromJson(json['connection'] as Map<String, dynamic>?)
        : null,
  );

  final String userId;
  final ProfileAccess access;
  final String firstName;
  final String lastName;
  final String? headline;
  final String? jobTitle;
  final String? company;
  final String? bio;
  final String? location;
  final String? website;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final ProfileVisibility? visibility;
  final bool? shareEmail;
  final bool? sharePhone;
  final String? accountEmail;

  /// Only on other members' profiles and search results.
  final MemberConnection? connection;

  bool get isOwn => visibility != null;

  String get fullName => '$firstName $lastName';

  String get initials =>
      '${firstName.isEmpty ? '' : firstName[0]}${lastName.isEmpty ? '' : lastName[0]}'
          .toUpperCase();

  /// "Job title · Company", whichever parts exist.
  String? get position {
    final parts = [jobTitle, company].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// Editable fields. Empty strings clear optional fields on the server.
class ProfileInput {
  const ProfileInput({
    required this.firstName,
    required this.lastName,
    this.headline = '',
    this.jobTitle = '',
    this.company = '',
    this.bio = '',
    this.location = '',
    this.phone = '',
    this.website = '',
    this.visibility,
    this.shareEmail,
    this.sharePhone,
  });

  final String firstName;
  final String lastName;
  final String headline;
  final String jobTitle;
  final String company;
  final String bio;
  final String location;
  final String phone;
  final String website;
  final ProfileVisibility? visibility;
  final bool? shareEmail;
  final bool? sharePhone;

  Map<String, dynamic> toJson() => {
    'firstName': firstName.trim(),
    'lastName': lastName.trim(),
    'headline': headline.trim(),
    'jobTitle': jobTitle.trim(),
    'company': company.trim(),
    'bio': bio.trim(),
    'location': location.trim(),
    'phone': phone.trim(),
    'website': website.trim(),
    if (visibility != null) 'visibility': visibility!.name,
    if (shareEmail != null) 'shareEmail': shareEmail,
    if (sharePhone != null) 'sharePhone': sharePhone,
  };
}
