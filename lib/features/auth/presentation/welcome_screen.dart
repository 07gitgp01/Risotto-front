import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/risotto_colors.dart';
import '../../../core/widgets/risotto_ui.dart';

class _Slide {
  const _Slide({
    required this.icon,
    required this.pill,
    required this.pillIcon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String pill;
  final IconData pillIcon;
  final String title;
  final String text;
}

const _slides = [
  _Slide(
    icon: Icons.qr_code_2,
    pill: 'Sans contact',
    pillIcon: Icons.contactless_outlined,
    title: 'Partagez vos contacts d’un scan',
    text:
        'Échangez vos cartes de visite numériques en un instant lors de '
        'vos événements et rencontres, grâce à votre QR code personnel.',
  ),
  _Slide(
    icon: Icons.diversity_3,
    pill: 'Réseau pro',
    pillIcon: Icons.handshake_outlined,
    title: 'Développez votre réseau',
    text:
        'Envoyez et acceptez des demandes de mise en relation, puis '
        'retrouvez tous vos contacts au même endroit.',
  ),
  _Slide(
    icon: Icons.forum_outlined,
    pill: 'Temps réel',
    pillIcon: Icons.bolt,
    title: 'Échangez avec vos relations',
    text:
        'Une messagerie réservée à vos relations, avec des notifications '
        'dès qu’on vous écrit ou qu’on accepte votre demande.',
  ),
];

/// First screen when signed out (design: bienvenue_onboarding): three slides.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                  const SizedBox(height: 16),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (page) => setState(() => _page = page),
                      children: [
                        for (final slide in _slides) _SlideView(slide: slide),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label: 'Page ${_page + 1} sur ${_slides.length}',
                    excludeSemantics: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _slides.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _page ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page
                                  ? RisottoColors.saffron
                                  : RisottoColors.outline,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: Stack(
                children: [
                  Center(child: _Illustration(icon: slide.icon)),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: StatusPill(
                      slide.pill,
                      tone: PillTone.neutral,
                      icon: slide.pillIcon,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(
              slide.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Phone showing the slide's icon, drawn with brand colors (no image asset).
class _Illustration extends StatelessWidget {
  const _Illustration({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 150,
        height: 150,
        decoration: const BoxDecoration(
          color: RisottoColors.cream,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Container(
          width: 72,
          height: 112,
          decoration: BoxDecoration(
            color: RisottoColors.white,
            border: Border.all(color: RisottoColors.charcoal, width: 5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: RisottoColors.basil),
              const SizedBox(height: 8),
              Container(width: 36, height: 4, color: RisottoColors.basil),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 22, height: 4, color: RisottoColors.outline),
                  const SizedBox(width: 4),
                  const CircleAvatar(
                    radius: 3,
                    backgroundColor: RisottoColors.saffron,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
