import 'package:flutter/material.dart';

import '../theme/alter_palette.dart';

class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    this.style,
    this.gradient = AlterPalette.premiumGradient,
    this.textAlign,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(text, style: style, textAlign: textAlign),
    );
  }
}
