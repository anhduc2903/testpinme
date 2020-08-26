import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// '436_1584523253_Free Video Templates - Your Shortcut To The Perfect Video.mp4',
// '436_1584523253_Free Video Templates - Your Shortcut To The Perfect Video_2.mp4',
// '435_1584523253_Free Video Templates - Your Shortcut To The Perfect Video_3.mp4',
// '435_1584605327_Free Video Templates - Your Shortcut To The Perfect Video_4.mp4',

const videoNames1 = [
  '1.mp4',
  '2.mp4',
];
const videoNames2 = [
  '1.mp4',
  '2.mp4',
];

const imageNames1 = [
  '1.jpg',
  '2.jpg',
];

const imageNames2 = [
  '1.jpg',
  '2.jpg',
];

final ScreenUtils utils = ScreenUtils();
final color = Color(int.parse('0xFF404CF0'));

class ScreenUtils {
  double _screenHeight;
  double _screenWidth;

  double get screenHeight => _screenHeight;
  double get screenWidth => _screenWidth;

  final double _referenceScreenHeight = 640;
  final double _referenceScreenWidth = 360;

  void update({double width, double height}) {
    _screenWidth = (width != null) ? width : _screenWidth;
    _screenHeight = (height != null) ? height : _screenHeight;
  }

  double height(double height) {
    if (_screenHeight == null) return height;
    return _screenHeight * height / _referenceScreenHeight;
  }

  double width(double width) {
    if (_screenWidth == null) return width;
    return _screenWidth * width / _referenceScreenWidth;
  }

  double fSize(double fontSize) {
    return fontSize * _screenWidth / _referenceScreenWidth;
  }

  TextStyle text({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.normal,
    Color color,
    bool isChangeAccordingToDeviceSize = true,
  }) {
    if (isChangeAccordingToDeviceSize && this._screenWidth != null) {
      fontSize = fontSize * _screenWidth / _referenceScreenWidth;
    }

    return GoogleFonts.roboto(
      fontWeight: fontWeight,
      fontSize: fontSize,
      color: color,
    );
  }
}
