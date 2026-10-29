import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/risotto_colors.dart';
import '../../../core/theme/risotto_theme.dart';
import '../../../core/widgets/risotto_ui.dart';
import '../../profile/data/profile_models.dart';
import '../../shell/main_app_bar.dart';
import '../application/connections_providers.dart';
import '../data/connections_models.dart';
import 'widgets/connection_button.dart';
import 'widgets/member_tile.dart';

/// Réseau tab (design: r_seau): search, my connections and pending requests.
class NetworkScreen extends ConsumerWidget {
  const NetworkScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref
        .watch(connectionRequestsProvider(RequestDirection.incoming))
        .value;
    final connections = ref.watch(myConnectionsProvider).value;
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
                  tabs: [
                    Tab(
                      text: connections == null || connections.isEmpty
                          ? 'Relations'
                          : 'Relations (${connections.length})',
                    ),
                    Tab(
                      text: incoming == null || incoming.isEmpty
                          ? 'Demandes'
                          : 'Demandes (${incoming.length})',
                    ),
                    const Tab(text: 'Envoyées'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  _ConnectionList(
                    provider: myConnectionsProvider,
                    empty:
                        'Pas encore de relations.\nRecherchez un membre ou scannez son QR code.',
                  ),
                  _ConnectionList(
                    provider: connectionRequestsProvider(
                      RequestDirection.incoming,
                    ),
                    empty: 'À jour ! Vous n’avez pas de demande en attente.',
                  ),
                  _ConnectionList(
                    provider: connectionRequestsProvider(
                      RequestDirection.outgoing,
                    ),
                    empty: 'Aucune demande envoyée en attente.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionList extends ConsumerWidget {
  const _ConnectionList({required this.provider, required this.empty});

  final FutureProvider<List<Connection>> provider;
  final String empty;

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
          data: (connections) => connections.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(empty, textAlign: TextAlign.center),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.refresh(provider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: connections.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final connection = connections[index];
                      final state = MemberConnection(
                        connection.status == 'accepted'
                            ? ConnectionStatus.connected
                            : connection.direction == RequestDirection.incoming
                            ? ConnectionStatus.pendingIncoming
                            : ConnectionStatus.pendingOutgoing,
                        connection.id,
                      );
                      return SurfaceCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: MemberTile(
                          profile: connection.user,
                          below: connection.status == 'accepted'
                              ? null
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (connection.message != null) ...[
                                      Text(
                                        '« ${connection.message} »',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    ConnectionButton(
                                      userId: connection.user.userId,
                                      name: connection.user.firstName,
                                      state: state,
                                      compact: true,
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
        );
  }
}
