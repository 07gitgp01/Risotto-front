import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../auth/application/auth_controller.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';
import '../application/messaging_providers.dart';
import 'time_format.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    final auth = ref.watch(authControllerProvider);
    final myId = auth is Authenticated ? auth.user.id : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: conversations.when(
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
        data: (conversations) => conversations.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Aucune conversation.\nOuvrez le profil d’une de vos relations pour lui écrire.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(conversationsProvider.notifier).refresh(),
                child: ListView.separated(
                  itemCount: conversations.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final user = conversation.user;
                    final last = conversation.lastMessage;
                    final unread = conversation.unreadCount;
                    final theme = Theme.of(context);
                    final preview = last == null
                        ? 'Nouvelle conversation'
                        : '${last.senderId == myId ? 'Vous : ' : ''}${last.body}';
                    return ListTile(
                      leading: ProfileAvatar(
                        initials: user.initials,
                        photoUrl: user.photoUrl,
                        name: user.fullName,
                        radius: 22,
                      ),
                      title: Text(
                        user.fullName,
                        style: unread > 0
                            ? const TextStyle(fontWeight: FontWeight.w700)
                            : null,
                      ),
                      subtitle: Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            shortTime(conversation.updatedAt),
                            style: theme.textTheme.bodySmall,
                          ),
                          if (unread > 0) ...[
                            const SizedBox(height: 4),
                            Badge(
                              label: Text('$unread'),
                              backgroundColor: theme.colorScheme.error,
                              textColor: theme.colorScheme.onError,
                            ),
                          ],
                        ],
                      ),
                      onTap: () =>
                          context.push(AppRoutes.chat(conversation.id)),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
