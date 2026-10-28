import 'package:flutter/material.dart';

/// Risotto brand palette. Widgets never hard-code colors: use the theme or these constants.
abstract final class RisottoColors {
  /// Primary. Always paired with [charcoal] text (never white).
  static const saffron = Color(0xFFE8A317);

  /// Background.
  static const cream = Color(0xFFFFF6E0);

  /// Secondary.
  static const basil = Color(0xFF2F6B4F);

  /// Text.
  static const charcoal = Color(0xFF1F2421);

  /// Alerts (icons, borders, fills).
  static const tomato = Color(0xFFD6452F);

  /// Darker tomato for small error text and filled error buttons: [tomato] only reaches
  /// 4.1:1 on [cream], below the WCAG AA 4.5:1 required for body text.
  static const tomatoDeep = Color(0xFFB23A26);

  static const white = Color(0xFFFFFFFF);

  /// Slightly darker cream for cards and input fills on the cream background.
  static const creamDark = Color(0xFFF7E9C6);
}
