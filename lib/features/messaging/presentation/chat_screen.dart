import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/application/auth_controller.dart';
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
      appBar: AppBar(
        title: Text(chat.value?.conversation.user.fullName ?? 'Conversation'),
      ),
      body: chat.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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

          return Column(
            children: [
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
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final message = state.messages[index];
                          return _Bubble(
                            message: message,
                            mine: message.senderId == myId,
                            receipt: message == lastMine
                                ? (readByOther ? 'Lu' : 'Envoyé')
                                : null,
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine, this.receipt});

  final ChatMessage message;
  final bool mine;
  final String? receipt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Mine: basil with white text; theirs: light card with charcoal text.
    final background = mine ? colors.secondary : colors.surfaceContainerLowest;
    final foreground = mine ? colors.onSecondary : colors.onSurface;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(mine ? 18 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SelectableText(
                    message.body,
                    style: textTheme.bodyLarge?.copyWith(color: foreground),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shortTime(message.createdAt),
                    style: textTheme.labelSmall?.copyWith(color: foreground),
                  ),
                ],
              ),
            ),
            if (receipt != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(receipt!, style: textTheme.labelSmall),
              ),
          ],
        ),
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
                decoration: const InputDecoration(
                  hintText: 'Votre message',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filled(
              tooltip: 'Envoyer',
              onPressed: sending ? null : onSend,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
