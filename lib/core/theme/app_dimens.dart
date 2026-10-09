import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  ///Horizontal page gutter
  static const double gutter = 20;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 30;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 4)),
  ];

  static List<BoxShadow> glow(Color color, {double strength = 1}) => [
        BoxShadow(color: color.withValues(alpha: 0.55 * strength), blurRadius: 22 * strength, spreadRadius: 1),
      ];

  static const List<BoxShadow> board = [
    BoxShadow(color: Color(0x80000000), blurRadius: 30, offset: Offset(0, 12)),
    BoxShadow(color: Color(0x336E9BFF), blurRadius: 40, spreadRadius: 2),
  ];

  static const Color edge = AppColors.backgroundBottom;
}

///Durations shared by UI (non-game) animations
class AppMotion {
  const AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 480);
}
