import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pronexa colours: deep navy, flat fills only (no gradients, no glows).
/// Every text pair used in the app meets WCAG AA; see docs/DESIGN.md.
abstract final class C {
  /// App background.
  static const bg = Color(0xFF07101C);

  /// Panels and list cards.
  static const surface = Color(0xFF111A2C);

  /// Raised fills inside panels: tracks, steppers, unselected tiles.
  static const surface2 = Color(0xFF18233A);
  static const line = Color(0xFF222E46);

  static const ink = Color(0xFFFFFFFF);
  static const ink2 = Color(0xFFC3C8D1);
  static const ink3 = Color(0xFF9AA3B2);

  /// Header block, hero panels and the Assistant Pill.
  static const indigo = Color(0xFF20296B);

  /// Selected pills, rows and the active nav button.
  static const indigo2 = Color(0xFF293477);

  /// Secondary text on indigo.
  static const onIndigo2 = Color(0xFFB9C2E8);

  /// Accent: focus rings, progress, icons.
  static const blue = Color(0xFF50A2FF);

  /// Accent text on panels.
  static const blueInk = Color(0xFF8FC2FF);

  static const good = Color(0xFF5FD38A);
  static const goodBg = Color(0xFF13291F);

  /// Gaps, warnings and value tags. Amber, never red.
  static const warm = Color(0xFFF5B971);
  static const warmBg = Color(0xFF2A2116);

  /// Light tile behind the food illustrations, which have dark outlines.
  static const tile = Color(0xFFE9EDF5);
}

abstract final class R {
  static const sm = 13.0;
  static const md = 18.0;
  static const lg = 22.0;
  static const xl = 30.0;
}

/// Durations shared by the animated widgets.
abstract final class Motion {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
  static const curve = Curves.easeOutCubic;

  /// Zero when the phone asks for less motion.
  static Duration of(BuildContext context, Duration d) => MediaQuery.of(context).disableAnimations ? Duration.zero : d;
}

/// Every screen is dark, so the status bar icons are always light.
const lightIcons = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: C.bg,
  systemNavigationBarIconBrightness: Brightness.light,
);

/// Fade with a short upward slide. Lighter than the default zoom on old phones.
class _FadeUpTransitions extends PageTransitionsBuilder {
  const _FadeUpTransitions();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final curved = CurvedAnimation(parent: animation, curve: Motion.curve, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: Colors.white,
    onPrimary: C.bg,
    primaryContainer: C.indigo2,
    onPrimaryContainer: Colors.white,
    secondary: C.blue,
    onSecondary: C.bg,
    surface: C.surface,
    onSurface: C.ink,
    onSurfaceVariant: C.ink2,
    surfaceContainerHighest: C.surface2,
    outline: C.line,
    outlineVariant: C.line,
    error: C.warm,
    onError: C.bg,
  );
  const stadium = StadiumBorder();
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.bg,
    canvasColor: C.bg,
    fontFamily: 'Poppins',
    fontFamilyFallback: const ['NairaSign'],
    splashFactory: InkRipple.splashFactory, // cheaper than InkSparkle on low-end phones
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: _FadeUpTransitions(), TargetPlatform.iOS: _FadeUpTransitions(), TargetPlatform.linux: _FadeUpTransitions()},
    ),
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
      systemOverlayStyle: lightIcons,
      titleTextStyle: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w500, color: C.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: C.bg,
        disabledBackgroundColor: C.surface2,
        disabledForegroundColor: C.ink3,
        minimumSize: const Size(64, 56),
        shape: stadium,
        animationDuration: Motion.fast,
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
        foregroundColor: C.blueInk,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: C.ink)),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : C.ink3),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.blue : C.surface2),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.white,
      contentTextStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: C.bg),
      actionTextColor: C.indigo,
      shape: StadiumBorder(),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: C.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: C.line,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: C.surface, surfaceTintColor: Colors.transparent),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(8))),
      textStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: C.bg),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: C.blue, selectionColor: Color(0x6650A2FF), selectionHandleColor: C.blue),
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
        borderSide: const BorderSide(color: C.blue, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: C.line, space: 1, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.blue, linearTrackColor: C.surface2),
  );
}
