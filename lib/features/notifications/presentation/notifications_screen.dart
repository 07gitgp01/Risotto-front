import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/open_route.dart';
import '../../../core/theme/risotto_colors.dart';
import '../../../core/widgets/risotto_ui.dart';
import '../../connections/application/connections_providers.dart';
import '../../connections/data/connections_models.dart';
import '../../connections/presentation/widgets/connection_button.dart';
import '../../messaging/presentation/time_format.dart';
import '../../profile/data/profile_models.dart';
import '../application/notifications_providers.dart';
import '../data/notifications_models.dart';
import 'notification_routes.dart';
import 'widgets/actor_avatar.dart';

enum _Filter { all, network, messages }

/// Design: notifications. The mockup's security alerts, end-to-end encryption
/// and "contacts communs" are left out: the app has none of them.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  _Filter _filter = _Filter.all;

  static bool _matches(_Filter filter, NotificationKind kind) =>
      switch (filter) {
        _Filter.all => true,
        _Filter.network =>
          kind == NotificationKind.connectionRequest ||
              kind == NotificationKind.connectionAccepted,
        _Filter.messages => kind == NotificationKind.message,
      };

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Préférences de notification',
            icon: const Icon(Icons.tune),
            onPressed: () => context.push(AppRoutes.notificationSettings),
          ),
        ],
      ),
      body: notifications.when(
        loading: () => const PageLoading(),
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
        data: (state) {
          final all = state.notifications;
          final shown = all.where((n) => _matches(_filter, n.kind)).toList();
          final now = DateTime.now();
          bool isToday(AppNotification n) {
            final local = n.createdAt.toLocal();
            return local.year == now.year &&
                local.month == now.month &&
                local.day == now.day;
          }

          final today = shown.where(isToday).toList();
          final earlier = shown.where((n) => !isToday(n)).toList();
          int count(_Filter filter) =>
              all.where((n) => _matches(filter, n.kind)).length;

          return RefreshIndicator(
            onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (unread > 0) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      avatar: const Icon(
                        Icons.done_all,
                        size: 18,
                        color: RisottoColors.basil,
                      ),
                      label: const Text('Tout marquer comme lu'),
                      onPressed: () => ref
                          .read(notificationsProvider.notifier)
                          .markAllRead(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (filter, label) in const [
                        (_Filter.all, 'Toutes'),
                        (_Filter.network, 'Réseau'),
                        (_Filter.messages, 'Messages'),
                      ]) ...[
                        ChoiceChip(
                          label: Text('$label (${count(filter)})'),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (unread > 0) ...[
                  const InfoPanel(
                    icon: Icons.swipe_left_outlined,
                    text:
                        'Glissez une notification vers la gauche pour la '
                        'marquer comme lue.',
                  ),
                  const SizedBox(height: 4),
                ],
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      all.isEmpty
                          ? 'Aucune notification pour le moment.'
                          : 'Aucune notification dans cette catégorie.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (today.isNotEmpty) ...[
                  _GroupHeader(
                    title: 'Aujourd’hui',
                    count: today.length,
                    accent: true,
                  ),
                  for (final notification in today)
                    _NotificationTile(notification: notification),
                ],
                if (earlier.isNotEmpty) ...[
                  _GroupHeader(title: 'Plus tôt', count: earlier.length),
                  for (final notification in earlier)
                    _NotificationTile(notification: notification),
                ],
                const SizedBox(height: 12),
                SurfaceCard(
                  onTap: () => context.push(AppRoutes.notificationSettings),
                  child: Row(
                    children: [
                      const IconTile(
                        Icons.notifications_active_outlined,
                        tone: PillTone.neutral,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Préférences d’alertes',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Text(
                              'Choisir les notifications dans l’app et push',
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.title,
    required this.count,
    this.accent = false,
  });

  final String title;
  final int count;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleLarge),
          ),
          if (accent) ...[
            const SizedBox(width: 6),
            const ExcludeSemantics(
              child: Icon(Icons.circle, size: 8, color: RisottoColors.saffron),
            ),
          ],
          const Spacer(),
          Text(
            count > 1 ? '$count notifications' : '$count notification',
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  void _open(BuildContext context, WidgetRef ref) {
    ref.read(notificationsProvider.notifier).markRead(notification.id).ignore();
    final route = routeForNotification(notification.kind, notification.data);
    if (route != null) {
      openRoute(GoRouter.of(context), route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actor = notification.actor;
    final badge = notificationIcon(notification.kind);
    final (pill, tone) = switch (notification.kind) {
      NotificationKind.connectionRequest => (
        'Nouvelle demande',
        PillTone.saffron,
      ),
      NotificationKind.connectionAccepted => (
        'Nouvelle relation',
        PillTone.basil,
      ),
      NotificationKind.message => ('Message', PillTone.neutral),
      NotificationKind.unknown => ('Risotto', PillTone.neutral),
    };
    // Accept / decline right here while the request is still pending.
    final pending = notification.kind == NotificationKind.connectionRequest
        ? ref
              .watch(connectionRequestsProvider(RequestDirection.incoming))
              .value
              ?.where((r) => r.id == notification.data['connectionId'])
              .firstOrNull
        : null;

    final card = SurfaceCard(
      onTap: () => _open(context, ref),
      child: Container(
        decoration: notification.isRead
            ? null
            : const BoxDecoration(
                border: Border(
                  left: BorderSide(color: RisottoColors.saffron, width: 3),
                ),
              ),
        padding: EdgeInsets.only(left: notification.isRead ? 0 : 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (actor == null)
                  IconTile(badge, tone: tone)
                else
                  ActorAvatar(actor: actor, kind: notification.kind),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: StatusPill(pill, tone: tone),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            shortTime(notification.createdAt),
                            style: theme.textTheme.labelMedium,
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 6),
                            Semantics(
                              label: 'Non lue',
                              child: const Icon(
                                Icons.circle,
                                size: 10,
                                color: RisottoColors.tomato,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.text,
                        style: notification.isRead
                            ? theme.textTheme.bodyMedium
                            : theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (pending != null && actor != null) ...[
              const SizedBox(height: 12),
              ConnectionButton(
                userId: actor.userId,
                name: actor.firstName,
                state: MemberConnection(
                  ConnectionStatus.pendingIncoming,
                  pending.id,
                ),
                compact: true,
              ),
            ],
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: notification.isRead
          ? card
          : Dismissible(
              key: ValueKey('notification-${notification.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  color: RisottoColors.basilSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.done, color: RisottoColors.basil),
                    SizedBox(width: 6),
                    Text(
                      'Lue',
                      style: TextStyle(
                        color: RisottoColors.basil,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Marks as read, but the notification stays in the list.
              confirmDismiss: (_) async {
                await ref
                    .read(notificationsProvider.notifier)
                    .markRead(notification.id);
                return false;
              },
              child: card,
            ),
    );
  }
}
