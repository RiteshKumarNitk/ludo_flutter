import 'package:flutter/material.dart';

///The app palette. Screens use these tokens instead of literal colors.
class AppColors {
  const AppColors._();

  //Backgrounds and surfaces (deep night-indigo game table)
  static const Color backgroundTop = Color(0xFF221A57);
  static const Color backgroundBottom = Color(0xFF0D0A26);
  static const Color surface = Color(0xFF2A2163);
  static const Color surfaceRaised = Color(0xFF372C7A);
  static const Color surfaceSunken = Color(0xFF1A1442);
  static const Color outline = Color(0xFF4A3F96);
  static const Color scrim = Color(0xCC090620);

  //Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC8C1F2);
  static const Color textMuted = Color(0xFF8C84C4);
  static const Color textOnLight = Color(0xFF1C1640);

  //Actions
  static const Color primary = Color(0xFFFFC233);
  static const Color primaryDeep = Color(0xFFD98E00);
  static const Color onPrimary = Color(0xFF3B2600);
  static const Color secondary = Color(0xFF7C5CFF);
  static const Color secondaryDeep = Color(0xFF5134D1);
  static const Color danger = Color(0xFFFF5A64);
  static const Color dangerDeep = Color(0xFFC6303C);
  static const Color success = Color(0xFF3DDC97);
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
