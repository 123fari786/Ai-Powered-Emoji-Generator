import 'package:flutter/material.dart';

class AppColors {
  // Background gradients / main colors
  static const Color background = Color(0xFFF6F2FF); // lighter purple (top)
  static const Color backgroundTwo = Color(0xFFCBD6FF); // darker blue (bottom)

  // Standard colors
  static const Color black = Color(0xFF000000); // existing black
  static const Color blackFull = Color(0xFF000000); // full black
  static const Color white = Color(0xFFFFFFFF); // full white
  static const Color whiteee = Color(
    0x80FFFFFF,
  ); // semi-transparent white (50%)
  static const Color grey = Color(0xFF808080);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color red = Color(0xFFF44336); // 30% opacity black

  static const Color black30 = Color(0x4D000000);
  static const Color fullwhite = Color(
    0xFFFFFFFF,
  ); // duplicate full white (optional)
  static const Color white30 = Color(0x60FFFFFF); // 30% opacity white

  // Container backgrounds (10% opacity)
  static const Color containerYellow10 = Color(0x1AFFE500); // #FFE5001A
  static const Color containerBlue10 = Color(0x1A00C7FF); // #00C7FF1A
  static const Color containerPurple10 = Color(0x1A8F8BFF); // #8F8BFF1A

  // Primary color
  static const Color primary = Color(0xFF9367F4);
}
