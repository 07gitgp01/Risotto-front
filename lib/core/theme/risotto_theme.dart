import 'package:flutter/material.dart';

import 'risotto_colors.dart';

/// Bundled font (assets/fonts/plus_jakarta_sans, SIL Open Font License).
const risottoFontFamily = 'PlusJakartaSans';

/// Ambient shadow of level-1 surfaces (cards, list tiles) from the design system.
const risottoCardShadow = [
  BoxShadow(
    color: Color(0x0F1F2421),
    blurRadius: 8,
    spreadRadius: -2,
    offset: Offset(0, 2),
  ),
  BoxShadow(color: Color(0x0A1F2421), blurRadius: 3, offset: Offset(0, 1)),
];

/// Builds the Risotto Material 3 theme (light only, see design/risotto/DESIGN.md).
ThemeData buildRisottoTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: RisottoColors.saffron,
    onPrimary: RisottoColors.charcoal,
    primaryContainer: RisottoColors.saffronSoft,
    onPrimaryContainer: RisottoColors.charcoal,
    secondary: RisottoColors.basil,
    onSecondary: RisottoColors.white,
    secondaryContainer: RisottoColors.basilSoft,
    onSecondaryContainer: RisottoColors.charcoal,
    tertiary: RisottoColors.tomato,
    onTertiary: RisottoColors.white,
    error: RisottoColors.tomatoDeep,
    onError: RisottoColors.white,
    errorContainer: Color(0xFFF9DCD6),
    onErrorContainer: RisottoColors.charcoal,
    surface: RisottoColors.cream,
    onSurface: RisottoColors.charcoal,
    surfaceContainerLowest: RisottoColors.white,
    surfaceContainerLow: Color(0xFFFFFBF2),
    surfaceContainer: RisottoColors.creamDark,
    surfaceContainerHigh: RisottoColors.creamDark,
    surfaceContainerHighest: Color(0xFFF0DFB4),
    onSurfaceVariant: RisottoColors.charcoalSoft,
    outline: Color(0xFF7A7F7B),
    outlineVariant: RisottoColors.outline,
    inverseSurface: RisottoColors.charcoal,
    onInverseSurface: RisottoColors.cream,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: risottoFontFamily,
    scaffoldBackgroundColor: RisottoColors.cream,
  );

  // Typography scale of the design system, mapped to Material roles.
  TextStyle style(
    double size,
    FontWeight weight,
    double height, [
    double? spacing,
  ]) => TextStyle(
    fontFamily: risottoFontFamily,
    fontSize: size,
    fontWeight: weight,
    height: height / size,
    letterSpacing: spacing,
    color: RisottoColors.charcoal,
  );
  final textTheme = base.textTheme.copyWith(
    displaySmall: style(32, FontWeight.w800, 40, -0.64),
    headlineLarge: style(32, FontWeight.w800, 40, -0.64),
    headlineMedium: style(26, FontWeight.w700, 34, -0.26),
    headlineSmall: style(22, FontWeight.w700, 28),
    titleLarge: style(22, FontWeight.w700, 28),
    titleMedium: style(18, FontWeight.w600, 24),
    titleSmall: style(15, FontWeight.w600, 20),
    bodyLarge: style(16, FontWeight.w400, 26),
    bodyMedium: style(15, FontWeight.w400, 24),
    bodySmall: style(
      13,
      FontWeight.w400,
      20,
    ).copyWith(color: RisottoColors.charcoalSoft),
    labelLarge: style(15, FontWeight.w600, 20),
    labelMedium: style(13, FontWeight.w600, 18),
    labelSmall: style(11, FontWeight.w700, 14, 0.44),
  );

  const pill = StadiumBorder();
  // 48 dp minimum touch target.
  const buttonMinSize = Size(64, 48);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 24);
  const inputRadius = BorderRadius.all(Radius.circular(12));

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: RisottoColors.cream,
      surfaceTintColor: Colors.transparent,
      foregroundColor: RisottoColors.charcoal,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: const CardThemeData(
      color: RisottoColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: Color(0x331F2421),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: RisottoColors.saffron,
        foregroundColor: RisottoColors.charcoal,
        minimumSize: buttonMinSize,
        padding: buttonPadding,
        shape: pill,
        textStyle: textTheme.labelLarge,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: RisottoColors.saffron,
        foregroundColor: RisottoColors.charcoal,
        minimumSize: buttonMinSize,
        padding: buttonPadding,
        shape: pill,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: RisottoColors.basil,
        side: const BorderSide(color: RisottoColors.basil, width: 1.5),
        minimumSize: buttonMinSize,
        padding: buttonPadding,
        shape: pill,
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: RisottoColors.basil,
        minimumSize: buttonMinSize,
        shape: pill,
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: RisottoColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: RisottoColors.charcoalSoft,
      ),
      prefixIconColor: RisottoColors.charcoalSoft,
      // Never saffron for small text (2:1 on white): basil when focused.
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (states) => TextStyle(
          fontFamily: risottoFontFamily,
          color: states.contains(WidgetState.error)
              ? RisottoColors.tomatoDeep
              : states.contains(WidgetState.focused)
              ? RisottoColors.basil
              : RisottoColors.charcoalSoft,
        ),
      ),
      border: const OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: RisottoColors.inputBorder, width: 1.5),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: RisottoColors.inputBorder, width: 1.5),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: RisottoColors.basil, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: RisottoColors.tomato, width: 1.5),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: inputRadius,
        borderSide: BorderSide(color: RisottoColors.tomato, width: 2),
      ),
      errorStyle: textTheme.bodySmall?.copyWith(
        color: RisottoColors.tomatoDeep,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: RisottoColors.white,
      selectedColor: RisottoColors.basil,
      side: const BorderSide(color: RisottoColors.outline),
      shape: pill,
      labelStyle: textTheme.labelMedium,
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: RisottoColors.white,
      ),
      checkmarkColor: RisottoColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: RisottoColors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: RisottoColors.saffronSoft,
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(color: RisottoColors.charcoal),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: RisottoColors.creamDark,
        foregroundColor: RisottoColors.charcoal,
        selectedBackgroundColor: RisottoColors.basil,
        selectedForegroundColor: RisottoColors.white,
        side: BorderSide.none,
        minimumSize: const Size(48, 48),
        textStyle: textTheme.labelMedium,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: RisottoColors.charcoal,
      unselectedLabelColor: RisottoColors.charcoalSoft,
      labelStyle: textTheme.labelLarge,
      unselectedLabelStyle: textTheme.labelLarge,
      indicatorColor: RisottoColors.saffron,
      dividerColor: RisottoColors.outline,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: RisottoColors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: RisottoColors.white,
      surfaceTintColor: Colors.transparent,
    ),
    listTileTheme: const ListTileThemeData(iconColor: RisottoColors.charcoal),
    dividerTheme: const DividerThemeData(color: RisottoColors.outline),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: RisottoColors.charcoal,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: RisottoColors.cream,
      ),
      actionTextColor: RisottoColors.saffron,
      behavior: SnackBarBehavior.floating,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: RisottoColors.basil,
      selectionHandleColor: RisottoColors.basil,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: RisottoColors.basil,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? RisottoColors.white
            : RisottoColors.charcoalSoft,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? RisottoColors.basil
            : RisottoColors.creamDark,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? RisottoColors.basil
            : RisottoColors.charcoalSoft,
      ),
    ),
  );
}
