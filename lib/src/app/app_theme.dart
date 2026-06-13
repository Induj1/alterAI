import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/alter_palette.dart';

class AlterTheme {
  const AlterTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AlterPalette.iris,
        brightness: brightness,
        primary: AlterPalette.iris,
        secondary: AlterPalette.aura,
        tertiary: AlterPalette.cyan,
        surface: isDark ? AlterPalette.ink : Colors.white,
      ),
    );
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: isDark ? AlterPalette.ink : AlterPalette.snow,
      textTheme: textTheme.apply(
        bodyColor: isDark ? Colors.white : AlterPalette.ink,
        displayColor: isDark ? Colors.white : AlterPalette.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : AlterPalette.ink,
        size: 22,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AlterPalette.iris.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AlterPalette.iris,
        inactiveTrackColor: AlterPalette.iris.withValues(alpha: 0.15),
        thumbColor: Colors.white,
        overlayColor: AlterPalette.iris.withValues(alpha: 0.14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return isDark ? AlterPalette.mist : AlterPalette.slate;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AlterPalette.iris;
          }
          return AlterPalette.slate.withValues(alpha: 0.18);
        }),
      ),
    );
  }
}
