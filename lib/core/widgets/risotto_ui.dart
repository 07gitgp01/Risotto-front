import 'package:flutter/material.dart';

import '../theme/risotto_colors.dart';
import '../theme/risotto_theme.dart';
import 'risotto_loader.dart';

/// Shared building blocks of the design system (design/risotto/DESIGN.md).

/// Logo mark of the brand kit (two circles meeting).
class RisottoLogo extends StatelessWidget {
  const RisottoLogo({this.size = 32, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/brand/png/logo-mark-512.png',
    width: size,
    height: size,
    semanticLabel: 'Risotto',
  );
}

/// White level-1 surface: 16 px radius, ambient shadow, 16 px padding.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = RisottoColors.white,
    this.gradient,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(16));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: radius,
        boxShadow: risottoCardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Section title with an optional action on the right ("Voir tout").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    this.trailing,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ?trailing,
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

enum PillTone { basil, saffron, tomato, neutral }

/// Small status badge (label-sm, soft background).
class StatusPill extends StatelessWidget {
  const StatusPill(
    this.label, {
    this.tone = PillTone.basil,
    this.icon,
    this.uppercase = false,
    super.key,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;

  /// Reserved to short metadata tags (design system rule).
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      PillTone.basil => (RisottoColors.basilSoft, RisottoColors.basil),
      PillTone.saffron => (RisottoColors.saffronSoft, RisottoColors.charcoal),
      PillTone.tomato => (const Color(0xFFF9DCD6), RisottoColors.tomatoDeep),
      PillTone.neutral => (RisottoColors.creamDark, RisottoColors.charcoal),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              uppercase ? label.toUpperCase() : label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded square with an icon, on a soft brand color.
class IconTile extends StatelessWidget {
  const IconTile(
    this.icon, {
    this.tone = PillTone.saffron,
    this.size = 48,
    super.key,
  });

  final IconData icon;
  final PillTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      PillTone.basil => (RisottoColors.basilSoft, RisottoColors.basil),
      PillTone.saffron => (RisottoColors.saffronSoft, RisottoColors.charcoal),
      PillTone.tomato => (const Color(0xFFF9DCD6), RisottoColors.tomatoDeep),
      PillTone.neutral => (RisottoColors.creamDark, RisottoColors.charcoal),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: foreground, size: size * 0.5),
    );
  }
}

/// Soft informative panel (tips, privacy notes).
class InfoPanel extends StatelessWidget {
  const InfoPanel({
    required this.icon,
    required this.text,
    this.tone = PillTone.basil,
    super.key,
  });

  final IconData icon;
  final String text;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RisottoColors.creamDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon, tone: tone, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Basil "tip of the day" card.
class TipCard extends StatelessWidget {
  const TipCard({required this.title, required this.text, super.key});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RisottoColors.basil,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: RisottoColors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: RisottoColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: RisottoColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered loading state of a screen.
class PageLoading extends StatelessWidget {
  const PageLoading({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: RisottoLoader(size: 56));
}
