import 'package:flutter/material.dart';

/// Color tokens for the older ContextOS / backend screens.
///
/// The hues here are intentionally repointed onto the shared ALTER signature
/// design language (lime-on-deep-violet-black) defined in
/// `lib/src/ui/theme.dart` (`AppColors`). The token *names* are kept stable so
/// every existing screen keeps compiling and laying out exactly as before —
/// only the colors move, so the whole app now reads as one system that matches
/// the "Alter Standalone" reference design. This is presentation-only: no
/// widget, provider, route, or data flow changes.
class AlterPalette {
  const AlterPalette._();

  // Light neutrals — used in the (optional) light-theme branches and for
  // genuinely white surfaces. Aligned to the reference light tones.
  static const snow = Color(0xFFF4F1FB);
  static const white = Color(0xFFFFFFFF);
  static const mist = Color(0xFFEAE3F4);

  // Dark neutrals — the active theme. Match AppColors.bg / panel / muted text.
  static const ink = Color(0xFF0A0810); // deep canvas
  static const graphite = Color(0xFF15101F); // raised panel
  static const slate = Color(0xFF9A93AD); // muted / secondary text

  // Accents — repointed to the reference palette (AppColors).
  // `iris` carries the signature lime: it was the primary accent in these
  // screens (active states, highlights, accent icons/labels), which is exactly
  // where the reference design uses lime.
  static const iris = Color(0xFFCDF74D); // signature lime
  static const violet = Color(0xFF9B6BFF); // purple
  static const aura = Color(0xFFFF6BD0); // pink
  static const cyan = Color(0xFF5BE0FF); // cyan
  static const mint = Color(0xFF38E8A0); // green
  static const amber = Color(0xFFFF8A3C); // orange
  static const danger = Color(0xFFFF8A8A); // soft red

  static const premiumGradient = LinearGradient(
    colors: [iris, violet, aura],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const coolGradient = LinearGradient(
    colors: [cyan, iris],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
