import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/risotto_colors.dart';
import '../../../core/theme/risotto_theme.dart';
import '../../../core/widgets/risotto_ui.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';
import '../application/messaging_providers.dart';
import '../data/messaging_models.dart';
import 'time_format.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.conversationId, super.key});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// The list is reversed: the "top" (older messages) is the max extent.
  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      ref
          .read(chatProvider(widget.conversationId).notifier)
          .loadMore()
          .ignore();
    }
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty || _sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(chatProvider(widget.conversationId).notifier).send(body);
      _input.clear();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.statusCode == 403
                  ? 'Vous n’êtes plus en relation : impossible d’envoyer un message.'
                  : 'Message non envoyé. ${error.message}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider(widget.conversationId));
    final auth = ref.watch(authControllerProvider);
    final myId = auth is Authenticated ? auth.user.id : '';

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Conversation')),
      body: chat.when(
        loading: () => const PageLoading(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error is ApiException && error.statusCode == 404
                  ? 'Cette conversation n’est plus disponible.'
                  : error is ApiException
                  ? error.message
                  : 'Impossible de charger la conversation.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (state) {
          // My most recent message, for the "read" receipt.
          final lastMine = state.messages
              .where((m) => m.senderId == myId)
              .firstOrNull;
          final readByOther =
              lastMine != null &&
              state.otherLastReadAt != null &&
              !state.otherLastReadAt!.isBefore(lastMine.createdAt);

          final user = state.conversation.user;
          return Column(
            children: [
              // Who I am talking to (design: chat header card).
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: SurfaceCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  onTap: () => context.push(AppRoutes.userProfile(user.userId)),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ProfileAvatar(
                      initials: user.initials,
                      photoUrl: user.photoUrl,
                      name: user.fullName,
                      radius: 24,
                    ),
                    title: Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: _subtitle(user) == null
                        ? null
                        : Text(
                            _subtitle(user)!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
              // Honest wording: encrypted at rest, not end to end.
              const StatusPill(
                'Messages chiffrés sur nos serveurs',
                tone: PillTone.neutral,
                icon: Icons.lock_outline,
              ),
              Expanded(
                child: state.messages.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Démarrez la conversation.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount:
                            state.messages.length + (state.loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.messages.length) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: PageLoading(),
                            );
                          }
                          // Reversed list: index - 1 is newer, index + 1 older.
                          final messages = state.messages;
                          final message = messages[index];
                          final newer = index > 0 ? messages[index - 1] : null;
                          final older = index + 1 < messages.length
                              ? messages[index + 1]
                              : null;
                          final mine = message.senderId == myId;
                          final bubble = _Bubble(
                            message: message,
                            mine: mine,
                            // Avatar on the last message of a run only.
                            avatar:
                                mine ||
                                    (newer != null &&
                                        newer.senderId == message.senderId)
                                ? null
                                : ProfileAvatar(
                                    initials: user.initials,
                                    photoUrl: user.photoUrl,
                                    name: user.fullName,
                                    radius: 16,
                                  ),
                            receipt: message == lastMine
                                ? (readByOther ? 'Lu' : 'Envoyé')
                                : null,
                          );
                          if (older != null &&
                              _sameDay(older.createdAt, message.createdAt)) {
                            return bubble;
                          }
                          return Column(
                            children: [
                              _DaySeparator(message.createdAt),
                              bubble,
                            ],
                          );
                        },
                      ),
              ),
              if (state.conversation.canSend)
                _Composer(controller: _input, sending: _sending, onSend: _send)
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: const SafeArea(
                    top: false,
                    child: Text(
                      'Vous n’êtes plus en relation : la conversation est en lecture seule.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String? _subtitle(Profile user) {
  final parts = [user.position ?? user.headline, user.location].nonNulls;
  return parts.isEmpty ? null : parts.join(' • ');
}

bool _sameDay(DateTime a, DateTime b) {
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

/// Day pill between messages of different days.
class _DaySeparator extends StatelessWidget {
  const _DaySeparator(this.day);

  final DateTime day;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Center(
      child: StatusPill(dayLabel(day), tone: PillTone.neutral, uppercase: true),
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    this.avatar,
    this.receipt,
  });

  final ChatMessage message;
  final bool mine;

  /// The sender's avatar, beside the last message of a run.
  final Widget? avatar;
  final String? receipt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Design: mine in saffron with charcoal text, theirs on white cards.
    final background = mine ? RisottoColors.saffron : RisottoColors.white;
    const foreground = RisottoColors.charcoal;
    // One coherent sentence for screen readers instead of separate fragments.
    final spoken = [
      mine ? 'Vous' : 'Message reçu',
      message.body,
      clockTime(message.createdAt),
      ?receipt,
    ].join(', ');
    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: _bubbleLayout(context, background, foreground, textTheme),
    );
  }

  Widget _bubbleLayout(
    BuildContext context,
    Color background,
    Color foreground,
    TextTheme textTheme,
  ) {
    final time = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          clockTime(message.createdAt),
          style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (receipt != null) ...[
          const SizedBox(width: 4),
          Icon(
            receipt == 'Lu' ? Icons.done_all : Icons.done,
            size: 14,
            color: RisottoColors.basil,
          ),
          const SizedBox(width: 2),
          Text(receipt!, style: textTheme.labelSmall),
        ],
      ],
    );
    final column = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.74,
      ),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(20),
              boxShadow: mine ? null : risottoCardShadow,
            ),
            child: SelectableText(
              message.body,
              style: textTheme.bodyLarge?.copyWith(color: foreground),
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(4, 4, 4, 0), child: time),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SizedBox(width: 32, child: avatar),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: column),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                maxLength: 4000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Votre message…',
                  counterText: '',
                  filled: true,
                  fillColor: RisottoColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Envoyer',
              onPressed: sending ? null : onSend,
              style: IconButton.styleFrom(
                minimumSize: const Size(52, 52),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
