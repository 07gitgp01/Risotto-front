import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/risotto_colors.dart';
import '../../../core/widgets/risotto_ui.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';
import '../../shell/main_app_bar.dart';
import '../application/messaging_providers.dart';
import '../data/messaging_models.dart';
import 'time_format.dart';

/// Messages tab (design: messages): filters and conversation cards.
class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  bool _unreadOnly = false;

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
          final shown = _unreadOnly
              ? all.where((c) => c.unreadCount > 0).toList()
              : all;
          return RefreshIndicator(
            onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                if (all.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text('Toutes (${all.length})'),
                        selected: !_unreadOnly,
                        onSelected: (_) => setState(() => _unreadOnly = false),
                      ),
                      ChoiceChip(
                        label: Text('Non lues ($unreadCount)'),
                        selected: _unreadOnly,
                        onSelected: (_) => setState(() => _unreadOnly = true),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                if (all.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      'Aucune conversation.\nOuvrez le profil d’une de vos relations pour lui écrire.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (shown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Aucun message non lu.',
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
    final preview = last == null
        ? 'Nouvelle conversation'
        : '${last.senderId == myId ? 'Vous : ' : ''}${last.body}';

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
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                child: Row(
                  children: [
                    ProfileAvatar(
                      initials: user.initials,
                      photoUrl: user.photoUrl,
                      name: user.fullName,
                      radius: 26,
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
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: unread > 0
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                shortTime(conversation.updatedAt),
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  preview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              if (unread > 0) ...[
                                const SizedBox(width: 8),
                                Badge(
                                  label: Text('$unread'),
                                  backgroundColor: RisottoColors.saffron,
                                  textColor: RisottoColors.charcoal,
                                ),
                              ],
                            ],
                          ),
                          if (user.position != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              user.position!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
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
