import '../../connections/data/connections_models.dart';
import '../../messaging/data/messaging_models.dart';
import '../../notifications/data/notifications_models.dart';
import '../../profile/data/profile_models.dart';

class ActivityItem {
  const ActivityItem({
    required this.kind,
    required this.at,
    required this.actor,
    required this.data,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
    kind: NotificationKind.fromApi(json['type'] as String?),
    at: DateTime.parse(json['at'] as String),
    actor: Profile.fromJson(json['actor'] as Map<String, dynamic>),
    data: Map<String, String>.from(
      (json['data'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? {},
    ),
  );

  final NotificationKind kind;
  final DateTime at;
  final Profile actor;
  final Map<String, String> data;

  String get text => switch (kind) {
    NotificationKind.connectionRequest =>
      '${actor.fullName} souhaite rejoindre votre réseau.',
    NotificationKind.connectionAccepted =>
      '${actor.fullName} a accepté votre demande.',
    NotificationKind.message => '${actor.fullName} vous a écrit.',
    NotificationKind.unknown => 'Nouvelle activité.',
  };
}

class Dashboard {
  const Dashboard({
    required this.pendingRequestsCount,
    required this.latestRequests,
    required this.unreadMessagesCount,
    required this.unreadConversations,
    required this.unreadNotifications,
    required this.connectionsCount,
    required this.contactsCount,
    required this.recentActivity,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    final pending = json['pendingRequests'] as Map<String, dynamic>;
    final unread = json['unreadMessages'] as Map<String, dynamic>;
    final stats = json['stats'] as Map<String, dynamic>;
    return Dashboard(
      pendingRequestsCount: pending['count'] as int,
      latestRequests: (pending['latest'] as List<dynamic>)
          .map((c) => Connection.fromJson(c as Map<String, dynamic>))
          .toList(),
      unreadMessagesCount: unread['count'] as int,
      unreadConversations: (unread['conversations'] as List<dynamic>)
          .map((c) => Conversation.fromJson(c as Map<String, dynamic>))
          .toList(),
      unreadNotifications: json['unreadNotifications'] as int,
      connectionsCount: stats['connections'] as int,
      contactsCount: stats['contacts'] as int,
      recentActivity: (json['recentActivity'] as List<dynamic>)
          .map((a) => ActivityItem.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  final int pendingRequestsCount;
  final List<Connection> latestRequests;
  final int unreadMessagesCount;
  final List<Conversation> unreadConversations;
  final int unreadNotifications;
  final int connectionsCount;
  final int contactsCount;
  final List<ActivityItem> recentActivity;
}
