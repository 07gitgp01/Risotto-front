import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../auth/application/auth_controller.dart';
import '../../connections/presentation/widgets/connection_button.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../dashboard/data/dashboard_models.dart';
import '../../messaging/presentation/time_format.dart';
import '../../notifications/application/notifications_providers.dart';
import '../../notifications/presentation/notification_routes.dart';
import '../../profile/application/my_profile_controller.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';

/// Dashboard: quick actions, pending requests, unread messages, recent activity.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(myProfileProvider).value;
    final dashboard = ref.watch(dashboardProvider);
    final summary = dashboard.value;
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risotto'),
        actions: [
          IconButton(
            tooltip: unreadNotifications > 0
                ? 'Notifications, $unreadNotifications non lues'
                : 'Notifications',
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Badge(
              isLabelVisible: unreadNotifications > 0,
              label: Text('$unreadNotifications'),
              backgroundColor: theme.colorScheme.error,
              textColor: theme.colorScheme.onError,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          if (profile != null)
            IconButton(
              tooltip: 'Mon profil',
              onPressed: () => context.push(AppRoutes.myProfile),
              icon: ProfileAvatar(
                initials: profile.initials,
                photoUrl: profile.photoUrl,
                name: profile.fullName,
                radius: 16,
              ),
            ),
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Semantics(
              header: true,
              child: Text(
                profile == null ? 'Bienvenue' : 'Bonjour, ${profile.firstName}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (summary != null) ...[
              const SizedBox(height: 4),
              Text(
                '${_plural(summary.connectionsCount, 'relation')}'
                ' · ${_plural(summary.contactsCount, 'contact')}',
                style: theme.textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 16),
            _QuickActions(
              unreadMessages: summary?.unreadMessagesCount ?? 0,
              pendingRequests: summary?.pendingRequestsCount ?? 0,
            ),
            const SizedBox(height: 16),
            if (summary == null && dashboard.hasError)
              _ErrorCard(
                message: dashboard.error is ApiException
                    ? (dashboard.error! as ApiException).message
                    : 'Tableau de bord indisponible.',
                onRetry: () => ref.invalidate(dashboardProvider),
              )
            else if (summary == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _PendingRequestsCard(summary: summary),
              const SizedBox(height: 12),
              _UnreadMessagesCard(summary: summary),
              const SizedBox(height: 12),
              _ActivityCard(items: summary.recentActivity),
            ],
          ],
        ),
      ),
    );
  }

  static String _plural(int count, String word) =>
      '$count $word${count > 1 ? 's' : ''}';
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.unreadMessages,
    required this.pendingRequests,
  });

  final int unreadMessages;
  final int pendingRequests;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _HomeAction(
          icon: Icons.qr_code_2,
          label: 'Ma carte',
          onTap: () => context.push(AppRoutes.myCard),
        ),
        _HomeAction(
          icon: Icons.qr_code_scanner,
          label: 'Scanner',
          onTap: () => context.push(AppRoutes.scan),
        ),
        _HomeAction(
          icon: Icons.chat_bubble_outline,
          label: 'Messages',
          badge: unreadMessages,
          onTap: () => context.push(AppRoutes.messages),
        ),
        _HomeAction(
          icon: Icons.group_outlined,
          label: 'Réseau',
          badge: pendingRequests,
          onTap: () => context.push(AppRoutes.network),
        ),
        _HomeAction(
          icon: Icons.person_search,
          label: 'Rechercher',
          onTap: () => context.push(AppRoutes.search),
        ),
        _HomeAction(
          icon: Icons.contacts_outlined,
          label: 'Contacts',
          onTap: () => context.push(AppRoutes.contacts),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.count,
    this.onSeeAll,
  });

  final String title;
  final int? count;
  final VoidCallback? onSeeAll;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      count == null ? title : '$title ($count)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (onSeeAll != null)
                  TextButton(
                    onPressed: onSeeAll,
                    child: const Text('Tout voir'),
                  ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8, right: 8),
    child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
  );
}

class _PendingRequestsCard extends StatelessWidget {
  const _PendingRequestsCard({required this.summary});

  final Dashboard summary;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Demandes en attente',
      count: summary.pendingRequestsCount,
      onSeeAll: summary.pendingRequestsCount > 0
          ? () => context.push('${AppRoutes.network}?tab=1')
          : null,
      children: summary.latestRequests.isEmpty
          ? const [_Empty('Aucune demande en attente.')]
          : [
              for (final request in summary.latestRequests)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PersonRow(
                        profile: request.user,
                        subtitle: request.message ?? request.user.headline,
                        onTap: () => context.push(
                          AppRoutes.userProfile(request.user.userId),
                        ),
                      ),
                      ConnectionButton(
                        userId: request.user.userId,
                        name: request.user.firstName,
                        state: MemberConnection(
                          ConnectionStatus.pendingIncoming,
                          request.id,
                        ),
                        compact: true,
                      ),
                    ],
                  ),
                ),
            ],
    );
  }
}

class _UnreadMessagesCard extends StatelessWidget {
  const _UnreadMessagesCard({required this.summary});

  final Dashboard summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _SectionCard(
      title: 'Messages non lus',
      count: summary.unreadMessagesCount,
      onSeeAll: () => context.push(AppRoutes.messages),
      children: summary.unreadConversations.isEmpty
          ? const [_Empty('Vous êtes à jour.')]
          : [
              for (final conversation in summary.unreadConversations)
                _PersonRow(
                  profile: conversation.user,
                  subtitle: conversation.lastMessage?.body,
                  trailing: Badge(
                    label: Text('${conversation.unreadCount}'),
                    backgroundColor: colors.error,
                    textColor: colors.onError,
                  ),
                  onTap: () => context.push(AppRoutes.chat(conversation.id)),
                ),
            ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.items});

  final List<ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Activité récente',
      children: items.isEmpty
          ? const [
              _Empty(
                'Rien de neuf pour l’instant. Partagez votre carte pour agrandir votre réseau.',
              ),
            ]
          : [
              for (final item in items)
                _PersonRow(
                  profile: item.actor,
                  title: item.text,
                  subtitle: shortTime(item.at),
                  onTap: () {
                    final route = routeForNotification(item.kind, {
                      ...item.data,
                      'actorId': item.actor.userId,
                    });
                    if (route != null) {
                      context.push(route);
                    }
                  },
                ),
            ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.profile,
    required this.onTap,
    this.title,
    this.subtitle,
    this.trailing,
  });

  final Profile profile;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: ProfileAvatar(
      initials: profile.initials,
      photoUrl: profile.photoUrl,
      name: profile.fullName,
      radius: 20,
    ),
    title: Text(title ?? profile.fullName),
    subtitle: subtitle == null
        ? null
        : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: trailing,
    onTap: onTap,
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    ),
  );
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Count shown on the icon (hidden when 0).
  final int badge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 104,
      child: Material(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                Badge(
                  isLabelVisible: badge > 0,
                  label: Text('$badge'),
                  backgroundColor: colors.error,
                  textColor: colors.onError,
                  child: Icon(icon, size: 32, color: colors.secondary),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  semanticsLabel: badge > 0
                      ? '$label, $badge en attente'
                      : label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
