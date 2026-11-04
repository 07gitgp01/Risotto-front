import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/risotto_colors.dart';
import '../../../core/widgets/risotto_ui.dart';
import '../application/app_lock.dart';
import '../application/auth_controller.dart';

/// Covers the signed-in app until the fingerprint (or device PIN) is given.
/// Shown above the router by app.dart, so it has no Scaffold of its own.
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // The system prompt opens by itself; the button is there to retry.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    final ok = await ref.read(appLockProvider.notifier).unlock();
    if (mounted && !ok) {
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RisottoLogo(size: 72),
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  child: Text(
                    'Risotto est verrouillé',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _failed
                      ? 'Empreinte non reconnue. Réessayez.'
                      : 'Utilisez votre empreinte pour continuer.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Déverrouiller'),
                  onPressed: _unlock,
                ),
                const SizedBox(height: 12),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: RisottoColors.basil,
                  ),
                  onPressed: () => unawaited(
                    ref.read(authControllerProvider.notifier).logout(),
                  ),
                  child: const Text('Utiliser mon mot de passe'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Neutral cover while the lock setting is being read (avoids a flash of content).
class AppLockCover extends StatelessWidget {
  const AppLockCover({super.key});

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: const Center(child: RisottoLogo(size: 72)),
  );
}
