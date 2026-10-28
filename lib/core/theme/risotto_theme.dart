import 'package:flutter/material.dart';

import 'risotto_colors.dart';

/// Builds the Risotto Material 3 theme (light only for now).
ThemeData buildRisottoTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: RisottoColors.saffron,
    onPrimary: RisottoColors.charcoal,
    primaryContainer: RisottoColors.creamDark,
    onPrimaryContainer: RisottoColors.charcoal,
    secondary: RisottoColors.basil,
    onSecondary: RisottoColors.white,
    secondaryContainer: Color(0xFFD5E6DC),
    onSecondaryContainer: RisottoColors.charcoal,
    error: RisottoColors.tomatoDeep,
    onError: RisottoColors.white,
    errorContainer: Color(0xFFF9DCD6),
    onErrorContainer: RisottoColors.charcoal,
    surface: RisottoColors.cream,
    onSurface: RisottoColors.charcoal,
    surfaceContainerLowest: RisottoColors.white,
    surfaceContainerLow: Color(0xFFFFF9EC),
    surfaceContainer: RisottoColors.creamDark,
    surfaceContainerHigh: RisottoColors.creamDark,
    surfaceContainerHighest: Color(0xFFF0DFB4),
    onSurfaceVariant: Color(0xFF4A4F4B),
    outline: Color(0xFF7A7F7B),
    outlineVariant: Color(0xFFD9CBA6),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: RisottoColors.cream,
  );

  const buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  // 48 dp minimum touch target.
  const buttonMinSize = Size(64, 48);

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: RisottoColors.charcoal,
      displayColor: RisottoColors.charcoal,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: RisottoColors.cream,
      foregroundColor: RisottoColors.charcoal,
      elevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: RisottoColors.saffron,
        foregroundColor: RisottoColors.charcoal,
        minimumSize: buttonMinSize,
        shape: buttonShape,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: RisottoColors.saffron,
        foregroundColor: RisottoColors.charcoal,
        minimumSize: buttonMinSize,
        shape: buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: RisottoColors.basil,
        side: const BorderSide(color: RisottoColors.basil),
        minimumSize: buttonMinSize,
        shape: buttonShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: RisottoColors.basil,
        minimumSize: buttonMinSize,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: RisottoColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: RisottoColors.basil, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: RisottoColors.tomato),
      ),
      errorStyle: TextStyle(color: RisottoColors.tomatoDeep),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: RisottoColors.charcoal,
      contentTextStyle: TextStyle(color: RisottoColors.cream),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: RisottoColors.basil,
    ),
  );
}
