import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../board_theme.dart';
import '../constants.dart';

///Paints the full 15x15 board: four 6x6 home quadrants with yards and base
///circles, the cross shaped track, the colored start and home cells, the
///safe star markers and the four color center. Quadrants whose color is
///missing from [activePlayers] are covered with the theme's corner dim
///overlay so unused corners read as inactive in 2/3 player matches.
class BoardPainter extends CustomPainter {
  ///Colors used for every element of the board
  final BoardTheme theme;

  ///Colors taking part in the match; every other quadrant is dimmed
  final Set<LudoPlayerType> activePlayers;

  ///Creates a painter for [theme], dimming the quadrants outside [activePlayers]
  BoardPainter({required this.theme, required this.activePlayers});

  ///Route of every player, used to classify the board cells
  static const Map<LudoPlayerType, List<List<double>>> _paths = {
    LudoPlayerType.green: LudoPath.greenPath,
    LudoPlayerType.yellow: LudoPath.yellowPath,
    LudoPlayerType.blue: LudoPath.bluePath,
    LudoPlayerType.red: LudoPath.redPath,
  };

  ///Home slots of every player, the centers of the base circles
  static const Map<LudoPlayerType, List<List<double>>> _homePaths = {
    LudoPlayerType.green: LudoPath.greenHomePath,
    LudoPlayerType.yellow: LudoPath.yellowHomePath,
    LudoPlayerType.blue: LudoPath.blueHomePath,
    LudoPlayerType.red: LudoPath.redHomePath,
  };

  ///Top left cell of each 6x6 quadrant: green top left, yellow top right,
  ///blue bottom right, red bottom left
  static const Map<LudoPlayerType, Offset> _quadrantOrigins = {
    LudoPlayerType.green: Offset.zero,
    LudoPlayerType.yellow: Offset(9, 0),
    LudoPlayerType.blue: Offset(9, 9),
    LudoPlayerType.red: Offset(0, 9),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.shortestSide / 15;
    final double stroke = math.max(1.0, cell * 0.045);
    final Paint paint = Paint()..isAntiAlias = true;

    ///Page background behind the grid
    paint
      ..style = PaintingStyle.fill
      ..color = theme.background;
    canvas.drawRect(Offset.zero & size, paint);

    ///Quadrant bases with yards and base circles, then the inactive corner dim
    for (final LudoPlayerType player in LudoPlayerType.values) {
      _drawQuadrant(canvas, paint, cell, player);
      if (!activePlayers.contains(player)) {
        paint.color = theme.dimmedCorner;
        canvas.drawRect(_quadrantRect(cell, player), paint);
      }
    }

    ///Classify the route cells once: the full track plus the colored start
    ///cells (`path.first` of every player)
    final Set<String> trackCells = <String>{};
    final Map<String, LudoPlayerType> startCells = <String, LudoPlayerType>{};
    for (final MapEntry<LudoPlayerType, List<List<double>>> entry in _paths.entries) {
      for (final List<double> step in entry.value) {
        trackCells.add(_cellKey(step[0], step[1]));
      }
      final List<double> start = entry.value.first;
      startCells[_cellKey(start[0], start[1])] = entry.key;
    }

    ///Track cells: every cell that appears in any player's path
    paint.color = theme.trackFill;
    for (int y = 0; y < 15; y++) {
      for (int x = 0; x < 15; x++) {
        if (trackCells.contains(_cellKey(x, y))) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
        }
      }
    }

    ///Colored cells: home columns and start cells in their player color
    for (int y = 0; y < 15; y++) {
      for (int x = 0; x < 15; x++) {
        final String key = _cellKey(x, y);
        if (!trackCells.contains(key)) {
          continue;
        }
        final LudoPlayerType? colored = startCells[key] ?? _homeOwner(x, y);
        if (colored != null) {
          paint.color = theme.quadrantColor(colored);
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
        }
      }
    }

    ///Star markers on the safe cells that are not colored start cells
    for (final List<double> safe in LudoPath.safeArea) {
      final String key = _cellKey(safe[0], safe[1]);
      if (startCells.containsKey(key)) {
        continue;
      }
      paint.color = theme.starColor;
      _drawStar(
        canvas,
        Rect.fromLTWH(safe[0] * cell, safe[1] * cell, cell, cell),
        paint,
      );
    }

