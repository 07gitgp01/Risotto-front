import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/risotto_colors.dart';
import '../../../core/widgets/risotto_ui.dart';

/// First screen when signed out (design: bienvenue_onboarding).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const RisottoLogo(size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Risotto',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      const StatusPill(
                        'Réseautage pro',
                        icon: Icons.circle,
                        uppercase: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SurfaceCard(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        _ScanIllustration(),
                        SizedBox(height: 16),
                        StatusPill(
                          'Sans contact',
                          tone: PillTone.saffron,
                          icon: Icons.qr_code_2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Semantics(
                    header: true,
                    child: Text(
                      'Partagez vos contacts d’un scan',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Échangez vos cartes de visite numériques en un instant lors de '
                    'vos événements et rencontres, grâce à votre QR code personnel.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.register),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Commencer'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('J’ai déjà un compte'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Phone showing a QR code, drawn with brand colors (no image asset needed).
class _ScanIllustration extends StatelessWidget {
  const _ScanIllustration();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 140,
        height: 140,
        decoration: const BoxDecoration(
          color: RisottoColors.cream,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 68,
          height: 104,
          decoration: BoxDecoration(
            color: RisottoColors.white,
            border: Border.all(color: RisottoColors.charcoal, width: 5),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.qr_code_2,
            size: 40,
            color: RisottoColors.basil,
          ),
        ),
      ),
    );
  }
}
