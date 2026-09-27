import 'package:flutter/material.dart';

class BackgroundTheme {
  // Gradient starting strong at bottom-right and fading toward top-left
  static final LinearGradient background = LinearGradient(
    begin: Alignment.bottomRight, // start from bottom-right
    end: Alignment.topLeft, // fade toward top-left
    colors: [
      Color(0xFFD9DFFF), // Strong color at bottom-right
      Color(0xFFF2EDFF), // Lighter/faded at top-left
    ],
    stops: const [0.0, 2.0], // start fully at bottom-right, end at top-left
  );

  static const double width = 440;
  static const double height = 956;
  static const double opacity = 1.0;
}
