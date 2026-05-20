import 'package:flutter/material.dart';

class ResultPageStyle {
  static const Color primary = Color(0xff1d63ff);
  static const Color secondary = Color(0xff4fa9ff);
  static const Color bg = Color(0xffeef2f7);
  static const Color surface = Colors.white;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
