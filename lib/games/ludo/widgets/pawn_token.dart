import 'dart:math' as math;

import 'package:flutter/material.dart';

///A Ludo pawn drawn as a glossy map-pin. When [selectable] it gently
///bobs with a pulsing ring at its base.
class PawnToken extends StatefulWidget {
  final Color color;
  final bool selectable;
  final bool dimmed;

  const PawnToken({super.key, required this.color, this.selectable = false, this.dimmed = false});

  @override
  State<PawnToken> createState() => _PawnTokenState();
}

class _PawnTokenState extends State<PawnToken> with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(PawnToken oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectable != widget.selectable) _sync();
  }

  void _sync() {
    if (widget.selectable) {
      _pulse ??= AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
      _pulse!.repeat();
    } else {
      _pulse?.stop();
      _pulse?.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulse = _pulse;
    if (pulse == null || !widget.selectable) {
      return CustomPaint(painter: PawnPainter(color: widget.color, dimmed: widget.dimmed));
    }
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) => CustomPaint(
        painter: PawnPainter(color: widget.color, pulse: pulse.value, selectable: true),
      ),
    );
  }
}

class PawnPainter extends CustomPainter {
  final Color color;
  final bool selectable;
  final bool dimmed;

  ///0..1 animation phase while selectable
  final double pulse;

  const PawnPainter({required this.color, this.selectable = false, this.dimmed = false, this.pulse = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final bob = selectable ? -math.sin(pulse * math.pi * 2).abs() * h * 0.08 : 0.0;
    final tip = Offset(cx, h * 0.9);

    //Base shadow / selection ring
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.28);
    canvas.drawOval(Rect.fromCenter(center: tip, width: w * 0.5, height: h * 0.16), shadow);
    if (selectable) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.07
        ..color = Colors.white.withValues(alpha: (1 - pulse) * 0.95);
      final grow = 0.45 + pulse * 0.55;
      canvas.drawOval(Rect.fromCenter(center: tip, width: w * grow * 1.3, height: h * grow * 0.5), ring);
    }

    canvas.save();
    canvas.translate(0, bob);
    final head = Offset(cx, h * 0.4);
    final r = w * 0.33;
    final d = tip.dy - head.dy;
    final phi = math.acos((r / d).clamp(-1.0, 1.0));
    final left = head + Offset(math.cos(math.pi / 2 + phi), math.sin(math.pi / 2 + phi)) * r;
    final body = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..arcTo(Rect.fromCircle(center: head, radius: r), math.pi / 2 + phi, 2 * math.pi - 2 * phi, false)
      ..close();

    final base = dimmed ? Color.lerp(color, Colors.grey, 0.45)! : color;
    final fill = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.6),
        radius: 1.1,
        colors: [Color.lerp(base, Colors.white, 0.35)!, base, Color.lerp(base, Colors.black, 0.3)!],
        stops: const [0, 0.55, 1],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(body, fill);
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, w * 0.05)
        ..color = selectable ? Colors.white : Color.lerp(base, Colors.black, 0.45)!,
    );

    //White face with a colored center
    canvas.drawCircle(head, r * 0.58, Paint()..color = Colors.white);
    canvas.drawCircle(head, r * 0.3, Paint()..color = Color.lerp(base, Colors.black, 0.1)!);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PawnPainter old) =>
      old.color != color || old.selectable != selectable || old.pulse != pulse || old.dimmed != dimmed;
}
