import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Global light/dark theme switch. Flip [isLight] and the whole app rebuilds
/// (see the ValueListenableBuilder in main.dart).
class AlterUiTheme {
  static final ValueNotifier<bool> isLight = ValueNotifier<bool>(false);
  static bool get light => isLight.value;
  static void setLight(bool v) => isLight.value = v;
}

/// Alter design tokens — colors and typography.
class AppColors {
  // Base (kept const: used in const gradient lists + as text color on bright
  // lime buttons, which stay dark in BOTH themes).
  static const bg = Color(0xFF0A0810);
  static const ink = Color(0xFF120E1C);

  // Theme-aware neutrals.
  static Color get bgRaised =>
      AlterUiTheme.light ? const Color(0xFFFFFFFF) : const Color(0xFF0D0A16);
  static Color get surfaceSolid =>
      AlterUiTheme.light ? const Color(0xFFFFFFFF) : const Color(0xFF0D0A16);
  static Color get screenBase =>
      AlterUiTheme.light ? const Color(0xFFEAE3F4) : bg;
  static Color get navBg =>
      AlterUiTheme.light ? const Color(0xFFFFFFFF) : const Color(0xFF14101C);

  /// White pill surface (e.g. "Ask Alter how") — flips to ink on light.
  static Color get pill =>
      AlterUiTheme.light ? const Color(0xFF18131F) : Colors.white;
  static Color get pillInk =>
      AlterUiTheme.light ? const Color(0xFFF5F2FB) : const Color(0xFF0A0810);

  // Accents
  static const lime = Color(0xFFCDF74D);
  static const limeDeep = Color(0xFFA6D63A);
  static const purple = Color(0xFF7C5CFF);
  static const purpleLight = Color(0xFF9B6BFF);
  static const purpleDeep = Color(0xFF5A2DB0);
  static const cyan = Color(0xFF5BE0FF);
  static const cyanDeep = Color(0xFF2D7AD0);
  static const orange = Color(0xFFFF8A3C);
  static const orangeDeep = Color(0xFFD14D1A);
  static const green = Color(0xFF38E8A0);
  static const greenDeep = Color(0xFF11A06A);
  static const pink = Color(0xFFFF6BD0);
  static const pinkDeep = Color(0xFFC02D9B);
  static const danger = Color(0xFFFF8A8A);

  // Foreground neutral — drives ALL text + translucent "glass" surfaces.
  // Flips from white (dark theme) to near-black indigo (light theme), so every
  // rgba(white, a) call themes correctly while preserving its alpha.
  static Color get _fg =>
      AlterUiTheme.light ? const Color(0xFF18131F) : Colors.white;
  static Color white(double o) => _fg.withValues(alpha: o);
  static Color get glass => _fg.withValues(alpha: 0.05);
  static Color get glassBorder => _fg.withValues(alpha: 0.10);
}

class AppText {
  /// Space Grotesk — display / headings.
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = Colors.white,
    double height = 1.08,
    double letterSpacing = -0.4,
    FontStyle? fontStyle,
  }) => GoogleFonts.spaceGrotesk(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
  );

  /// Manrope — body / UI.
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = Colors.white,
    double height = 1.4,
    double letterSpacing = 0,
  }) => GoogleFonts.manrope(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// Uppercase eyebrow / kicker label.
  static TextStyle kicker(Color color, {double size = 11}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.8,
      );
}

ThemeData buildAlterTheme(bool light) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: light ? Brightness.light : Brightness.dark,
  );
  final fg = light ? const Color(0xFF18131F) : Colors.white;
  // Manrope for body/UI, Space Grotesk for display + headlines — the same
  // typographic split as the reference design (see AppText). Applied globally
  // so every screen's headings match without per-screen edits.
  final manrope = GoogleFonts.manropeTextTheme(
    base.textTheme,
  ).apply(bodyColor: fg, displayColor: fg);
  final display = GoogleFonts.spaceGroteskTextTheme(base.textTheme)
      .apply(bodyColor: fg, displayColor: fg);
  final textTheme = manrope.copyWith(
    displayLarge: display.displayLarge?.copyWith(letterSpacing: -0.5),
    displayMedium: display.displayMedium?.copyWith(letterSpacing: -0.5),
    displaySmall: display.displaySmall?.copyWith(letterSpacing: -0.4),
    headlineLarge: display.headlineLarge?.copyWith(letterSpacing: -0.4),
    headlineMedium: display.headlineMedium?.copyWith(letterSpacing: -0.3),
    headlineSmall: display.headlineSmall?.copyWith(letterSpacing: -0.2),
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.screenBase,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.lime,
      secondary: AppColors.purpleLight,
      surface: AppColors.screenBase,
    ),
    textTheme: textTheme,
    splashFactory: InkRipple.splashFactory,
  );
}
