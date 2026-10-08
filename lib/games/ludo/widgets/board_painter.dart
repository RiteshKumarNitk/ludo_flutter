import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/board_geometry.dart';
import '../models/ludo_models.dart';
import 'board_theme.dart';

///Paints the 15x15 board: four base quadrants, the cross-shaped track,
///colored start cells and home columns, the eight safe cells (every one
///marked with a star) and the center home triangles. Quadrants of colors
///that are not playing are dimmed.
class BoardPainter extends CustomPainter {
  final BoardTheme theme;
  final Set<LudoColor> activeColors;

  const BoardPainter({required this.theme, required this.activeColors});

  static final Set<Cell> _trackCells = {
    for (final c in LudoColor.values) ...BoardGeometry.routeOf(c),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final double cell = size.shortestSide / 15;
    final double stroke = math.max(1.0, cell * 0.045);
    final paint = Paint()..isAntiAlias = true;

    paint.color = theme.frame;
    canvas.drawRect(Offset.zero & size, paint);

    for (final color in LudoColor.values) {
      _drawQuadrant(canvas, cell, color);
    }

    //Track cells
    for (final c in _trackCells) {
      final rect = _rect(c, cell);
      paint
        ..style = PaintingStyle.fill
        ..color = _cellColor(c);
      canvas.drawRect(rect, paint);
    }

    //Safe cells: a star on every one of them, light on colored start cells
    for (final c in BoardGeometry.safeCells) {
      final isStart = BoardGeometry.startCells.contains(c);
      paint
        ..style = PaintingStyle.fill
        ..color = isStart ? Colors.white.withValues(alpha: 0.92) : theme.starColor;
      _drawStar(canvas, _rect(c, cell), paint);
    }

    //Direction arrows into each home column
    for (final color in LudoColor.values) {
      _drawEntryArrow(canvas, cell, color);
    }

    //Grid lines
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = theme.trackBorder;
    for (final c in _trackCells) {
      canvas.drawRect(_rect(c, cell), paint);
    }

    _drawCenter(canvas, cell, stroke);

    //Dim unused corners last so they read as inactive
    for (final color in LudoColor.values) {
      if (!activeColors.contains(color)) {
        paint
          ..style = PaintingStyle.fill
          ..color = theme.dimmedCorner;
        canvas.drawRect(_quadrantRect(cell, color), paint);
      }
    }
  }

  Color _cellColor(Cell c) {
    if (BoardGeometry.startCells.contains(c)) {
      return theme.colorOf(LudoColor.values.firstWhere((p) => BoardGeometry.routeOf(p).first == c));
    }
    for (final color in LudoColor.values) {
      final route = BoardGeometry.routeOf(color);
      final idx = route.indexOf(c);
      if (idx > BoardGeometry.lastTrackStep && idx < BoardGeometry.homeStep) return theme.colorOf(color);
    }
    return theme.trackFill;
  }

  void _drawQuadrant(Canvas canvas, double cell, LudoColor color) {
    final quadrant = _quadrantRect(cell, color);
    final base = theme.colorOf(color);
    final paint = Paint()..isAntiAlias = true;
    paint.color = base;
    canvas.drawRect(quadrant, paint);

    //Inner yard
    final yard = RRect.fromRectAndRadius(
      Rect.fromLTWH(quadrant.left + cell, quadrant.top + cell, 4 * cell, 4 * cell),
      Radius.circular(cell * 0.7),
    );
    paint.color = theme.yardFill;
    canvas.drawRRect(yard, paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.08
      ..color = Color.lerp(base, Colors.black, 0.12)!;
    canvas.drawRRect(yard, paint);

    //Base slots
    for (int i = 0; i < BoardGeometry.pawnsPerPlayer; i++) {
      final slot = BoardGeometry.baseSlot(color, i);
      final center = Offset((slot.x + 0.5) * cell, (slot.y + 0.5) * cell);
      paint
        ..style = PaintingStyle.fill
        ..color = base.withValues(alpha: 0.9);
      canvas.drawCircle(center, cell * 0.62, paint);
      paint.color = Colors.white.withValues(alpha: 0.35);
      canvas.drawCircle(center.translate(-cell * 0.12, -cell * 0.14), cell * 0.32, paint);
    }
  }

  void _drawCenter(Canvas canvas, double cell, double stroke) {
    final center = Rect.fromLTWH(6 * cell, 6 * cell, 3 * cell, 3 * cell);
    final apex = center.center;
    final paint = Paint()..isAntiAlias = true;
    void triangle(Offset a, Offset b, LudoColor color) {
      paint
        ..style = PaintingStyle.fill
        ..color = theme.colorOf(color);
      canvas.drawPath(Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(apex.dx, apex.dy)
        ..close(), paint);
    }

    triangle(center.topLeft, center.bottomLeft, LudoColor.green);
    triangle(center.topLeft, center.topRight, LudoColor.yellow);
    triangle(center.topRight, center.bottomRight, LudoColor.blue);
    triangle(center.bottomLeft, center.bottomRight, LudoColor.red);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawLine(center.topLeft, center.bottomRight, paint);
    canvas.drawLine(center.topRight, center.bottomLeft, paint);
    paint.color = theme.trackBorder;
    canvas.drawRect(center, paint);
  }

  ///A small arrow on the track cell where each color turns into its home
  ///column, so players can see where their pawns head
  void _drawEntryArrow(Canvas canvas, double cell, LudoColor color) {
    final route = BoardGeometry.routeOf(color);
    final turn = route[BoardGeometry.lastTrackStep];
    final into = route[BoardGeometry.lastTrackStep + 1];
    final rect = _rect(turn, cell);
    final dir = Offset((into.x - turn.x).toDouble(), (into.y - turn.y).toDouble());
    final c = rect.center;
    final s = cell * 0.26;
    final normal = Offset(-dir.dy, dir.dx);
    final tip = c + dir * s;
    final back = c - dir * s * 0.6;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo((back + normal * s).dx, (back + normal * s).dy)
      ..lineTo((back - normal * s).dx, (back - normal * s).dy)
      ..close();
    canvas.drawPath(path, Paint()..color = theme.colorOf(color));
  }

  void _drawStar(Canvas canvas, Rect rect, Paint paint) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final outer = rect.width * 0.36;
    final inner = outer * 0.46;
    final star = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(cx + r * math.cos(a), cy + r * math.sin(a));
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    star.close();
    canvas.drawPath(star, paint);
  }

  static Rect _rect(Cell c, double cell) => Rect.fromLTWH(c.x * cell, c.y * cell, cell, cell);

  static Rect _quadrantRect(double cell, LudoColor color) {
    final o = BoardGeometry.quadrantOrigin(color);
    return Rect.fromLTWH(o.x * cell, o.y * cell, 6 * cell, 6 * cell);
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.theme.type != theme.type || old.activeColors.length != activeColors.length || !old.activeColors.containsAll(activeColors);
}
