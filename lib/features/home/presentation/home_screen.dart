import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_health_repository.dart';

/// Temporary landing screen (milestone 1): shows the brand and the API connection status.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final health = ref.watch(apiHealthProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Risotto',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre réseau professionnel, à feu doux.',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                health.when(
                  loading: () => const CircularProgressIndicator(
                    semanticsLabel: 'Connexion au serveur',
                  ),
                  data: (healthy) => _ApiStatus(healthy: healthy),
                  error: (_, _) => const _ApiStatus(healthy: false),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => ref.invalidate(apiHealthProvider),
                  child: const Text('Vérifier la connexion'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ApiStatus extends StatelessWidget {
  const _ApiStatus({required this.healthy});

  final bool healthy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = healthy ? colors.secondary : colors.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(healthy ? Icons.check_circle : Icons.error_outline, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            healthy ? 'Serveur connecté' : 'Serveur injoignable',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
