import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/risotto_colors.dart';
import '../../../core/widgets/risotto_ui.dart';
import '../../auth/application/auth_controller.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';

/// Platform figures and account moderation. Reserved to admins (the router and,
/// above all, the API check the role).
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  AccountFilter _filter = AccountFilter.all;
  List<AdminAccount> _accounts = const [];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  AdminRepository get _repository => ref.read(adminRepositoryProvider);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repository.accounts(
        query: _search.text,
        filter: _filter,
      );
      if (mounted) {
        setState(() {
          _accounts = page.items;
          _total = page.total;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final page = await _repository.accounts(
        query: _search.text,
        filter: _filter,
        offset: _accounts.length,
      );
      if (mounted) {
        setState(() {
          _accounts = [..._accounts, ...page.items];
          _total = page.total;
        });
      }
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(adminStatsProvider);
    await _load();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  void _showMessage(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _toggleSuspension(AdminAccount account) async {
    final label = account.name ?? account.email;
    if (!account.isSuspended) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Suspendre $label ?'),
          content: const Text(
            'Ses sessions seront fermées tout de suite et il ne pourra plus '
            'se connecter. Il disparaît aussi de la recherche. Vous pourrez '
            'le réactiver à tout moment.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: RisottoColors.tomatoDeep,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Suspendre'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    }
    try {
      if (account.isSuspended) {
        await _repository.reactivate(account.id);
      } else {
        await _repository.suspend(account.id);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _accounts = [
          for (final item in _accounts)
            item.id == account.id
                ? item.copyWith(
                    suspendedAt: account.isSuspended ? null : DateTime.now(),
                  )
                : item,
        ];
      });
      ref.invalidate(adminStatsProvider);
      _showMessage(
        account.isSuspended ? '$label réactivé.' : '$label suspendu.',
      );
    } on ApiException catch (error) {
      _showMessage(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = switch (ref.watch(authControllerProvider)) {
      Authenticated(:final user) => user.id,
      _ => null,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const _StatsSection(),
            const SectionHeader(title: 'Comptes'),
            TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Rechercher par nom ou email',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<AccountFilter>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: AccountFilter.all, label: Text('Tous')),
                ButtonSegment(
                  value: AccountFilter.active,
                  label: Text('Actifs'),
                ),
                ButtonSegment(
                  value: AccountFilter.suspended,
                  label: Text('Suspendus'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) {
                setState(() => _filter = selection.first);
                unawaited(_load());
              },
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(padding: EdgeInsets.all(32), child: PageLoading())
            else if (_error != null)
              _ErrorBlock(message: _error!, onRetry: _load)
            else if (_accounts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Aucun compte trouvé.',
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              Text(
                _total > 1 ? '$_total comptes' : '$_total compte',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              for (final account in _accounts) ...[
                _AccountCard(
                  key: ValueKey('account-${account.id}'),
                  account: account,
                  // Neither oneself nor another admin can be suspended.
                  canModerate: !account.isAdmin && account.id != me,
                  onToggle: () => _toggleSuspension(account),
                ),
                const SizedBox(height: 12),
              ],
              if (_accounts.length < _total)
                Center(
                  child: _loadingMore
                      ? const CircularProgressIndicator()
                      : OutlinedButton(
                          onPressed: _loadMore,
                          child: const Text('Afficher plus'),
                        ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsSection extends ConsumerWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(adminStatsProvider)
        .when(
          loading: () =>
              const Padding(padding: EdgeInsets.all(24), child: PageLoading()),
          error: (error, _) => _ErrorBlock(
            message: error is ApiException
                ? error.message
                : 'Statistiques indisponibles.',
            onRetry: () => ref.invalidate(adminStatsProvider),
          ),
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(title: 'Vue d’ensemble'),
              _FigureRow(
                figures: [
                  _Figure(
                    Icons.groups_outlined,
                    PillTone.basil,
                    stats.members,
                    'Membres',
                  ),
                  _Figure(
                    Icons.person_add_alt_1_outlined,
                    PillTone.saffron,
                    stats.newMembersLast7Days,
                    'Nouveaux (7 j)',
                  ),
                  _Figure(
                    Icons.block,
                    PillTone.tomato,
                    stats.suspended,
                    'Suspendus',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _FigureRow(
                figures: [
                  _Figure(
                    Icons.handshake_outlined,
                    PillTone.basil,
                    stats.acceptedConnections,
                    'Relations',
                  ),
                  _Figure(
                    Icons.hourglass_empty,
                    PillTone.neutral,
                    stats.pendingConnections,
                    'En attente',
                  ),
                  _Figure(
                    Icons.chat_bubble_outline,
                    PillTone.saffron,
                    stats.messagesLast7Days,
                    'Messages (7 j)',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InfoPanel(
                icon: Icons.privacy_tip_outlined,
                text:
                    '${stats.membersWithProfile} membres sur ${stats.members} '
                    'ont un profil. L’administration ne donne jamais accès au '
                    'contenu des messages.',
              ),
            ],
          ),
        );
  }
}

class _Figure {
  const _Figure(this.icon, this.tone, this.value, this.label);

  final IconData icon;
  final PillTone tone;
  final int value;
  final String label;
}

class _FigureRow extends StatelessWidget {
  const _FigureRow({required this.figures});

  final List<_Figure> figures;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, figure) in figures.indexed) ...[
          if (index > 0) const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              container: true,
              label: '${figure.value} ${figure.label}',
              excludeSemantics: true,
              child: SurfaceCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconTile(figure.icon, tone: figure.tone, size: 36),
                    const SizedBox(height: 12),
                    Text(
                      '${figure.value}',
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(figure.label, style: theme.textTheme.labelMedium),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    super.key,
    required this.canModerate,
    required this.onToggle,
  });

  final AdminAccount account;
  final bool canModerate;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final created = account.createdAt.toLocal();
    final date =
        '${created.day.toString().padLeft(2, '0')}/'
        '${created.month.toString().padLeft(2, '0')}/${created.year}';
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  account.name ?? 'Profil non créé',
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (account.isAdmin)
                const StatusPill('Admin', tone: PillTone.saffron)
              else if (account.isSuspended)
                const StatusPill('Suspendu', tone: PillTone.tomato)
              else
                const StatusPill('Actif'),
            ],
          ),
          const SizedBox(height: 4),
          Text(account.email, style: theme.textTheme.bodyMedium),
          Text('Inscrit le $date', style: theme.textTheme.labelMedium),
          if (canModerate) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: account.isSuspended
                  ? FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: RisottoColors.basil,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onToggle,
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Réactiver'),
                    )
                  : OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RisottoColors.tomatoDeep,
                        side: const BorderSide(color: RisottoColors.tomatoDeep),
                      ),
                      onPressed: onToggle,
                      icon: const Icon(Icons.block),
                      label: const Text('Suspendre'),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
