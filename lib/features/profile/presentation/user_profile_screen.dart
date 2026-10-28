import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../connections/application/connections_providers.dart';
import '../../connections/presentation/widgets/connection_button.dart';
import '../application/my_profile_controller.dart';
import '../data/profile_models.dart';
import 'widgets/profile_details.dart';

/// Another member's profile, as much as their visibility allows.
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({required this.userId, super.key});

  final String userId;

  Future<void> _block(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bloquer ${profile.fullName} ?'),
        content: const Text(
          'Vous ne verrez plus son profil et il ne verra plus le vôtre. '
          'Votre relation et les demandes en cours seront supprimées. '
          'Ce membre n’est pas prévenu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bloquer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(connectionActionsProvider).block(profile.userId);
      messenger.showSnackBar(
        SnackBar(content: Text('${profile.fullName} est bloqué.')),
      );
      if (context.mounted) {
        context.pop();
      }
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileByIdProvider(userId));
    final loaded = profile.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (loaded != null && !loaded.isOwn)
            PopupMenuButton<String>(
              tooltip: 'Plus d’options',
              onSelected: (_) => _block(context, ref, loaded),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'block', child: Text('Bloquer')),
              ],
            ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error is ApiException && error.statusCode == 404
                  ? 'Ce profil n’est pas disponible.'
                  : error is ApiException
                  ? error.message
                  : 'Impossible de charger le profil.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ProfileDetails(profile: profile),
            if (profile.connection != null) ...[
              const SizedBox(height: 24),
              Center(
                child: ConnectionButton(
                  userId: profile.userId,
                  name: profile.firstName,
                  state: profile.connection!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
