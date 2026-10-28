import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../messaging/presentation/time_format.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';
import '../application/notifications_providers.dart';
import 'notification_routes.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text('Tout lire'),
            ),
          IconButton(
            tooltip: 'Préférences de notification',
            icon: const Icon(Icons.tune),
            onPressed: () => context.push(AppRoutes.notificationSettings),
          ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is ApiException
                      ? error.message
                      : 'Impossible de charger les notifications.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(notificationsProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (state) => state.notifications.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Aucune notification pour le moment.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
                child: ListView.separated(
                  itemCount: state.notifications.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];
                    final actor = notification.actor;
                    final theme = Theme.of(context);
                    return ListTile(
                      tileColor: notification.isRead
                          ? null
                          : theme.colorScheme.primaryContainer,
                      leading: actor == null
                          ? const Icon(Icons.notifications_outlined)
                          : ProfileAvatar(
                              initials: actor.initials,
                              photoUrl: actor.photoUrl,
                              name: actor.fullName,
                              radius: 22,
                            ),
                      title: Text(
                        notification.text,
                        style: notification.isRead
                            ? null
                            : const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(shortTime(notification.createdAt)),
                      trailing: notification.isRead
                          ? null
                          : Semantics(
                              label: 'Non lue',
                              child: Icon(
                                Icons.circle,
                                size: 12,
                                color: theme.colorScheme.error,
                              ),
                            ),
                      onTap: () {
                        ref
                            .read(notificationsProvider.notifier)
                            .markRead(notification.id)
                            .ignore();
                        final route = routeForNotification(
                          notification.kind,
                          notification.data,
                        );
                        if (route != null) {
                          context.push(route);
                        }
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }
}
