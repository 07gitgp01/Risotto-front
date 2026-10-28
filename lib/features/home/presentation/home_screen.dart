import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_health_repository.dart';
import '../../auth/application/auth_controller.dart';

/// Temporary home (milestone 2): greets the user, shows the API status, signs out.
/// Replaced by the dashboard in milestone 8.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final health = ref.watch(apiHealthProvider);
    final email = auth is Authenticated ? auth.user.email : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risotto'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
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
                    'Bienvenue',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  email,
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
