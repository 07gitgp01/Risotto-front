import '../../../core/router/app_routes.dart';
import '../data/notifications_models.dart';

/// Screen to open for a notification (in-app tap or push tap), or null.
String? routeForNotification(NotificationKind kind, Map<String, String> data) =>
    switch (kind) {
      NotificationKind.connectionRequest => '${AppRoutes.network}?tab=1',
      NotificationKind.connectionAccepted =>
        data['actorId'] == null
            ? null
            : AppRoutes.userProfile(data['actorId']!),
      NotificationKind.message =>
        data['conversationId'] == null
            ? null
            : AppRoutes.chat(data['conversationId']!),
      NotificationKind.unknown => null,
    };

/// Same, from the raw data of a push notification.
String? routeForPushData(Map<String, String> data) =>
    routeForNotification(NotificationKind.fromApi(data['type']), data);
