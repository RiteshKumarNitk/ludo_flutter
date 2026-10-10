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

  ///Vertical gap between sections (14–18)
  static const double section = 16;
}

class AppRadius {
  const AppRadius._();

  static const double chip = 10;
  static const double iconButton = 14;
  static const double segmentedInner = 14;
  static const double segmentedOuter = 18;
  static const double button = 18;
  static const double buttonLarge = 22;
  static const double card = 24;

  //General scale
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 24;

  static const BorderRadius chipAll = BorderRadius.all(Radius.circular(chip));
  static const BorderRadius iconButtonAll = BorderRadius.all(Radius.circular(iconButton));
  static const BorderRadius buttonAll = BorderRadius.all(Radius.circular(button));
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

class AppSizes {
  const AppSizes._();

  ///Smallest touch target for any control
  static const double minTouch = 46;

  ///Touch target around a pawn on the board
  static const double pawnTouch = 48;
  static const double iconButton = 46;
  static const double button = 58;
  static const double buttonLarge = 66;

  ///Height of the solid drop edge under primary buttons (5–6 px)
  static const double buttonEdge = 6;

  ///Background dot grid
  static const double dotSpacing = 24;
  static const double dotRadius = 1.5;
}

class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
  ];

  static List<BoxShadow> glow(Color color, {double strength = 1}) => [
        BoxShadow(color: color.withValues(alpha: 0.5 * strength), blurRadius: 20 * strength, spreadRadius: 1),
      ];

  static const List<BoxShadow> board = [
    BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 14)),
  ];

  static const Color edge = AppColors.goldEdge;
}

///Durations and curves shared by UI (non-game) animations
class AppMotion {
  const AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 480);

  ///Repeating pulse of "tap me" highlights
  static const Duration pulse = Duration(milliseconds: 1300);

  ///Bob of a selectable pawn
  static const Duration bob = Duration(milliseconds: 900);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
}
