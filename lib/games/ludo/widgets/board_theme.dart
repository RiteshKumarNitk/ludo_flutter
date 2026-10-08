import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/ludo_models.dart';

enum BoardThemeType {
  classic('Classic'),
  midnight('Midnight'),
  pastel('Pastel');

  final String label;
  const BoardThemeType(this.label);
}

///Every color used to paint the board and its pawns
class BoardTheme {
  final BoardThemeType type;
  final Color frame;
  final Color trackFill;
  final Color trackBorder;
  final Color yardFill;
  final Color centerFill;
  final Color starColor;
  final Color dimmedCorner;
  final Color green;
  final Color yellow;
  final Color blue;
  final Color red;

  const BoardTheme({
    required this.type,
    required this.frame,
    required this.trackFill,
    required this.trackBorder,
    required this.yardFill,
    required this.centerFill,
    required this.starColor,
    required this.dimmedCorner,
    required this.green,
    required this.yellow,
    required this.blue,
    required this.red,
  });

  Color colorOf(LudoColor color) {
    switch (color) {
      case LudoColor.green:
        return green;
      case LudoColor.yellow:
        return yellow;
      case LudoColor.blue:
        return blue;
      case LudoColor.red:
        return red;
    }
  }

  static BoardTheme of(BoardThemeType type) {
    switch (type) {
      case BoardThemeType.classic:
        return const BoardTheme(
          type: BoardThemeType.classic,
          frame: Color(0xFFFFFFFF),
          trackFill: Color(0xFFFFFFFF),
          trackBorder: Color(0xFFC9CDD8),
          yardFill: Color(0xFFFFFFFF),
          centerFill: Color(0xFFFFFFFF),
          starColor: Color(0xFF9AA0B4),
          dimmedCorner: Color(0xB86E7480),
          green: AppColors.playerGreen,
          yellow: AppColors.playerYellow,
          blue: AppColors.playerBlue,
          red: AppColors.playerRed,
        );
      case BoardThemeType.midnight:
        return const BoardTheme(
          type: BoardThemeType.midnight,
          frame: Color(0xFF151B33),
          trackFill: Color(0xFF1F2747),
          trackBorder: Color(0xFF3B4573),
          yardFill: Color(0xFF151B33),
          centerFill: Color(0xFF151B33),
          starColor: Color(0xFF8E97CD),
          dimmedCorner: Color(0xC0101426),
          green: Color(0xFF22A84A),
          yellow: Color(0xFFE8B30C),
          blue: Color(0xFF3D72E0),
          red: Color(0xFFE23D3D),
        );
      case BoardThemeType.pastel:
        return const BoardTheme(
          type: BoardThemeType.pastel,
          frame: Color(0xFFFFFBF4),
          trackFill: Color(0xFFFFFFFF),
          trackBorder: Color(0xFFDCD2EA),
          yardFill: Color(0xFFFFFDF8),
          centerFill: Color(0xFFFFFFFF),
          starColor: Color(0xFFB39DDB),
          dimmedCorner: Color(0x998B8798),
          green: Color(0xFF6CCB8C),
          yellow: Color(0xFFF5C95A),
          blue: Color(0xFF7FA7EE),
          red: Color(0xFFF08C7E),
        );
    }
  }
}
