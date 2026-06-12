import 'package:flutter/material.dart';

class AlterPalette {
  const AlterPalette._();

  static const snow = Color(0xFFF8F7FF);
  static const white = Color(0xFFFFFFFF);
  static const mist = Color(0xFFE8E7F5);
  static const ink = Color(0xFF090A14);
  static const graphite = Color(0xFF161823);
  static const slate = Color(0xFF62657A);
  static const iris = Color(0xFF7C3DFF);
  static const violet = Color(0xFFB76CFF);
  static const aura = Color(0xFFFF5FB7);
  static const cyan = Color(0xFF41D4FF);
  static const mint = Color(0xFF48E0B6);
  static const amber = Color(0xFFFFC861);
  static const danger = Color(0xFFFF6678);

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

