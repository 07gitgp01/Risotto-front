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
import '../../dashboard/application/dashboard_provider.dart';
import '../../dashboard/data/dashboard_models.dart';
import '../../messaging/data/messaging_repository.dart';
import '../../messaging/presentation/time_format.dart';
import '../../notifications/presentation/notification_routes.dart';
import '../../profile/application/my_profile_controller.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';
import '../../shell/main_app_bar.dart';

/// Home tab (design: accueil): my card, key figures, recent contacts, activity.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(myProfileProvider).value;
    final dashboard = ref.watch(dashboardProvider);
    final summary = dashboard.value;

    return Scaffold(
      appBar: const MainAppBar(title: 'Accueil'),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Semantics(
              header: true,
              child: Text(
                profile == null ? 'Bienvenue' : 'Bonjour, ${profile.firstName}',
                style: theme.textTheme.headlineLarge,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Voici l’essentiel de votre réseau aujourd’hui.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const _CardPass(),
            const SizedBox(height: 16),
            if (summary == null && dashboard.hasError)
              _ErrorCard(
                message: dashboard.error is ApiException
                    ? (dashboard.error! as ApiException).message
                    : 'Tableau de bord indisponible.',
                onRetry: () => ref.invalidate(dashboardProvider),
              )
            else if (summary == null)
              const Padding(padding: EdgeInsets.all(32), child: PageLoading())
            else ...[
              _KeyFigures(summary: summary),
              if (summary.latestRequests.isNotEmpty) ...[
                SectionHeader(
                  title:
                      'Demandes en attente (${summary.pendingRequestsCount})',
                  actionLabel: 'Tout voir',
                  onAction: () => context.go('${AppRoutes.network}?tab=1'),
                ),
                for (final request in summary.latestRequests) ...[
                  _RequestCard(request: request),
                  const SizedBox(height: 12),
                ],
              ],
              const _RecentContacts(),
              SectionHeader(
                title: 'Messages non lus (${summary.unreadMessagesCount})',
                actionLabel: 'Tout voir',
                onAction: () => context.go(AppRoutes.messages),
              ),
              if (summary.unreadConversations.isEmpty)
                const _EmptyLine('Vous êtes à jour.')
              else
                for (final conversation in summary.unreadConversations) ...[
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    onTap: () => context.push(AppRoutes.chat(conversation.id)),
                    child: _PersonRow(
                      profile: conversation.user,
                      subtitle: conversation.lastMessage?.body,
                      trailing: Badge(
                        label: Text('${conversation.unreadCount}'),
                        backgroundColor: RisottoColors.saffron,
                        textColor: RisottoColors.charcoal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              const SectionHeader(title: 'Activité récente'),
              if (summary.recentActivity.isEmpty)
                const _EmptyLine(
                  'Rien de neuf pour l’instant. Partagez votre carte pour agrandir votre réseau.',
                )
              else
                for (final item in summary.recentActivity) ...[
                  _ActivityCard(item: item),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 12),
              const TipCard(
                title: 'Astuce Risotto du jour',
                text:
                    'Gardez votre carte à portée de main : un scan de votre QR code suffit '
                    'pour partager vos coordonnées et recevoir une demande de mise en relation.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Ma carte Risotto" shortcut (design: Pass Risotto).
class _CardPass extends StatelessWidget {
  const _CardPass();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      gradient: const LinearGradient(
        colors: [RisottoColors.white, Color(0xFFFFF1D2)],
      ),
      onTap: () => context.push(AppRoutes.myCard),
      child: Row(
        children: [
          const IconTile(Icons.qr_code_2, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ma carte Risotto',
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Prête pour vos rencontres',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => context.push(AppRoutes.myCard),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Afficher'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyFigures extends StatelessWidget {
  const _KeyFigures({required this.summary});

  final Dashboard summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _FigureTile(
            icon: Icons.person_add_alt_1_outlined,
            tone: PillTone.tomato,
            value: summary.pendingRequestsCount,
            label: 'Demandes reçues',
            onTap: () => context.go('${AppRoutes.network}?tab=1'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FigureTile(
            icon: Icons.chat_bubble_outline,
            tone: PillTone.saffron,
            value: summary.unreadMessagesCount,
            label: 'Messages non lus',
            onTap: () => context.go(AppRoutes.messages),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FigureTile(
            icon: Icons.group_outlined,
            tone: PillTone.basil,
            value: summary.connectionsCount,
            label: summary.connectionsCount > 1 ? 'Relations' : 'Relation',
            onTap: () => context.go(AppRoutes.network),
          ),
        ),
      ],
    );
  }
}

class _FigureTile extends StatelessWidget {
  const _FigureTile({
    required this.icon,
    required this.tone,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final PillTone tone;
  final int value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '$value $label',
      excludeSemantics: true,
      child: SurfaceCard(
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(icon, tone: tone, size: 36),
            const SizedBox(height: 12),
            Text('$value', style: theme.textTheme.headlineSmall),
            Text(label, style: theme.textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final Connection request;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: () => context.push(AppRoutes.userProfile(request.user.userId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PersonRow(
            profile: request.user,
            subtitle: request.message ?? request.user.headline,
          ),
          const SizedBox(height: 8),
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
    );
  }
}

/// Horizontal list of my latest connections, with a shortcut to write to them.
class _RecentContacts extends ConsumerWidget {
  const _RecentContacts();

  Future<void> _write(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final conversation = await ref
          .read(messagingRepositoryProvider)
          .start(userId);
      if (context.mounted) {
        await context.push(AppRoutes.chat(conversation.id));
      }
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connections = ref.watch(myConnectionsProvider).value ?? const [];
    if (connections.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Contacts récents',
          actionLabel: 'Voir tout',
          onAction: () => context.go(AppRoutes.network),
        ),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: connections.length.clamp(0, 10),
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final user = connections[index].user;
              return SizedBox(
                width: 156,
                child: SurfaceCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () => context.push(AppRoutes.userProfile(user.userId)),
                  child: Column(
                    children: [
                      ProfileAvatar(
                        initials: user.initials,
                        photoUrl: user.photoUrl,
                        name: user.fullName,
                        radius: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        user.position ?? user.headline ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: () => _write(context, ref, user.userId),
                        style: FilledButton.styleFrom(
                          backgroundColor: RisottoColors.basilSoft,
                          foregroundColor: RisottoColors.basil,
                          minimumSize: const Size(120, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: Text(
                          'Écrire',
                          semanticsLabel: 'Écrire à ${user.firstName}',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {
        final route = routeForNotification(item.kind, {
          ...item.data,
          'actorId': item.actor.userId,
        });
        if (route != null) {
          openRoute(GoRouter.of(context), route);
        }
      },
      child: _PersonRow(
        profile: item.actor,
        title: item.text,
        subtitle: shortTime(item.at),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.profile,
    this.title,
    this.subtitle,
    this.trailing,
  });

  final Profile profile;
  final String? title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: ProfileAvatar(
      initials: profile.initials,
      photoUrl: profile.photoUrl,
      name: profile.fullName,
      radius: 22,
    ),
    title: Text(title ?? profile.fullName),
    subtitle: subtitle == null
        ? null
        : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: trailing,
  );
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
    ),
  );
}
