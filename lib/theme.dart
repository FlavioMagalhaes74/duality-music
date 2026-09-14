import 'package:flutter/material.dart';

enum AppThemeMode { dualityDark, angelicLight }

class DualityThemes {
  static const Color crimson = Color(0xFF54141E);
  static const Color cream = Color(0xFFF4EFE6);
  static const Color haloGold = Color(0xFFBFA263);
  static const Color pitchBlack = Color(0xFF141216);
  static const Color darkSurface = Color(0xFF1E1A22);

  static final ThemeData dualityDark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: pitchBlack,
    primaryColor: crimson,
    colorScheme: const ColorScheme.dark(
      primary: crimson,
      secondary: haloGold,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSurface: cream,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: pitchBlack,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: cream, fontSize: 20, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: haloGold),
    ),
  );

  static final ThemeData angelicLight = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: cream,
    primaryColor: haloGold,
    colorScheme: const ColorScheme.light(
      primary: haloGold,
      secondary: crimson,
      surface: Colors.white,
      onPrimary: pitchBlack,
      onSurface: pitchBlack,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: cream,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: pitchBlack, fontSize: 20, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: crimson),
    ),
  );
}