import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../engine/board_geometry.dart';
import '../models/ludo_models.dart';
import 'board_painter.dart';
import 'board_theme.dart';
import 'pawn_token.dart';

///What the board needs to know about one pawn
class BoardPawn {
  final LudoColor color;
  final int index;
  final int step;

  ///Arrival order on the current cell; later arrivals stack on top
  final int arrival;
  final bool selectable;

  ///Drawn faded (a pawn of the moving player that cannot move now)
  final bool dimmed;

  const BoardPawn({
    required this.color,
    required this.index,
    required this.step,
    required this.arrival,
    this.selectable = false,
    this.dimmed = false,
  });
}

///The painted board with animated pawns. Purely presentational: it draws
///the steps it is given and animates between them.
class LudoBoard extends StatefulWidget {
  final double size;
  final BoardTheme theme;
  final Set<LudoColor> activeColors;

  ///Color whose turn it is; its base gets a soft glowing outline
  final LudoColor? turnColor;
  final List<BoardPawn> pawns;
  final void Function(LudoColor color, int pawn)? onPawnTap;
  final Duration stepDuration;
  final Duration returnDuration;

  const LudoBoard({
    super.key,
    required this.size,
    required this.theme,
    required this.activeColors,
    required this.pawns,
    this.turnColor,
    this.onPawnTap,
    this.stepDuration = const Duration(milliseconds: 170),
    this.returnDuration = const Duration(milliseconds: 420),
  });

  @override
  State<LudoBoard> createState() => _LudoBoardState();
}

class _LudoBoardState extends State<LudoBoard> with SingleTickerProviderStateMixin {
  late final AnimationController _glow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  double get _cell => widget.size / 15;

  ///Visual box of a pawn standing alone at [step] (or in its base slot)
  Rect _soloRect(LudoColor color, int index, int step) {
    final c = _cell;
    final Offset center;
    if (step < 0) {
      final slot = BoardGeometry.baseSlot(color, index);
      center = Offset((slot.x + 0.5) * c, (slot.y + 0.5) * c);
    } else {
      final cell = BoardGeometry.cellOf(color, step)!;
      center = Offset((cell.x + 0.5) * c, (cell.y + 0.5) * c);
    }
    return _pinBox(center, 1);
  }

  Rect _pinBox(Offset cellCenter, double scale) {
    final w = _cell * 1.05 * scale;
    final h = _cell * 1.3 * scale;
    final bottom = cellCenter.dy + _cell * 0.42 * scale;
    return Rect.fromLTWH(cellCenter.dx - w / 2, bottom - h, w, h);
  }

  static const List<List<Offset>> _stackOffsets = [
    [Offset.zero],
    [Offset(-0.2, 0), Offset(0.2, 0)],
    [Offset(-0.22, 0.12), Offset(0.22, 0.12), Offset(0, -0.14)],
    [Offset(-0.2, -0.12), Offset(0.2, -0.12), Offset(-0.2, 0.15), Offset(0.2, 0.15)],
  ];

  @override
  Widget build(BuildContext context) {
    final c = _cell;

    //Group on-board pawns by cell to lay out stacks
    final Map<Cell, List<BoardPawn>> cells = {};
    for (final p in widget.pawns) {
      if (p.step < 0) continue;
      cells.putIfAbsent(BoardGeometry.cellOf(p.color, p.step)!, () => []).add(p);
    }
    final Map<String, Rect> targets = {};
    final Map<String, int> zOrder = {};
    for (final entry in cells.entries) {
      final group = entry.value..sort((a, b) => a.arrival.compareTo(b.arrival));
      final n = group.length;
      final scale = n == 1 ? 1.0 : (n == 2 ? 0.8 : 0.68);
      final pattern = _stackOffsets[math.min(n, 4) - 1];
      final center = Offset((entry.key.x + 0.5) * c, (entry.key.y + 0.5) * c);
      for (int i = 0; i < n; i++) {
        final o = pattern[i % pattern.length] * c;
        final extra = Offset(0, -(i ~/ 4) * c * 0.12);
        targets[_key(group[i])] = _pinBox(center + o + extra, scale);
        zOrder[_key(group[i])] = i;
      }
    }

    final pawns = [...widget.pawns]..sort((a, b) {
        //Selectable pawns on top so they always receive taps, then by stack order
        if (a.selectable != b.selectable) return a.selectable ? 1 : -1;
        final ya = (targets[_key(a)] ?? _soloRect(a.color, a.index, a.step)).bottom;
        final yb = (targets[_key(b)] ?? _soloRect(b.color, b.index, b.step)).bottom;
        if (ya != yb) return ya.compareTo(yb);
        return (zOrder[_key(a)] ?? 0).compareTo(zOrder[_key(b)] ?? 0);
      });

    final radius = BorderRadius.circular(c * 0.9);
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(borderRadius: radius, boxShadow: AppShadows.board),
              child: ClipRRect(
                borderRadius: radius,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: BoardPainter(theme: widget.theme, activeColors: widget.activeColors),
                  ),
                ),
              ),
            ),
          ),
          if (widget.turnColor != null)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _glow,
                  builder: (context, _) => CustomPaint(
                    painter: _TurnGlowPainter(
                      color: widget.turnColor!,
                      tint: widget.theme.colorOf(widget.turnColor!),
                      t: _glow.value,
                    ),
                  ),
                ),
              ),
            ),
          for (final p in pawns)
                _AnimatedPawn(
                  key: ValueKey(_key(p)),
                  pawn: p,
                  target: targets[_key(p)] ?? _soloRect(p.color, p.index, p.step),
                  pathRect: (step) => _soloRect(p.color, p.index, step),
                  cell: c,
                  color: widget.theme.colorOf(p.color),
                  stepDuration: widget.stepDuration,
                  returnDuration: widget.returnDuration,
                  onTap: p.selectable && widget.onPawnTap != null ? () => widget.onPawnTap!(p.color, p.index) : null,
                ),
        ],
      ),
    );
  }

  static String _key(BoardPawn p) => '${p.color.name}-${p.index}';
}

