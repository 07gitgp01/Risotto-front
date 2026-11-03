import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../application/notifications_providers.dart';
import '../application/push_service.dart';
import '../data/notifications_models.dart';
import 'widgets/actor_avatar.dart';
import '../../../core/widgets/risotto_ui.dart';

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
        loading: () => const PageLoading(),
        error: (error, _) => Center(
          child: Text(
            error is ApiException
                ? error.message
                : 'Préférences indisponibles.',
          ),
        ),
        data: (preferences) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (!fcmEnabled) ...[
              const InfoPanel(
                icon: Icons.info_outline,
                text:
                    'Les notifications push ne sont pas activées dans cette version de l’application : '
                    'vos choix seront appliqués dès qu’elles le seront.',
              ),
              const SizedBox(height: 16),
            ],
            for (final preference in preferences) ...[
              SurfaceCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconTile(
                          notificationIcon(preference.kind),
                          tone: PillTone.basil,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              preference.kind.label,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (preference.supportsInApp)
                      SwitchListTile(
                        contentPadding: const EdgeInsets.only(left: 52),
                        title: const Text('Dans l’application'),
                        value: preference.inApp,
                        onChanged: (value) => _change(
                          context,
                          ref,
                          preference.copyWith(inApp: value),
                        ),
                      ),
                    SwitchListTile(
                      contentPadding: const EdgeInsets.only(left: 52),
                      title: const Text('Notification push'),
                      subtitle: preference.kind == NotificationKind.message
                          ? const Text(
                              'Le contenu du message n’est jamais affiché dans la notification.',
                            )
                          : null,
                      value: preference.push,
                      onChanged: (value) => _change(
                        context,
                        ref,
                        preference.copyWith(push: value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
