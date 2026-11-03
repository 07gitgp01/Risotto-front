import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../application/connections_providers.dart';
import '../../../core/widgets/risotto_ui.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Membres bloqués')),
      body: blocked.when(
        loading: () => const PageLoading(),
        error: (error, _) => Center(
          child: Text(
            error is ApiException ? error.message : 'Liste indisponible.',
          ),
        ),
        data: (users) => users.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Vous n’avez bloqué personne.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: users.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return SurfaceCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const IconTile(
                        Icons.block,
                        tone: PillTone.tomato,
                        size: 40,
                      ),
                      title: Text(user.displayName),
                      trailing: TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ref
                                .read(connectionActionsProvider)
                                .unblock(user.userId);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('${user.displayName} débloqué.'),
                              ),
                            );
                          } on ApiException catch (error) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                          }
                        },
                        child: const Text('Débloquer'),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
