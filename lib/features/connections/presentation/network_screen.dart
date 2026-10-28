import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../profile/data/profile_models.dart';
import '../application/connections_providers.dart';
import '../data/connections_models.dart';
import 'widgets/connection_button.dart';
import 'widgets/member_tile.dart';

/// My connections and the pending requests, in three tabs.
class NetworkScreen extends ConsumerWidget {
  const NetworkScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref
        .watch(connectionRequestsProvider(RequestDirection.incoming))
        .value;
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mon réseau'),
          actions: [
            IconButton(
              tooltip: 'Rechercher un membre',
              icon: const Icon(Icons.person_search),
              onPressed: () => context.push(AppRoutes.search),
            ),
            PopupMenuButton<String>(
              tooltip: 'Plus d’options',
              onSelected: (_) => context.push(AppRoutes.blockedUsers),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'blocked', child: Text('Membres bloqués')),
              ],
            ),
          ],
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Relations'),
              Tab(
                text: incoming == null || incoming.isEmpty
                    ? 'Reçues'
                    : 'Reçues (${incoming.length})',
              ),
              const Tab(text: 'Envoyées'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ConnectionList(
              provider: myConnectionsProvider,
              empty:
                  'Pas encore de relations.\nRecherchez un membre ou scannez son QR code.',
            ),
            _ConnectionList(
              provider: connectionRequestsProvider(RequestDirection.incoming),
              empty: 'Aucune demande reçue.',
            ),
            _ConnectionList(
              provider: connectionRequestsProvider(RequestDirection.outgoing),
              empty: 'Aucune demande en attente.',
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
                    itemCount: connections.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
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
                      return MemberTile(
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
                      );
                    },
                  ),
                ),
        );
  }
}
