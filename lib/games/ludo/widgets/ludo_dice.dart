import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/pulse_glow.dart';

///Interactive dice. Tumbles while [rolling], pops on a six and pulses in
///the player's color when it is waiting to be rolled.
class LudoDice extends StatefulWidget {
  final int? value;
  final bool rolling;
  final bool canRoll;
  final Color color;
  final VoidCallback? onRoll;
  final double size;

  const LudoDice({
    super.key,
    required this.value,
    required this.rolling,
    required this.canRoll,
    required this.color,
    this.onRoll,
    this.size = 56,
  });

  @override
  State<LudoDice> createState() => _LudoDiceState();
}

class _LudoDiceState extends State<LudoDice> with TickerProviderStateMixin {
  late final AnimationController _tumble =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final AnimationController _pop =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  final math.Random _random = math.Random();
  int _face = 6;

  @override
  void initState() {
    super.initState();
    _face = widget.value ?? 6;
    _tumble.addListener(_shuffleFace);
    if (widget.rolling) _tumble.repeat();
  }

  void _shuffleFace() {
    final next = 1 + _random.nextInt(6);
    if (next != _face && (_tumble.value * 10).floor().isEven) setState(() => _face = next);
  }

  @override
  void didUpdateWidget(LudoDice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rolling && !_tumble.isAnimating) {
      _tumble.repeat();
    } else if (!widget.rolling && _tumble.isAnimating) {
      _tumble.stop();
      _tumble.value = 0;
    }
    if (!widget.rolling && widget.value != null && (oldWidget.rolling || oldWidget.value != widget.value)) {
      _face = widget.value!;
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _tumble.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSix = !widget.rolling && widget.value == 6;
    final dice = AnimatedBuilder(
      animation: Listenable.merge([_tumble, _pop]),
      builder: (context, _) {
        final spin = widget.rolling ? math.sin(_tumble.value * math.pi * 2) * 0.5 : 0.0;
        final popScale = 1 + math.sin(_pop.value * math.pi) * (isSix ? 0.28 : 0.12);
        return Transform.rotate(
          angle: spin,
          child: Transform.scale(
            scale: popScale,
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _DicePainter(
                value: widget.rolling ? _face : (widget.value ?? 0),
                accent: widget.color,
                glow: isSix,
                faded: !widget.rolling && widget.value == null,
              ),
            ),
          ),
        );
      },
    );

    return Semantics(
      button: widget.canRoll,
      label: widget.rolling
          ? 'Rolling dice'
          : widget.value == null
              ? 'Dice, tap to roll'
              : 'Dice shows ${widget.value}',
      child: GestureDetector(
        onTap: widget.canRoll ? widget.onRoll : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox.square(
          dimension: widget.size,
          child: PulseGlow(
            active: widget.canRoll,
            color: widget.color,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(widget.size * 0.28),
            spread: 0.3,
            child: dice,
          ),
        ),
      ),
    );
  }
}

class _DicePainter extends CustomPainter {
  final int value;
  final Color accent;
  final bool glow;
  final bool faded;

  const _DicePainter({required this.value, required this.accent, required this.glow, required this.faded});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(size.width * 0.04), Radius.circular(size.width * 0.24));
    if (glow) {
      canvas.drawRRect(
        rrect.inflate(size.width * 0.06),
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.7)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.12),
      );
    }
    //Bottom edge for depth
    canvas.drawRRect(rrect.shift(Offset(0, size.height * 0.06)), Paint()..color = const Color(0xFFB7B2D6));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFE9E6F7)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.05
        ..color = glow ? AppColors.gold : accent,
    );

    //Not rolled yet this turn: faint pips in the player's color
    final pip = Paint()
      ..color = value < 1
          ? accent.withValues(alpha: faded ? 0.3 : 0.45)
          : (value == 6 && glow ? const Color(0xFFD32F2F) : AppColors.textOnLight);
    final r = size.width * 0.085;
    const layouts = {
      1: [(0.5, 0.5)],
      2: [(0.28, 0.28), (0.72, 0.72)],
      3: [(0.28, 0.28), (0.5, 0.5), (0.72, 0.72)],
      4: [(0.28, 0.28), (0.72, 0.28), (0.28, 0.72), (0.72, 0.72)],
      5: [(0.28, 0.28), (0.72, 0.28), (0.5, 0.5), (0.28, 0.72), (0.72, 0.72)],
      6: [(0.28, 0.25), (0.72, 0.25), (0.28, 0.5), (0.72, 0.5), (0.28, 0.75), (0.72, 0.75)],
    };
    for (final (x, y) in layouts[value < 1 ? 5 : value]!) {
      canvas.drawCircle(Offset(size.width * x, size.height * y), value == 1 ? r * 1.5 : r, pip);
    }
  }

  @override
  bool shouldRepaint(_DicePainter old) =>
      old.value != value || old.accent != accent || old.glow != glow || old.faded != faded;
}

///Static dice face used in illustrations
class DiceFace extends StatelessWidget {
  final int value;
  final double size;
  final Color accent;
  const DiceFace({super.key, required this.value, this.size = 40, this.accent = AppColors.secondary});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _DicePainter(value: value, accent: accent, glow: false, faded: false),
      );
}
