import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Quick reactions offered on a long press.
const quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

/// Same rule as the API: a message can be fixed during its first minutes.
const editWindow = Duration(minutes: 15);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.conversationId, super.key});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _scroll = ScrollController();

  /// The message being answered, shown above the input.
  ChatMessage? _replyTo;

  /// The message being edited (the input holds its text).
  ChatMessage? _editing;

  ChatController get _chat =>
      ref.read(chatProvider(widget.conversationId).notifier);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// The list is reversed: the "top" (older messages) is the max extent.
  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _chat.loadMore().ignore();
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _errorText(ApiException error) => switch (error) {
    ApiException(statusCode: 403) =>
      'Vous n’êtes plus en relation : impossible d’envoyer un message.',
    ApiException(kind: ApiErrorKind.network) =>
      'Pas de réseau : le message partira au retour de la connexion.',
    _ => 'Message non envoyé. ${error.message}',
  };

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty) {
      return;
    }
    final editing = _editing;
    final replyTo = _replyTo;
    // Optimistic: the input is free again at once.
    _input.clear();
    setState(() {
      _editing = null;
      _replyTo = null;
    });
    try {
      if (editing != null) {
        await _chat.edit(editing, body);
      } else {
        await _chat.send(body, replyTo: replyTo);
      }
    } on ApiException catch (error) {
      _showError(
        editing != null && error.statusCode == 403
            ? 'Ce message ne peut plus être modifié.'
            : _errorText(error),
      );
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (error) {
      _showError(error.message);
    }
  }

  void _startReply(ChatMessage message) {
    setState(() {
      _editing = null;
      _replyTo = message;
    });
    _inputFocus.requestFocus();
  }

  void _startEdit(ChatMessage message) {
    setState(() {
      _replyTo = null;
      _editing = message;
    });
    _input
      ..text = message.body
      ..selection = TextSelection.collapsed(offset: message.body.length);
    _inputFocus.requestFocus();
  }

  void _cancelBanner() {
    if (_editing != null) {
      _input.clear();
    }
    setState(() {
      _editing = null;
      _replyTo = null;
    });
  }

  Future<void> _confirmDelete(ChatMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer pour tous ?'),
        content: const Text(
          'Le message sera effacé pour vous et votre interlocuteur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _run(() => _chat.delete(message));
    }
  }

  Future<void> _showActions(
    ChatMessage message, {
    required bool mine,
    required bool canSend,
    required String myId,
  }) async {
    if (message.deleted) {
      return;
    }
    final canEdit =
        mine &&
        canSend &&
        !message.isLocal &&
        DateTime.now().difference(message.createdAt) < editWindow;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!message.isLocal && canSend)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final emoji in quickReactions)
                      _EmojiButton(
                        emoji: emoji,
                        selected: message.reactionOf(myId) == emoji,
                        onTap: () => Navigator.pop(context, 'react:$emoji'),
                      ),
                  ],
                ),
              ),
            if (message.status == SendStatus.failed)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Réessayer'),
                onTap: () => Navigator.pop(context, 'retry'),
              ),
            if (!message.isLocal && canSend)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Répondre'),
                onTap: () => Navigator.pop(context, 'reply'),
              ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copier'),
              onTap: () => Navigator.pop(context, 'copy'),
            ),
            if (canEdit)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Modifier'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
            if (mine)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  message.isLocal ? 'Supprimer' : 'Supprimer pour tous',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) {
      return;
    }
    switch (action) {
      case 'reply':
        _startReply(message);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: message.body));
        _showError('Message copié.');
      case 'edit':
        _startEdit(message);
      case 'delete':
        if (message.isLocal) {
          await _run(() => _chat.delete(message));
        } else {
          await _confirmDelete(message);
        }
      case 'retry':
        await _retry(message);
      default:
        if (action.startsWith('react:')) {
          await _run(() => _chat.react(message, action.substring(6)));
        }
    }
  }

  Future<void> _retry(ChatMessage message) async {
    try {
      await _chat.retry(message);
    } on ApiException catch (error) {
      _showError(_errorText(error));
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
          // My most recent stored message, for the "read" receipt.
          final lastMine = state.messages
              .where((m) => m.senderId == myId && !m.isLocal)
              .firstOrNull;
          final readByOther =
              lastMine != null &&
              state.otherLastReadAt != null &&
              !state.otherLastReadAt!.isBefore(lastMine.createdAt);

          final user = state.conversation.user;
          String nameOf(String senderId) =>
              senderId == myId ? 'Vous' : user.firstName;
          return Column(
            children: [
              _ChatHeader(
                user: user,
                typing: state.otherTyping,
                presence: state.presence,
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
                            myId: myId,
                            replyAuthor: message.replyTo == null
                                ? null
                                : nameOf(message.replyTo!.senderId),
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
                            onLongPress: () => _showActions(
                              message,
                              mine: mine,
                              canSend: state.conversation.canSend,
                              myId: myId,
                            ),
                            onRetry: () => _retry(message),
                            onReaction: state.conversation.canSend
                                ? (emoji) =>
                                      _run(() => _chat.react(message, emoji))
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
              if (state.conversation.canSend) ...[
                if (_replyTo != null || _editing != null)
                  _ComposerBanner(
                    title: _editing != null
                        ? 'Modifier le message'
                        : 'Réponse à ${nameOf(_replyTo!.senderId)}',
                    text: (_editing ?? _replyTo)!.body,
                    icon: _editing != null ? Icons.edit_outlined : Icons.reply,
                    onCancel: _cancelBanner,
                  ),
                _Composer(
                  controller: _input,
                  focusNode: _inputFocus,
                  editing: _editing != null,
                  onChanged: (_) => _chat.notifyTyping(),
                  onSend: _send,
                ),
              ] else
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

/// Who I am talking to: "Écrit…", "En ligne", "Vu à…", else their position.
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.user, required this.typing, this.presence});

  final Profile user;
  final bool typing;
  final Presence? presence;

  @override
  Widget build(BuildContext context) {
    final presence = this.presence;
    final status = typing
        ? 'Écrit…'
        : presence == null
        ? null
        : presence.online
        ? 'En ligne'
        : presence.lastSeenAt == null
        ? null
        : lastSeenLabel(presence.lastSeenAt!);
    final subtitle = status ?? _subtitle(user);
    final live = typing || (presence?.online ?? false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        onTap: () => context.push(AppRoutes.userProfile(user.userId)),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              ProfileAvatar(
                initials: user.initials,
                photoUrl: user.photoUrl,
                name: user.fullName,
                radius: 24,
              ),
              if (presence?.online ?? false)
                const Positioned(right: 0, bottom: 0, child: OnlineDot()),
            ],
          ),
          title: Text(
            user.fullName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: subtitle == null
              ? null
              : Semantics(
                  liveRegion: typing,
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: live
                        ? const TextStyle(
                            color: RisottoColors.basil,
                            fontWeight: FontWeight.w600,
                          )
                        : null,
                  ),
                ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

/// Basil dot on an avatar: the person has the app open.
class OnlineDot extends StatelessWidget {
  const OnlineDot({this.size = 14, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'En ligne',
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: RisottoColors.basil,
        shape: BoxShape.circle,
        border: Border.all(color: RisottoColors.white, width: 2),
      ),
    ),
  );
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
    required this.myId,
    required this.onLongPress,
    required this.onRetry,
    this.onReaction,
    this.replyAuthor,
    this.avatar,
    this.receipt,
  });

  final ChatMessage message;
  final bool mine;
  final String myId;
  final VoidCallback onLongPress;
  final VoidCallback onRetry;

  /// Tapping a reaction toggles mine; null when the conversation is read-only.
  final ValueChanged<String>? onReaction;
  final String? replyAuthor;

  /// The sender's avatar, beside the last message of a run.
  final Widget? avatar;
  final String? receipt;

  bool get _failed => message.status == SendStatus.failed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Design: mine in saffron with charcoal text, theirs on white cards.
    final background = message.deleted
        ? RisottoColors.creamDark
        : mine
        ? RisottoColors.saffron
        : RisottoColors.white;
    // One coherent sentence for screen readers instead of separate fragments.
    final reply = message.replyTo;
    final spoken = [
      mine ? 'Vous' : 'Message reçu',
      if (reply != null)
        'en réponse à $replyAuthor : '
            '${reply.deleted ? 'message supprimé' : reply.body}',
      message.deleted ? 'Message supprimé' : message.body,
      if (message.editedAt != null) 'modifié',
      clockTime(message.createdAt),
      ?receipt,
      if (message.status == SendStatus.sending) 'envoi en cours',
      if (_failed) 'non envoyé, touchez pour réessayer',
      for (final group in _groups) '${group.$1} ${group.$2}',
    ].join(', ');
    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      onLongPressHint: 'Actions sur le message',
      child: GestureDetector(
        onLongPress: onLongPress,
        onTap: _failed ? onRetry : null,
        child: _bubbleLayout(context, background, textTheme),
      ),
    );
  }

  /// Reactions grouped by emoji, in order of first use: (emoji, count).
  List<(String, int)> get _groups {
    final counts = <String, int>{};
    for (final reaction in message.reactions) {
      counts[reaction.emoji] = (counts[reaction.emoji] ?? 0) + 1;
    }
    return [for (final entry in counts.entries) (entry.key, entry.value)];
  }

  Widget _bubbleLayout(
    BuildContext context,
    Color background,
    TextTheme textTheme,
  ) {
    const foreground = RisottoColors.charcoal;
    final error = Theme.of(context).colorScheme.error;
    final status = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.editedAt != null && !message.deleted) ...[
          Text('modifié', style: textTheme.labelSmall),
          const SizedBox(width: 6),
        ],
        Text(
          clockTime(message.createdAt),
          style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (message.status == SendStatus.sending) ...[
          const SizedBox(width: 4),
          const Icon(Icons.schedule, size: 14),
        ] else if (_failed) ...[
          const SizedBox(width: 4),
          Icon(Icons.error_outline, size: 14, color: error),
          const SizedBox(width: 2),
          Text(
            'Non envoyé · Réessayer',
            style: textTheme.labelSmall?.copyWith(
              color: error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else if (receipt != null) ...[
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
    final reply = message.replyTo;
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: mine || message.deleted ? null : risottoCardShadow,
        border: _failed ? Border.all(color: error, width: 1.5) : null,
      ),
      child: message.deleted
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Ce message a été supprimé',
                    style: textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reply != null) ...[
                  _Quote(author: replyAuthor ?? '', preview: reply, mine: mine),
                  const SizedBox(height: 8),
                ],
                Text(
                  message.body,
                  style: textTheme.bodyLarge?.copyWith(color: foreground),
                ),
              ],
            ),
    );
    final groups = _groups;
    final column = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.74,
      ),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          content,
          if (groups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final (emoji, count) in groups)
                    _ReactionChip(
                      emoji: emoji,
                      count: count,
                      mine: message.reactionOf(myId) == emoji,
                      onTap: onReaction == null
                          ? null
                          : () => onReaction!(emoji),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: status,
          ),
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

