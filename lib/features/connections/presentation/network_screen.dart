import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/risotto_colors.dart';
import '../../../core/theme/risotto_theme.dart';
import '../../../core/widgets/risotto_ui.dart';
import '../../messaging/application/open_chat.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';
import '../../shell/main_app_bar.dart';
import '../application/connections_providers.dart';
import '../data/connections_models.dart';
import 'widgets/connection_button.dart';

/// Réseau tab (design: r_seau): search, my connections and pending requests.
/// Recommendations, mutual connections and sector filters are not shown:
/// the API has none of them.
class NetworkScreen extends ConsumerWidget {
  const NetworkScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref
        .watch(connectionRequestsProvider(RequestDirection.incoming))
        .value;
    final connections = ref.watch(myConnectionsProvider).value;
    final pending = incoming?.length ?? 0;
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: MainAppBar(
          title: 'Réseau',
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Plus d’options',
              onSelected: (route) => context.push(route),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: AppRoutes.contacts,
                  child: Text('Mes contacts'),
                ),
                PopupMenuItem(
                  value: AppRoutes.blockedUsers,
                  child: Text('Membres bloqués'),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Semantics(
                button: true,
                label: 'Rechercher un membre',
                excludeSemantics: true,
                child: TextField(
                  readOnly: true,
                  onTap: () => context.push(AppRoutes.search),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher par nom, métier ou entreprise',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: RisottoColors.creamDark,
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: RisottoColors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: risottoCardShadow,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.zero,
                  labelColor: RisottoColors.basil,
                  tabs: [
                    Tab(
                      text: connections == null || connections.isEmpty
                          ? 'Relations'
                          : 'Relations (${connections.length})',
                    ),
                    Tab(
                      child: Semantics(
                        label: pending == 0 ? null : 'Demandes ($pending)',
                        excludeSemantics: pending > 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Demandes'),
                            if (pending > 0) ...[
                              const SizedBox(width: 6),
                              CountBadge(pending),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const Tab(text: 'Envoyées'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Expanded(
              child: TabBarView(
                children: [_ConnectionsTab(), _IncomingTab(), _OutgoingTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Saffron circle with a count (charcoal text, as the brand requires).
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 22),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: RisottoColors.saffron,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      count > 99 ? '99+' : '$count',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: RisottoColors.charcoal,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Loading, error and refresh around a list of connections.
class _AsyncList extends ConsumerWidget {
  const _AsyncList({required this.provider, required this.builder});

  final FutureProvider<List<Connection>> provider;
  final List<Widget> Function(BuildContext, List<Connection>) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(provider)
        .when(
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
                        : 'Impossible de charger la liste.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(provider),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
          data: (connections) => RefreshIndicator(
            onRefresh: () => ref.refresh(provider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: builder(context, connections),
            ),
          ),
        );
  }
}

class _ConnectionsTab extends ConsumerWidget {
  const _ConnectionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming =
        ref
            .watch(connectionRequestsProvider(RequestDirection.incoming))
            .value ??
        const <Connection>[];
    return _AsyncList(
      provider: myConnectionsProvider,
      builder: (context, connections) => [
        // Design: the pending requests come first, with a shortcut to all.
        if (incoming.isNotEmpty) ...[
          SectionHeader(
            title: 'Demandes en attente (${incoming.length})',
            actionLabel: incoming.length > 1 ? 'Voir tout' : null,
            onAction: () => DefaultTabController.of(context).animateTo(1),
          ),
          _RequestCard(request: incoming.first),
          const SizedBox(height: 8),
        ],
        SectionHeader(
          title: connections.isEmpty
              ? 'Mes relations'
              : 'Mes relations (${connections.length})',
        ),
        if (connections.isEmpty)
          const _EmptyCard(
            icon: Icons.diversity_3_outlined,
            title: 'Pas encore de relations',
            text: 'Recherchez un membre ou scannez son QR code.',
          )
        else
          for (final connection in connections) ...[
            _RelationCard(profile: connection.user),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _IncomingTab extends StatelessWidget {
  const _IncomingTab();

  @override
  Widget build(BuildContext context) => _AsyncList(
    provider: connectionRequestsProvider(RequestDirection.incoming),
    builder: (context, requests) => [
      for (final request in requests) ...[
        _RequestCard(request: request),
        const SizedBox(height: 12),
      ],
      if (requests.isEmpty)
        const _EmptyCard(
          icon: Icons.spa_outlined,
          title: 'À jour !',
          text: 'Vous n’avez pas de demande en attente.',
        ),
    ],
  );
}

class _OutgoingTab extends StatelessWidget {
  const _OutgoingTab();

  @override
  Widget build(BuildContext context) => _AsyncList(
    provider: connectionRequestsProvider(RequestDirection.outgoing),
    builder: (context, requests) => [
      for (final request in requests) ...[
        SurfaceCard(
          onTap: () => context.push(AppRoutes.userProfile(request.user.userId)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PersonHeader(
                profile: request.user,
                badge: const StatusPill(
                  'En attente',
                  tone: PillTone.saffron,
                  icon: Icons.hourglass_top,
                ),
              ),
              const SizedBox(height: 12),
              ConnectionButton(
                userId: request.user.userId,
                name: request.user.firstName,
                state: MemberConnection(
                  ConnectionStatus.pendingOutgoing,
                  request.id,
                ),
                compact: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (requests.isEmpty)
        const _EmptyCard(
          icon: Icons.outbox_outlined,
          title: 'Aucune demande envoyée',
          text: 'Les demandes que vous envoyez attendent ici une réponse.',
        ),
    ],
  );
}

/// Avatar, name, headline and an optional badge on the right.
class _PersonHeader extends StatelessWidget {
  const _PersonHeader({required this.profile, this.badge});

  final Profile profile;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = profile.position ?? profile.headline;
    return Row(
      children: [
        ProfileAvatar(
          initials: profile.initials,
          photoUrl: profile.photoUrl,
          name: profile.fullName,
          radius: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              if (profile.location != null)
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        profile.location!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (badge != null) ...[const SizedBox(width: 8), badge!],
      ],
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PersonHeader(profile: request.user),
          if (request.message != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RisottoColors.cream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('« ${request.message} »'),
            ),
          ],
          const SizedBox(height: 12),
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

class _RelationCard extends ConsumerWidget {
  const _RelationCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      onTap: () => context.push(AppRoutes.userProfile(profile.userId)),
      child: _PersonHeader(
        profile: profile,
        badge: IconButton.filledTonal(
          tooltip: 'Écrire à ${profile.firstName}',
          style: IconButton.styleFrom(
            backgroundColor: RisottoColors.basilSoft,
            foregroundColor: RisottoColors.basil,
          ),
          onPressed: () => openChatWith(context, ref, profile.userId),
          icon: const Icon(Icons.chat_bubble_outline),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RisottoColors.creamDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: RisottoColors.basilSoft,
            child: Icon(icon, color: RisottoColors.basil),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
