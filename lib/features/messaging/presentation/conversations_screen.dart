import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/risotto_colors.dart';
import '../../../core/widgets/risotto_ui.dart';
import '../../auth/application/auth_controller.dart';
import '../../connections/application/connections_providers.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';
import '../../shell/main_app_bar.dart';
import '../application/messaging_providers.dart';
import '../application/open_chat.dart';
import '../data/messaging_models.dart';
import 'time_format.dart';

/// Messages tab (design: messages): search, quick access to my connections,
/// filters and conversation cards. The mockup's "online" row becomes my
/// connections (the app has no presence) and its "end-to-end" claim is not
/// repeated.
class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  bool _unreadOnly = false;
  String _query = '';

  bool _matches(Conversation conversation) {
    if (_query.isEmpty) {
      return true;
    }
    final haystack = [
      conversation.user.fullName,
      conversation.user.position ?? '',
      conversation.lastMessage?.body ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(_query.toLowerCase());
  }

  /// Picks one of my connections to write to (messaging is reserved to them).
  Future<void> _compose() async {
    final userId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _ComposeSheet(),
    );
    if (userId != null && mounted) {
      await openChatWith(context, ref, userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);
    final auth = ref.watch(authControllerProvider);
    final myId = auth is Authenticated ? auth.user.id : null;

    return Scaffold(
      appBar: const MainAppBar(title: 'Messages'),
      body: conversations.when(
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
                      : 'Impossible de charger les messages.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(conversationsProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (all) {
          final unreadCount = all.where((c) => c.unreadCount > 0).length;
          final shown = all
              .where((c) => !_unreadOnly || c.unreadCount > 0)
              .where(_matches)
              .toList();
          return RefreshIndicator(
            onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) =>
                            setState(() => _query = value.trim()),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher une conversation',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      tooltip: 'Nouveau message',
                      style: IconButton.styleFrom(
                        backgroundColor: RisottoColors.saffron,
                        foregroundColor: RisottoColors.charcoal,
                        minimumSize: const Size(56, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _compose,
                      icon: const Icon(Icons.edit_square),
                    ),
                  ],
                ),
                const _QuickContacts(),
                const SizedBox(height: 16),
                if (all.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: [
                      _CountChip(
                        label: 'Toutes',
                        count: all.length,
                        selected: !_unreadOnly,
                        onSelected: () => setState(() => _unreadOnly = false),
                      ),
                      _CountChip(
                        label: 'Non lues',
                        count: unreadCount,
                        selected: _unreadOnly,
                        onSelected: () => setState(() => _unreadOnly = true),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                if (all.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      'Aucune conversation.\nÉcrivez à l’une de vos relations pour commencer.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      _query.isNotEmpty
                          ? 'Aucune conversation ne correspond.'
                          : 'Aucun message non lu.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final conversation in shown) ...[
                  _ConversationCard(conversation: conversation, myId: myId),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
                const InfoPanel(
                  icon: Icons.lock_outline,
                  text:
                      'Vos messages sont chiffrés pendant le transfert et sur nos serveurs. '
                      'Ce n’est pas un chiffrement de bout en bout.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Choice chip with its count in a small round badge (design).
class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label ($count)',
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: ChoiceChip(
        showCheckmark: false,
        selected: selected,
        onSelected: (_) => onSelected(),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? RisottoColors.white.withValues(alpha: 0.25)
                    : RisottoColors.saffron,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? RisottoColors.white
                      : RisottoColors.charcoal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// My connections as round avatars: one tap opens the conversation.
class _QuickContacts extends ConsumerWidget {
  const _QuickContacts();

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
          title: 'Écrire à une relation',
          trailing: StatusPill(
            connections.length == 1
                ? '1 relation'
                : '${connections.length} relations',
          ),
        ),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: connections.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final user = connections[index].user;
              return Semantics(
                button: true,
                label: 'Écrire à ${user.fullName}',
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => openChatWith(context, ref, user.userId),
                  child: SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: RisottoColors.basilSoft,
                          ),
                          child: ProfileAvatar(
                            initials: user.initials,
                            photoUrl: user.photoUrl,
                            name: user.fullName,
                            radius: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.firstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
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

class _ComposeSheet extends ConsumerWidget {
  const _ComposeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connections = ref.watch(myConnectionsProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Nouveau message',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Flexible(
              child: connections.when(
                loading: () => const PageLoading(),
                error: (_, _) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Impossible de charger vos relations.'),
                ),
                data: (list) => list.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'La messagerie est réservée à vos relations. '
                          'Connectez-vous d’abord à un membre.',
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final connection in list)
                            ListTile(
                              leading: ProfileAvatar(
                                initials: connection.user.initials,
                                photoUrl: connection.user.photoUrl,
                                name: connection.user.fullName,
                                radius: 22,
                              ),
                              title: Text(connection.user.fullName),
                              subtitle: connection.user.position == null
                                  ? null
                                  : Text(connection.user.position!),
                              onTap: () => Navigator.of(
                                context,
                              ).pop(connection.user.userId),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.conversation, required this.myId});

  final Conversation conversation;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = conversation.user;
    final last = conversation.lastMessage;
    final unread = conversation.unreadCount;
    final mine = last != null && last.senderId == myId;
    final readAt = conversation.otherLastReadAt;
    final readByOther =
        mine && readAt != null && !readAt.isBefore(last.createdAt);
    final preview = last == null
        ? 'Nouvelle conversation'
        : '${mine ? 'Vous : ' : ''}${last.body}';

    return SurfaceCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push(AppRoutes.chat(conversation.id)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Saffron edge on unread conversations.
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: unread > 0 ? RisottoColors.saffron : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
                child: Row(
                  children: [
                    ProfileAvatar(
                      initials: user.initials,
                      photoUrl: user.photoUrl,
                      name: user.fullName,
                      radius: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: unread > 0
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                shortTime(conversation.updatedAt),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: unread > 0
                                      ? FontWeight.w700
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: unread > 0 ? RisottoColors.charcoal : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (user.position != null) ...[
                                const Icon(
                                  Icons.work_outline,
                                  size: 14,
                                  color: RisottoColors.basil,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  user.position ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium,
                                ),
                              ),
                              if (unread > 0)
                                Badge(
                                  label: Text('$unread'),
                                  backgroundColor: RisottoColors.saffron,
                                  textColor: RisottoColors.charcoal,
                                )
                              else if (mine)
                                Icon(
                                  readByOther ? Icons.done_all : Icons.done,
                                  size: 18,
                                  color: RisottoColors.basil,
                                  semanticLabel: readByOther ? 'Lu' : 'Envoyé',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