/// The answered message, inside the reply bubble.
class _Quote extends StatelessWidget {
  const _Quote({
    required this.author,
    required this.preview,
    required this.mine,
  });

  final String author;
  final MessagePreview preview;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: mine
            ? RisottoColors.white.withValues(alpha: 0.55)
            : RisottoColors.cream,
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: RisottoColors.basil, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            author,
            style: textTheme.labelMedium?.copyWith(
              color: RisottoColors.basil,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            preview.deleted ? 'Message supprimé' : preview.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              fontStyle: preview.deleted ? FontStyle.italic : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.mine,
    this.onTap,
  });

  final String emoji;
  final int count;
  final bool mine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: mine ? RisottoColors.basilSoft : RisottoColors.white,
    shape: StadiumBorder(
      side: BorderSide(
        color: mine ? RisottoColors.basil : RisottoColors.creamDark,
      ),
    ),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          count > 1 ? '$emoji $count' : emoji,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    ),
  );
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'Réagir avec $emoji',
    excludeSemantics: true,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? RisottoColors.basilSoft : null,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    ),
  );
}

/// "Réponse à Bob" / "Modifier le message", above the input.
class _ComposerBanner extends StatelessWidget {
  const _ComposerBanner({
    required this.title,
    required this.text,
    required this.icon,
    required this.onCancel,
  });

  final String title;
  final String text;
  final IconData icon;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: RisottoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: RisottoColors.basil, width: 4),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: RisottoColors.basil),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: textTheme.labelLarge?.copyWith(
                    color: RisottoColors.basil,
                  ),
                ),
                Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Annuler',
            icon: const Icon(Icons.close),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.editing,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool editing;
  final ValueChanged<String> onChanged;
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
                focusNode: focusNode,
                onChanged: onChanged,
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
              tooltip: editing ? 'Enregistrer' : 'Envoyer',
              onPressed: onSend,
              style: IconButton.styleFrom(
                minimumSize: const Size(52, 52),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              icon: Icon(editing ? Icons.check : Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
