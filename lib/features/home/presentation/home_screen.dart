import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_health_repository.dart';
import '../../../core/router/app_routes.dart';
import '../../auth/application/auth_controller.dart';
import '../../messaging/application/messaging_providers.dart';
import '../../profile/application/my_profile_controller.dart';
import '../../profile/presentation/widgets/profile_avatar.dart';

/// Temporary home: greets the user, links to the profile, shows the API status.
/// Replaced by the dashboard in milestone 8.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final health = ref.watch(apiHealthProvider);
    final email = auth is Authenticated ? auth.user.email : '';
    final profile = ref.watch(myProfileProvider).value;
    final unreadMessages = ref.watch(unreadMessagesCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risotto'),
        actions: [
          if (profile != null)
            IconButton(
              tooltip: 'Mon profil',
              onPressed: () => context.push(AppRoutes.myProfile),
              icon: ProfileAvatar(
                initials: profile.initials,
                photoUrl: profile.photoUrl,
                name: profile.fullName,
                radius: 16,
              ),
            ),
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
                    profile == null
                        ? 'Bienvenue'
                        : 'Bienvenue, ${profile.firstName}',
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
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _HomeAction(
                      icon: Icons.qr_code_2,
                      label: 'Ma carte',
                      onTap: () => context.push(AppRoutes.myCard),
                    ),
                    _HomeAction(
                      icon: Icons.qr_code_scanner,
                      label: 'Scanner',
                      onTap: () => context.push(AppRoutes.scan),
                    ),
                    _HomeAction(
                      icon: Icons.contacts_outlined,
                      label: 'Contacts',
                      onTap: () => context.push(AppRoutes.contacts),
                    ),
                    _HomeAction(
                      icon: Icons.chat_bubble_outline,
                      label: 'Messages',
                      badge: unreadMessages,
                      onTap: () => context.push(AppRoutes.messages),
                    ),
                    _HomeAction(
                      icon: Icons.group_outlined,
                      label: 'Réseau',
                      onTap: () => context.push(AppRoutes.network),
                    ),
                    _HomeAction(
                      icon: Icons.person_search,
                      label: 'Rechercher',
                      onTap: () => context.push(AppRoutes.search),
                    ),
                  ],
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

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Unread count shown on the icon (hidden when 0).
  final int badge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 104,
      child: Material(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                Badge(
                  isLabelVisible: badge > 0,
                  label: Text('$badge'),
                  backgroundColor: colors.error,
                  textColor: colors.onError,
                  child: Icon(icon, size: 32, color: colors.secondary),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  semanticsLabel: badge > 0 ? '$label, $badge non lus' : label,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
