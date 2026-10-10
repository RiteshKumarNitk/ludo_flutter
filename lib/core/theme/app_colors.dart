import 'package:flutter/material.dart';

///The "Jaipur courtyard" palette. Screens use these tokens instead of
///literal colors.
class AppColors {
  const AppColors._();

  //Brand
  static const Color indigo = Color(0xFF1B2153);
  static const Color sandstone = Color(0xFFF6D9CB);
  static const Color gold = Color(0xFFF5B700);

  ///Solid "pressed edge" under gold buttons
  static const Color goldEdge = Color(0xFFB98900);
  static const Color boardWhite = Color(0xFFFFFDF9);
  static const Color cardDivider = Color(0xFFEEDCD2);

  //App background: flat indigo with a faint dot grid (no gradient washes)
  static const Color background = indigo;
  static const Color backgroundTop = indigo;
  static const Color backgroundBottom = indigo;
  static const Color backgroundDot = Color(0x11FFFFFF); //white at ~6.5%

  //Surfaces on indigo
  static const Color surface = Color(0xFF262D66); //≈ white 8% over indigo
  static const Color surfaceRaised = Color(0xFF323A7A);
  static const Color surfaceSunken = Color(0xFF141A45);
  static const Color outline = Color(0xFF4F5590); //≈ white 25% over indigo
  static const Color scrim = Color(0xCC0E1236);

  //Light cards on indigo
  static const Color card = boardWhite;
  static const Color onCard = indigo;
  static const Color onCardMuted = Color(0xFF4A4F75);

  //Text on indigo
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC9CDF0);
  static const Color textMuted = Color(0xFFA3A8D6);
  static const Color textOnLight = indigo;

  //Actions
  static const Color primary = gold;
  static const Color primaryDeep = goldEdge;
  static const Color onPrimary = indigo;
  static const Color secondary = sandstone;
  static const Color secondaryDeep = Color(0xFFD9B3A0);
  static const Color onSecondary = indigo;
  static const Color danger = Color(0xFFD62F33);
  static const Color dangerDeep = Color(0xFF9E1F22);
  static const Color success = Color(0xFF1F9D5C);

  //Medals
  static const Color medalGold = gold;
  static const Color medalSilver = Color(0xFFDDE2EA);
  static const Color medalBronze = Color(0xFFE9A877);
  static const Color silver = medalSilver;
  static const Color bronze = medalBronze;

  //Player colors: pawns, bases and board
  static const Color playerRed = Color(0xFFD62F33);
  static const Color playerGreen = Color(0xFF1F9D5C);
  static const Color playerYellow = Color(0xFFF2AE1C);
  static const Color playerBlue = Color(0xFF2F7BE5);

  //Player panel fills, darker where needed for 4.5:1 text contrast.
  //White text on all of them except yellow, which takes indigo text.
  static const Color panelRed = Color(0xFFD62F33);
  static const Color panelGreen = Color(0xFF157A46);
  static const Color panelYellow = Color(0xFFF2AE1C);
  static const Color panelBlue = Color(0xFF2163C4);

  static Color lighten(Color c, [double amount = 0.15]) => Color.lerp(c, Colors.white, amount)!;

  static Color darken(Color c, [double amount = 0.2]) => Color.lerp(c, Colors.black, amount)!;
}
