import 'package:flutter/material.dart';

/// Risotto brand palette (design/risotto/DESIGN.md). Widgets never hard-code colors:
/// use the theme or these constants.
abstract final class RisottoColors {
  /// Primary. Always paired with [charcoal] text (never white).
  static const saffron = Color(0xFFE8A317);

  /// Light saffron fill (icon tiles, highlights).
  static const saffronSoft = Color(0xFFFFE6B3);

  /// Canvas (screen background).
  static const cream = Color(0xFFFFF6E0);

  /// Secondary: growth, trust, confirmations, links.
  static const basil = Color(0xFF2F6B4F);

  /// Light basil fill (status badges, secondary tonal buttons).
  static const basilSoft = Color(0xFFD3EEDD);

  /// Text and icons.
  static const charcoal = Color(0xFF1F2421);

  /// Secondary text (meets 4.5:1 on white and cream).
  static const charcoalSoft = Color(0xFF5B6460);

  /// Alerts (icons, borders, fills).
  static const tomato = Color(0xFFD6452F);

  /// Darker tomato for small error text and filled error buttons: [tomato] only reaches
  /// 4.1:1 on [cream], below the WCAG AA 4.5:1 required for body text.
  static const tomatoDeep = Color(0xFFB23A26);

  /// Cards, inputs, bottom bar: white layered over the cream canvas.
  static const white = Color(0xFFFFFFFF);

  /// Slightly darker cream for neutral fills (ghost buttons, info panels).
  static const creamDark = Color(0xFFF7E9C6);

  /// Input borders.
  static const inputBorder = Color(0xFFE6DECA);

  /// Card and chip outlines, dividers.
  static const outline = Color(0xFFE5DAC1);
}
