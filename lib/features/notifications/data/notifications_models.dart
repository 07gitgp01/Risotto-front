import '../../profile/data/profile_models.dart';

enum NotificationKind {
  connectionRequest('connection_request', 'Demandes de mise en relation'),
  connectionAccepted('connection_accepted', 'Demandes acceptées'),
  message('message', 'Nouveaux messages'),
  unknown('unknown', 'Autres');

  const NotificationKind(this.apiName, this.label);

  final String apiName;
  final String label;

  static NotificationKind fromApi(String? name) => values.firstWhere(
    (kind) => kind.apiName == name,
    orElse: () => NotificationKind.unknown,
  );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.data,
    required this.createdAt,
    this.actor,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        kind: NotificationKind.fromApi(json['type'] as String?),
        actor: json['actor'] == null
            ? null
            : Profile.fromJson(json['actor'] as Map<String, dynamic>),
        data: Map<String, String>.from(
          (json['data'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? {},
        ),
        readAt: json['readAt'] == null
            ? null
            : DateTime.parse(json['readAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final NotificationKind kind;
  final Profile? actor;
  final Map<String, String> data;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;

  AppNotification markedRead() => AppNotification(
    id: id,
    kind: kind,
    actor: actor,
    data: data,
    readAt: readAt ?? DateTime.now(),
    createdAt: createdAt,
  );

  /// French sentence shown in the list and in the in-app banner.
  String get text {
    final name = actor?.fullName ?? 'Un membre';
    return switch (kind) {
      NotificationKind.connectionRequest =>
        '$name souhaite rejoindre votre réseau.',
      NotificationKind.connectionAccepted =>
        '$name a accepté votre demande de mise en relation.',
      NotificationKind.message => 'Nouveau message de $name.',
      NotificationKind.unknown => 'Nouvelle notification.',
    };
  }
}

class NotificationsPage {
  const NotificationsPage({
    required this.notifications,
    required this.unreadCount,
    this.nextCursor,
  });

  factory NotificationsPage.fromJson(Map<String, dynamic> json) =>
      NotificationsPage(
        notifications: (json['notifications'] as List<dynamic>)
            .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
            .toList(),
        unreadCount: json['unreadCount'] as int,
        nextCursor: json['nextCursor'] as String?,
      );

  final List<AppNotification> notifications;
  final int unreadCount;
  final String? nextCursor;
}

class NotificationPreference {
  const NotificationPreference({
    required this.kind,
    required this.inApp,
    required this.push,
    required this.supportsInApp,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) =>
      NotificationPreference(
        kind: NotificationKind.fromApi(json['type'] as String?),
        inApp: json['inApp'] as bool,
        push: json['push'] as bool,
        supportsInApp: json['supportsInApp'] as bool,
      );

  final NotificationKind kind;
  final bool inApp;
  final bool push;
  final bool supportsInApp;

  NotificationPreference copyWith({bool? inApp, bool? push}) =>
      NotificationPreference(
        kind: kind,
        inApp: inApp ?? this.inApp,
        push: push ?? this.push,
        supportsInApp: supportsInApp,
      );

  Map<String, dynamic> toJson() => {
    'type': kind.apiName,
    'inApp': inApp,
    'push': push,
  };
}
