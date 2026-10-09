import 'package:flutter/material.dart';

///The app palette. Screens use these tokens instead of literal colors.
class AppColors {
  const AppColors._();

  //Backgrounds and surfaces (Khelora deep navy, brand base #11182B)
  static const Color backgroundTop = Color(0xFF1B2646);
  static const Color backgroundBottom = Color(0xFF0B1020);
  static const Color surface = Color(0xFF1A2341);
  static const Color surfaceRaised = Color(0xFF253155);
  static const Color surfaceSunken = Color(0xFF0E1427);
  static const Color outline = Color(0xFF314070);
  static const Color scrim = Color(0xCC060A16);

  //Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC5CDE8);
  static const Color textMuted = Color(0xFF8691B5);
  static const Color textOnLight = Color(0xFF11182B);

  //Actions
  static const Color primary = Color(0xFFF6C453); //Khelora gold
  static const Color primaryDeep = Color(0xFFC9922B);
  static const Color onPrimary = Color(0xFF3A2700);
  static const Color secondary = Color(0xFF6E9BFF); //Khelora blue
  static const Color secondaryDeep = Color(0xFF4A70D4);
  static const Color danger = Color(0xFFFF6F78); //Khelora coral
  static const Color dangerDeep = Color(0xFFD24D57);
  static const Color success = Color(0xFF4CD7A0); //Khelora mint
  static const Color gold = Color(0xFFFFD54F);
  static const Color silver = Color(0xFFCFD8E3);
  static const Color bronze = Color(0xFFE0A26E);

  //Player colors, shared by every game that seats colored players
  static const Color playerRed = Color(0xFFEF4A4A);
  static const Color playerGreen = Color(0xFF2EBF5B);
  static const Color playerYellow = Color(0xFFFFC61A);
  static const Color playerBlue = Color(0xFF2F86F0);

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundTop, backgroundBottom],
  );

  ///Lighter and darker variants for gradients and 3D edges
  static Color lighten(Color c, [double amount = 0.15]) =>
      Color.lerp(c, Colors.white, amount)!;

  static Color darken(Color c, [double amount = 0.2]) => Color.lerp(c, Colors.black, amount)!;
}
