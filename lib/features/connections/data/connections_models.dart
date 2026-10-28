import '../../profile/data/profile_models.dart';

enum RequestDirection { incoming, outgoing }

/// A connection or a pending request, from the current user's point of view.
class Connection {
  const Connection({
    required this.id,
    required this.status,
    required this.direction,
    required this.createdAt,
    required this.user,
    this.message,
  });

  factory Connection.fromJson(Map<String, dynamic> json) => Connection(
    id: json['id'] as String,
    status: json['status'] as String,
    direction: json['direction'] == 'incoming'
        ? RequestDirection.incoming
        : RequestDirection.outgoing,
    message: json['message'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    user: Profile.fromJson(json['user'] as Map<String, dynamic>),
  );

  final String id;

  /// `pending` or `accepted`.
  final String status;
  final RequestDirection direction;
  final String? message;
  final DateTime createdAt;

  /// The other member.
  final Profile user;
}

class BlockedUser {
  const BlockedUser({required this.userId, this.firstName, this.lastName});

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
    userId: json['userId'] as String,
    firstName: json['firstName'] as String?,
    lastName: json['lastName'] as String?,
  );

  final String userId;
  final String? firstName;
  final String? lastName;

  String get displayName =>
      [firstName, lastName].whereType<String>().join(' ').trim().isEmpty
      ? 'Membre'
      : [firstName, lastName].whereType<String>().join(' ');
}
