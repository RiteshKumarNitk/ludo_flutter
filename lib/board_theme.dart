import 'package:flutter/material.dart';

import 'constants.dart';

///Selectable skins for the painted board
enum BoardThemeType {
  ///The traditional white board with the classic Ludo colors
  classic,

  ///A dark board with deep navy cells, made for night play
  midnight,

  ///A light board with soft pastel player colors
  pastel;

  ///Short label shown on the settings screen
  String get label {
    switch (this) {
      case BoardThemeType.classic:
        return 'Classic';
      case BoardThemeType.midnight:
        return 'Midnight';
      case BoardThemeType.pastel:
        return 'Pastel';
    }
  }
}

///Every color the board painter needs to draw the board
class BoardTheme {
  ///The skin this instance was built from
  final BoardThemeType type;

  ///Color painted behind the whole grid
  final Color background;

  ///Fill of a plain track cell
  final Color trackFill;

  ///Border color of the cell grid lines
  final Color trackBorder;

  ///Fill of the inner yard square inside a home quadrant
  final Color yardFill;

  ///Fill of the shared center cell behind the finish triangles
  final Color centerFill;

  ///Marker color for the safe star cells
  final Color starColor;

  ///Semi transparent grey laid over quadrants whose player is not in the match
  final Color dimmedCorner;

  ///Quadrant color for green, also used for its start and home cells
  final Color green;

  ///Quadrant color for yellow, also used for its start and home cells
  final Color yellow;

  ///Quadrant color for blue, also used for its start and home cells
  final Color blue;

  ///Quadrant color for red, also used for its start and home cells
  final Color red;

  ///Creates a theme from its colors
  const BoardTheme({
    required this.type,
    required this.background,
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

  ///Human readable name of the theme
  String get label => type.label;

  ///Theme tinted color for the quadrant, start cell and home column of [player]
  Color quadrantColor(LudoPlayerType player) {
    switch (player) {
      case LudoPlayerType.green:
        return green;
      case LudoPlayerType.yellow:
        return yellow;
      case LudoPlayerType.blue:
        return blue;
      case LudoPlayerType.red:
        return red;
    }
  }

  ///Returns the built in theme for [type]
  static BoardTheme of(BoardThemeType type) {
    switch (type) {
      case BoardThemeType.classic:
        return const BoardTheme(
          type: BoardThemeType.classic,
          background: Color(0xFFF2F2F4),
          trackFill: Color(0xFFFFFFFF),
          trackBorder: Color(0xFFB9BEC7),
          yardFill: Color(0xFFFFFFFF),
          centerFill: Color(0xFFF2F2F4),
          starColor: Color(0xFF8A9099),
          dimmedCorner: Color(0xB86E7480),
          green: LudoColor.green,
          yellow: LudoColor.yellow,
          blue: LudoColor.blue,
          red: LudoColor.red,
        );
      case BoardThemeType.midnight:
        return const BoardTheme(
          type: BoardThemeType.midnight,
          background: Color(0xFF0C0F1C),
          trackFill: Color(0xFF1B2138),
          trackBorder: Color(0xFF3B4370),
          yardFill: Color(0xFFDCE0EC),
          centerFill: Color(0xFF141A30),
          starColor: Color(0xFF8E97CD),
          dimmedCorner: Color(0xB83A3F4E),
          green: Color(0xFF15942C),
          yellow: Color(0xFFE3B40E),
          blue: Color(0xFF4659C9),
          red: Color(0xFFE0400A),
        );
      case BoardThemeType.pastel:
        return const BoardTheme(
          type: BoardThemeType.pastel,
          background: Color(0xFFF4EFFA),
          trackFill: Color(0xFFFFFFFF),
          trackBorder: Color(0xFFD5CBE6),
          yardFill: Color(0xFFFFFDF7),
          centerFill: Color(0xFFFFFFFF),
          starColor: Color(0xFFAF95D6),
          dimmedCorner: Color(0x998B8798),
          green: Color(0xFF85D49F),
          yellow: Color(0xFFFBE08C),
          blue: Color(0xFFA7B2F0),
          red: Color(0xFFF6A98E),
        );
    }
  }
}
