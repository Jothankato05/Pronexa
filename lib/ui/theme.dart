import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pronexa colours. Flat fills only: no gradients, no glows.
/// Every text pair used in the app meets WCAG AA.
abstract final class C {
  static const bg = Color(0xFFFAF7F2);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF2ECE3);
  static const line = Color(0xFFE7DFD3);
  static const ink = Color(0xFF2B2A27);
  static const ink2 = Color(0xFF5C574F);
  static const ink3 = Color(0xFF6B645A);

  static const leaf800 = Color(0xFF1F4A33);
  static const leaf700 = Color(0xFF2E6340);
  static const leaf600 = Color(0xFF3B7A4F);
  static const leaf300 = Color(0xFF97C487);
  static const leaf200 = Color(0xFFC9DFC3);
  static const leaf100 = Color(0xFFE4EFE0);
  static const leaf50 = Color(0xFFF1F6EE);

  static const clay700 = Color(0xFF9C4F25);
  static const clay200 = Color(0xFFF0CDB4);
  static const clay100 = Color(0xFFF8E7DA);

  static const ochre800 = Color(0xFF7A5410);
  static const ochre400 = Color(0xFFD9A441);
  static const ochre100 = Color(0xFFF6EBCF);

  /// Text on the green header (white at 86% is 5.7:1 on leaf700).
  static const onGreen2 = Color(0xDBFFFFFF);
}

abstract final class R {
  static const sm = 13.0;
  static const md = 18.0;
  static const lg = 22.0;
  static const xl = 30.0;
}

const darkIcons = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: C.bg,
  systemNavigationBarIconBrightness: Brightness.dark,
);

const lightIcons = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: C.bg,
  systemNavigationBarIconBrightness: Brightness.dark,
);

ThemeData buildTheme() {
  const scheme = ColorScheme.light(
    primary: C.leaf600,
    onPrimary: Colors.white,
    primaryContainer: C.leaf100,
    onPrimaryContainer: C.leaf700,
    secondary: C.ochre400,
    onSecondary: C.ink,
    surface: C.surface,
    onSurface: C.ink,
    onSurfaceVariant: C.ink2,
    outline: C.line,
    outlineVariant: C.line,
    error: C.clay700,
    onError: Colors.white,
  );
  const stadium = StadiumBorder();
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.bg,
    fontFamily: 'Poppins',
    fontFamilyFallback: const ['NairaSign'],
    splashFactory: InkRipple.splashFactory, // cheaper than InkSparkle on low-end phones
  );
  final text = base.textTheme
      .apply(bodyColor: C.ink, displayColor: C.ink)
      .copyWith(
        displaySmall: const TextStyle(fontSize: 44, fontWeight: FontWeight.w500, letterSpacing: -1.5, height: 1, color: C.ink),
        headlineSmall: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500, letterSpacing: -0.5, height: 1.15, color: C.ink),
        titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: -0.3, color: C.ink),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: C.ink),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.5, color: C.ink),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.45, color: C.ink2),
        bodySmall: const TextStyle(fontSize: 12.5, height: 1.35, color: C.ink3),
        labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1, color: C.ink3),
      );
  // Apply the family last: copyWith above replaces whole styles, which would drop it.
  final themed = text.apply(fontFamily: 'Poppins', fontFamilyFallback: const ['NairaSign']);
  return base.copyWith(
    textTheme: themed,
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Poppins', fontFamilyFallback: const ['NairaSign']),
    appBarTheme: const AppBarTheme(
      backgroundColor: C.bg,
      foregroundColor: C.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: darkIcons,
      titleTextStyle: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w500, color: C.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.leaf600,
        foregroundColor: Colors.white,
        disabledBackgroundColor: C.surface2,
        disabledForegroundColor: C.ink3,
        minimumSize: const Size(64, 56),
        shape: stadium,
        textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.ink,
        backgroundColor: C.surface,
        minimumSize: const Size(64, 52),
        shape: stadium,
        side: const BorderSide(color: C.line),
        textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: C.leaf700,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : C.ink3),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.leaf600 : C.surface2),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.leaf800,
      contentTextStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.white),
      actionTextColor: C.ochre100,
      shape: StadiumBorder(),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: C.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: const TextStyle(color: C.ink3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(99),
        borderSide: const BorderSide(color: C.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(99),
        borderSide: const BorderSide(color: C.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(99),
        borderSide: const BorderSide(color: C.leaf600, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: C.line, space: 1, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.leaf600),
  );
}
