import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pronexa colours, taken from the Asteria design: a near-black navy canvas,
/// an indigo header, white sheets for lists, and blue as the one accent.
/// Every text pair meets WCAG AA; see docs/DESIGN.md.
abstract final class C {
  // Dark canvas.
  static const bg = Color(0xFF0A0E17);
  static const ink = Color(0xFFFFFFFF);

  /// White at 70% on [bg] (9.6:1).
  static const ink2 = Color(0xFFB6B7B9);

  /// White at 60% on [bg] (7.3:1). Captions and caps labels.
  static const ink3 = Color(0xFF9D9FA2);

  /// White at 10%: group outlines, input outlines.
  static const line = Color(0x1AFFFFFF);

  /// White at 5%: chip and button fills, hairlines between rows.
  static const fill = Color(0x0DFFFFFF);

  static const indigo = Color(0xFF20296B);
  static const indigo2 = Color(0xFF293477);
  static const blue = Color(0xFF50A2FF);
  static const blueSoft = Color(0x3350A2FF);

  /// Gaps and "check this" on dark. Amber, never red.
  static const warm = Color(0xFFF5B971);
  static const good = Color(0xFF5FD38A);

  // White sheet (lists on Today and Close the gap).
  static const sheet = Color(0xFFFFFFFF);
  static const sInk = Color(0xFF07101C);

  /// Black at 60% on white (5.7:1).
  static const sInk2 = Color(0xFF666666);
  static const sTile = Color(0xFFF2F4F7);
  static const sGood = Color(0xFF007A2E);
  static const sWarm = Color(0xFF9A4A08);
  static const sBlue = Color(0xFF1A5FB8);

  /// Light tile behind the food illustrations, which have dark outlines.
  static const tile = Color(0xFFF2F4F7);

  /// The Asteria header: sky blue fading into the canvas. Darkened at the
  /// top so white text stays above 4.5:1.
  static const header = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF4F6896), Color(0xFF2E3D72), Color(0xFF1C2756), Color(0xFF111A40), Color(0xFF0A0E17)],
    stops: [0, 0.22, 0.4, 0.63, 1],
  );

  /// The active navigation button.
  static const navActive = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF07101B), Color(0xFF293477)]);
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

/// Every screen starts dark, so the status bar icons are always light.
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

const _font = 'Poppins';
const _fallback = ['NairaSign'];

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: Colors.white,
    onPrimary: Colors.black,
    primaryContainer: C.indigo2,
    onPrimaryContainer: Colors.white,
    secondary: C.blue,
    onSecondary: C.sInk,
    surface: C.bg,
    onSurface: C.ink,
    onSurfaceVariant: C.ink2,
    surfaceContainerHighest: Color(0xFF1A1E27),
    outline: C.line,
    outlineVariant: C.line,
    error: C.warm,
    onError: C.sInk,
  );
  const stadium = StadiumBorder();
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.bg,
    canvasColor: C.bg,
    fontFamily: _font,
    fontFamilyFallback: _fallback,
    splashFactory: InkRipple.splashFactory, // cheaper than InkSparkle on low-end phones
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: _FadeUpTransitions(), TargetPlatform.iOS: _FadeUpTransitions(), TargetPlatform.linux: _FadeUpTransitions()},
    ),
  );
  final text = base.textTheme
      .apply(bodyColor: C.ink, displayColor: C.ink)
      .copyWith(
        displaySmall: const TextStyle(fontSize: 48, fontWeight: FontWeight.w500, letterSpacing: -2.4, height: 1, color: C.ink),
        headlineSmall: const TextStyle(fontSize: 30, fontWeight: FontWeight.w500, letterSpacing: -0.8, height: 1.05, color: C.ink),
        titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: -0.45, color: C.ink),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.3, color: C.ink),
        bodyLarge: const TextStyle(fontSize: 16, height: 1.4, color: C.ink2),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.4, color: C.ink2),
        bodySmall: const TextStyle(fontSize: 12, height: 1.33, color: C.ink3),
        labelSmall: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1, color: C.ink3),
      );
  // Apply the family last: copyWith above replaces whole styles, which would drop it.
  final themed = text.apply(fontFamily: _font, fontFamilyFallback: _fallback);
  return base.copyWith(
    textTheme: themed,
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: _font, fontFamilyFallback: _fallback),
    appBarTheme: const AppBarTheme(
      backgroundColor: C.bg,
      foregroundColor: C.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 64,
      systemOverlayStyle: lightIcons,
      titleTextStyle: TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: -0.45, color: C.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        disabledBackgroundColor: C.fill,
        disabledForegroundColor: C.ink3,
        minimumSize: const Size(64, 60),
        shape: stadium,
        animationDuration: Motion.fast,
        textStyle: const TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.ink,
        backgroundColor: C.fill,
        minimumSize: const Size(64, 60),
        shape: stadium,
        side: const BorderSide(color: C.line),
        textStyle: const TextStyle(fontFamily: _font, fontSize: 17, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: C.ink,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: C.ink)),
    actionIconTheme: ActionIconThemeData(backButtonIconBuilder: (context) => const Icon(Icons.arrow_back_ios_new, size: 20)),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.blue : C.ink3),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.blueSoft : C.fill),
      trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.transparent : C.line),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.white,
      contentTextStyle: TextStyle(fontFamily: _font, fontSize: 14, color: C.sInk),
      actionTextColor: C.sBlue,
      shape: StadiumBorder(),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF141821),
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: Color(0x33FFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl))),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF141821),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(R.xl))),
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(8))),
      textStyle: TextStyle(fontFamily: _font, fontSize: 12, color: C.sInk),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: C.blue, selectionColor: Color(0x6650A2FF), selectionHandleColor: C.blue),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      hintStyle: const TextStyle(color: C.ink3),
      prefixIconColor: C.ink3,
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
    dividerTheme: const DividerThemeData(color: C.fill, space: 1, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.blue, linearTrackColor: C.fill),
  );
}
