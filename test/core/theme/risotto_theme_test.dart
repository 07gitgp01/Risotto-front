import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/core/theme/risotto_colors.dart';
import 'package:risotto/core/theme/risotto_theme.dart';

/// WCAG 2.x contrast ratio.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('RisottoColors', () {
    test('match the brand guidelines', () {
      expect(RisottoColors.saffron, const Color(0xFFE8A317));
      expect(RisottoColors.cream, const Color(0xFFFFF6E0));
      expect(RisottoColors.basil, const Color(0xFF2F6B4F));
      expect(RisottoColors.charcoal, const Color(0xFF1F2421));
      expect(RisottoColors.tomato, const Color(0xFFD6452F));
    });
  });

  group('buildRisottoTheme', () {
    final theme = buildRisottoTheme();
    final scheme = theme.colorScheme;

    test('maps the palette to the color scheme', () {
      expect(theme.useMaterial3, isTrue);
      expect(scheme.primary, RisottoColors.saffron);
      expect(scheme.onPrimary, RisottoColors.charcoal);
      expect(scheme.secondary, RisottoColors.basil);
      expect(scheme.surface, RisottoColors.cream);
      expect(scheme.onSurface, RisottoColors.charcoal);
      expect(theme.scaffoldBackgroundColor, RisottoColors.cream);
    });

    test('saffron buttons use charcoal text, never white', () {
      final style = theme.filledButtonTheme.style!;
      expect(style.backgroundColor!.resolve({}), RisottoColors.saffron);
      expect(style.foregroundColor!.resolve({}), RisottoColors.charcoal);
      expect(
        theme.elevatedButtonTheme.style!.foregroundColor!.resolve({}),
        RisottoColors.charcoal,
      );
    });

    test('buttons keep a 48 dp minimum touch target', () {
      for (final style in [
        theme.filledButtonTheme.style!,
        theme.elevatedButtonTheme.style!,
        theme.outlinedButtonTheme.style!,
        theme.textButtonTheme.style!,
      ]) {
        expect(
          style.minimumSize!.resolve({})!.height,
          greaterThanOrEqualTo(48),
        );
      }
    });

    test('text/background pairs meet WCAG AA (4.5:1)', () {
      final pairs = <String, (Color, Color)>{
        'onPrimary/primary': (scheme.onPrimary, scheme.primary),
        'onSurface/surface': (scheme.onSurface, scheme.surface),
        'onSecondary/secondary': (scheme.onSecondary, scheme.secondary),
        'secondary/surface': (scheme.secondary, scheme.surface),
        'onError/error': (scheme.onError, scheme.error),
        'error/surface': (scheme.error, scheme.surface),
        'onSurfaceVariant/surface': (scheme.onSurfaceVariant, scheme.surface),
      };
      pairs.forEach((name, pair) {
        expect(
          contrast(pair.$1, pair.$2),
          greaterThanOrEqualTo(4.5),
          reason: '$name contrast is too low',
        );
      });
    });

    test('documents why tomato is not used for small text on cream', () {
      expect(
        contrast(RisottoColors.tomato, RisottoColors.cream),
        lessThan(4.5),
      );
      expect(
        contrast(RisottoColors.tomatoDeep, RisottoColors.cream),
        greaterThanOrEqualTo(4.5),
      );
    });
  });
}
