import 'package:flutter/material.dart';

import '../../../../core/theme/risotto_colors.dart';
import '../../../../core/widgets/risotto_ui.dart';

/// Common layout of the auth screens (design: connexion / inscription): logo,
/// centred title and subtitle, the form in a white card on the cream canvas.
class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    required this.title,
    required this.child,
    this.subtitle,
    this.appBarTitle,
    this.showBackButton = false,
    this.onBack,
    this.header,
    this.footer,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// Short screen name next to the logo (e.g. "Connexion").
  final String? appBarTitle;
  final bool showBackButton;

  /// Back arrow for screens reached with `go` (nothing to pop).
  final VoidCallback? onBack;

  /// Above the card (e.g. the registration step).
  final Widget? header;

  /// Below the card (e.g. "Créer un compte" link).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBackButton,
        leading: onBack == null
            ? null
            : IconButton(
                tooltip: 'Retour',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
        title: Row(
          children: [
            const RisottoLogo(size: 28),
            if (appBarTitle != null) ...[
              const SizedBox(width: 12),
              Flexible(child: Text(appBarTitle!)),
            ],
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (header != null) ...[header!, const SizedBox(height: 16)],
                  SurfaceCard(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: _LogoBadge()),
                        const SizedBox(height: 16),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        child,
                      ],
                    ),
                  ),
                  if (footer != null) ...[const SizedBox(height: 16), footer!],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Réseau professionnel sécurisé',
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                    ],
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

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) => Container(
    width: 72,
    height: 72,
    decoration: const BoxDecoration(
      color: RisottoColors.cream,
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: const RisottoLogo(size: 44),
  );
}

/// Error message shown above the submit button, announced by screen readers.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary button that shows a spinner and ignores taps while [loading].
class SubmitButton extends StatelessWidget {
  const SubmitButton({
    required this.label,
    required this.onPressed,
    required this.loading,
    this.icon = Icons.arrow_forward,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;

  /// Shown after the label.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
                semanticsLabel: 'Chargement',
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(label)),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 20),
                ],
              ],
            ),
    );
  }
}
