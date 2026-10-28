import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../application/notifications_providers.dart';
import '../application/push_service.dart';
import '../data/notifications_models.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _change(
    BuildContext context,
    WidgetRef ref,
    NotificationPreference updated,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(notificationPreferencesProvider.notifier).change(updated);
    } on ApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Préférence non enregistrée. ${error.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(notificationPreferencesProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Préférences de notification')),
      body: preferences.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            error is ApiException
                ? error.message
                : 'Préférences indisponibles.',
          ),
        ),
        data: (preferences) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (!fcmEnabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'Les notifications push ne sont pas activées dans cette version de l’application : '
                  'vos choix seront appliqués dès qu’elles le seront.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            for (final preference in preferences) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Semantics(
                  header: true,
                  child: Text(
                    preference.kind.label,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              if (preference.supportsInApp)
                SwitchListTile(
                  title: const Text('Dans l’application'),
                  value: preference.inApp,
                  onChanged: (value) =>
                      _change(context, ref, preference.copyWith(inApp: value)),
                ),
              SwitchListTile(
                title: const Text('Notification push'),
                subtitle: preference.kind == NotificationKind.message
                    ? const Text(
                        'Le contenu du message n’est jamais affiché dans la notification.',
                      )
                    : null,
                value: preference.push,
                onChanged: (value) =>
                    _change(context, ref, preference.copyWith(push: value)),
              ),
              const Divider(),
            ],
          ],
        ),
      ),
    );
  }
}