    ///Cell borders so the track reads crisply
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = theme.trackBorder;
    for (int y = 0; y < 15; y++) {
      for (int x = 0; x < 15; x++) {
        if (trackCells.contains(_cellKey(x, y))) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
        }
      }
    }

    ///Shared finish cell: four triangles meeting in the middle. The block
    ///spans the whole 3x3 center so the colored home ends and the corner
    ///cells around them are covered exactly.
    final Rect center = Rect.fromLTWH(6 * cell, 6 * cell, 3 * cell, 3 * cell);
    paint
      ..style = PaintingStyle.fill
      ..color = theme.centerFill;
    canvas.drawRect(center, paint);
    final Offset apex = center.center;
    _triangle(canvas, paint, center.topLeft, center.bottomLeft, apex,
        theme.quadrantColor(LudoPlayerType.green));
    _triangle(canvas, paint, center.topLeft, center.topRight, apex,
        theme.quadrantColor(LudoPlayerType.yellow));
    _triangle(canvas, paint, center.topRight, center.bottomRight, apex,
        theme.quadrantColor(LudoPlayerType.blue));
    _triangle(canvas, paint, center.bottomLeft, center.bottomRight, apex,
        theme.quadrantColor(LudoPlayerType.red));
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = theme.trackBorder;
    canvas.drawRect(center, paint);
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) {
    if (theme.type != oldDelegate.theme.type) {
      return true;
    }
    if (activePlayers.length != oldDelegate.activePlayers.length) {
      return true;
    }
    return !activePlayers.containsAll(oldDelegate.activePlayers);
  }

  ///Draws the 6x6 quadrant of [player] with its inner yard and the four
  ///base circles, centered where the pawns sit in their home slots
  void _drawQuadrant(Canvas canvas, Paint paint, double cell, LudoPlayerType player) {
    final Rect quadrant = _quadrantRect(cell, player);
    final Color color = theme.quadrantColor(player);
    paint
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawRect(quadrant, paint);

    ///Inner yard square
    final RRect yard = RRect.fromRectAndRadius(
      Rect.fromLTWH(quadrant.left + cell, quadrant.top + cell, 4 * cell, 4 * cell),
      Radius.circular(cell * 0.5),
    );
    paint.color = theme.yardFill;
    canvas.drawRRect(yard, paint);

    ///Base circle outlines
    final Paint circle = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, cell * 0.07)
      ..color = color;
    for (final List<double> slot in _homePaths[player]!) {
      final Offset center = Offset((slot[0] + 0.5) * cell, (slot[1] + 0.5) * cell);
      canvas.drawCircle(center, cell * 0.36, circle);
    }
  }

  ///Draws a five point star filling the middle of [rect]
  void _drawStar(Canvas canvas, Rect rect, Paint paint) {
    final double cx = rect.center.dx;
    final double cy = rect.center.dy;
    final double outer = rect.width * 0.38;
    final double inner = outer * 0.45;
    final Path star = Path();
    for (int i = 0; i < 10; i++) {
      final double radius = i.isEven ? outer : inner;
      final double angle = -math.pi / 2 + i * math.pi / 5;
      final double dx = cx + radius * math.cos(angle);
      final double dy = cy + radius * math.sin(angle);
      if (i == 0) {
        star.moveTo(dx, dy);
      } else {
        star.lineTo(dx, dy);
      }
    }
    star.close();
    paint.style = PaintingStyle.fill;
    canvas.drawPath(star, paint);
  }

  ///Fills the triangle built from [a], [b] and [apex] with [color]
  void _triangle(Canvas canvas, Paint paint, Offset a, Offset b, Offset apex, Color color) {
    paint
      ..style = PaintingStyle.fill
      ..color = color;
    final Path path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(apex.dx, apex.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  ///The 6x6 cell rectangle of [player]'s home quadrant
  static Rect _quadrantRect(double cell, LudoPlayerType player) {
    final Offset origin = _quadrantOrigins[player]!;
    return Rect.fromLTWH(origin.dx * cell, origin.dy * cell, 6 * cell, 6 * cell);
  }

  ///Owner of the home column cell at [x],[y], or null when the cell belongs
  ///to no home column. The columns lie on the middle row/column and run from
  ///the board edge to the shared center: green west, yellow north,
  ///blue east, red south.
  static LudoPlayerType? _homeOwner(int x, int y) {
    if (y == 7 && x < 7) {
      return LudoPlayerType.green;
    }
    if (x == 7 && y < 7) {
      return LudoPlayerType.yellow;
    }
    if (y == 7 && x > 7) {
      return LudoPlayerType.blue;
    }
    if (x == 7 && y > 7) {
      return LudoPlayerType.red;
    }
    return null;
  }

  ///String key of the whole number cell containing ([x],[y])
  static String _cellKey(num x, num y) => '${x.toInt()}_${y.toInt()}';
}
