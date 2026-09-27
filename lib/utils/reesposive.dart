import 'package:flutter/widgets.dart';

class ResponsiveConfig {
  static double _screenWidth = 360;
  static double _screenHeight = 800;
  static double _scaleWidth = 1;
  static double _scaleHeight = 1;
  static double _scaleText = 1;
  static bool isInitialized = false;

  // Your Figma / design base dimensions
  static const double _designWidth = 360;
  static const double _designHeight = 800;

  static void init(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    _screenWidth = size.width;
    _screenHeight = size.height;

    _scaleWidth = _screenWidth / _designWidth;
    _scaleHeight = _screenHeight / _designHeight;

    // Base text scale on smaller ratio (to avoid distortion)
    _scaleText = _scaleWidth < _scaleHeight ? _scaleWidth : _scaleHeight;

    //  Tablet & iPad optimization:
    // Prevent text/UI from getting *too big* on very large
    // screens
    if (_scaleText > 1.5) _scaleText = 1.5;
    if (_scaleWidth > 1.8) _scaleWidth = 1.8;
    if (_scaleHeight > 1.8) _scaleHeight = 1.8;

    isInitialized = true;
  }

  static double scaleWidth(double width) => width * _scaleWidth;
  static double scaleHeight(double height) => height * _scaleHeight;
  static double scaleText(double fontSize) => fontSize * _scaleText;

  static double get screenWidth => _screenWidth;
  static double get screenHeight => _screenHeight;
}

extension ResponsiveExtensions on num {
  double get w => ResponsiveConfig.scaleWidth(toDouble());
  double get h => ResponsiveConfig.scaleHeight(toDouble());
  double get sp => ResponsiveConfig.scaleText(toDouble());
}