///Soft pulsing outline around the base of the seat whose turn it is.
///Outline only, so it never covers that player's pawns.
class _TurnGlowPainter extends CustomPainter {
  final LudoColor color;
  final Color tint;
  final double t;
  const _TurnGlowPainter({required this.color, required this.tint, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.shortestSide / 15;
    final o = BoardGeometry.quadrantOrigin(color);
    final rect = Rect.fromLTWH(o.x * cell, o.y * cell, 6 * cell, 6 * cell).deflate(cell * 0.18);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.8));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * (0.16 + 0.08 * t)
        ..color = Colors.white.withValues(alpha: 0.55 + 0.4 * t),
    );
    canvas.drawRRect(
      rrect.inflate(cell * 0.08),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.1
        ..color = Color.lerp(tint, Colors.black, 0.25)!.withValues(alpha: 0.5 + 0.3 * t),
    );
  }

  @override
  bool shouldRepaint(_TurnGlowPainter old) => old.t != t || old.color != color || old.tint != tint;
}

///One pawn that animates between the rects it is given: hopping cell by
///cell along its route when its step increases, sliding home on capture.
class _AnimatedPawn extends StatefulWidget {
  final BoardPawn pawn;
  final Rect target;
  final Rect Function(int step) pathRect;
  final double cell;
  final Color color;
  final Duration stepDuration;
  final Duration returnDuration;
  final VoidCallback? onTap;

  const _AnimatedPawn({
    super.key,
    required this.pawn,
    required this.target,
    required this.pathRect,
    required this.cell,
    required this.color,
    required this.stepDuration,
    required this.returnDuration,
    required this.onTap,
  });

  @override
  State<_AnimatedPawn> createState() => _AnimatedPawnState();
}

class _AnimatedPawnState extends State<_AnimatedPawn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  List<Rect> _frames = const [];
  bool _hop = false;

  @override
  void initState() {
    super.initState();
    _frames = [widget.target];
    _controller.value = 1;
  }

  Rect get _current {
    if (_frames.length == 1) return _frames.first;
    final t = _controller.value;
    final segments = _frames.length - 1;
    final pos = t * segments;
    final i = math.min(pos.floor(), segments - 1);
    final local = pos - i;
    final eased = Curves.easeInOut.transform(local.clamp(0.0, 1.0));
    final rect = Rect.lerp(_frames[i], _frames[i + 1], eased)!;
    if (!_hop || t >= 1) return rect;
    return rect.shift(Offset(0, -math.sin(local * math.pi) * widget.cell * 0.38));
  }

  @override
  void didUpdateWidget(_AnimatedPawn old) {
    super.didUpdateWidget(old);
    final from = old.pawn.step;
    final to = widget.pawn.step;
    if (from == to && old.target == widget.target) return;

    final start = _current;
    List<Rect> frames;
    Duration duration;
    bool hop = true;
    if (to > from && from >= 0) {
      frames = [start, for (int s = from + 1; s < to; s++) widget.pathRect(s), widget.target];
      duration = widget.stepDuration * (to - from);
    } else if (from < 0 && to >= 0) {
      frames = [start, widget.target];
      duration = widget.stepDuration * 1.6;
    } else if (to < 0 && from >= 0) {
      frames = [start, widget.target];
      duration = widget.returnDuration;
      hop = false;
    } else {
      frames = [start, widget.target];
      duration = const Duration(milliseconds: 180);
      hop = false;
    }
    _frames = frames;
    _hop = hop;
    if (duration == Duration.zero) {
      _frames = [widget.target];
      _controller.value = 1;
      return;
    }
    _controller.duration = duration;
    _controller.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted && _controller.value >= 1) _frames = [widget.target];
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final token = PawnToken(color: widget.color, selectable: widget.pawn.selectable, dimmed: widget.pawn.dimmed);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final rect = _current;
        //Generous invisible hit area so small pawns are easy to tap
        final hit = math.max(44.0, rect.width * 1.5);
        return Positioned(
          left: rect.center.dx - hit / 2,
          top: rect.center.dy - hit / 2,
          width: hit,
          height: hit,
          child: IgnorePointer(
            ignoring: widget.onTap == null,
            child: Semantics(
              button: widget.onTap != null,
              label: '${widget.pawn.color.label} pawn ${widget.pawn.index + 1}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                child: Center(child: SizedBox(width: rect.width, height: rect.height, child: token)),
              ),
            ),
          ),
        );
      },
    );
  }
}
