import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

///Khelora brand colors
class KheloraColors {
  const KheloraColors._();

  static const Color navy = Color(0xFF11182B);
  static const Color gold = Color(0xFFF6C453);
  static const Color mint = Color(0xFF4CD7A0);
  static const Color coral = Color(0xFFFF6F78);
  static const Color blue = Color(0xFF6E9BFF);

  ///Tile colors clockwise from the top
  static const List<Color> tiles = [gold, mint, coral, blue];
}

///The Khelora symbol: four game tiles set as diamonds around a shared
///center token. One painter drives the in-app logo, the splash animation
///and the generated launcher icons, so they always match.
///
///[progress] animates the assembly (0 = tiles outside and hidden,
///1 = final logo). [monochrome] paints everything in [monochromeColor]
///(used for Android themed icons).
class KheloraMarkPainter extends CustomPainter {
  final double progress;
  final bool monochrome;
  final Color monochromeColor;

  ///Color behind the center token's separating ring
  final Color ringColor;

  const KheloraMarkPainter({
    this.progress = 1,
    this.monochrome = false,
    this.monochromeColor = Colors.white,
    this.ringColor = KheloraColors.navy,
  });

  ///Geometry in units of the symbol's side
  static const double _tileSide = 0.30;
  static const double _distance = 0.24;
  static const double _corner = 0.07;
  static const double _centerRadius = 0.085;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = size.center(Offset.zero);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(side);

    for (int i = 0; i < 4; i++) {
      //Staggered arrival: each tile starts a little after the previous one
      final local = Curves.easeOutCubic.transform(((progress - i * 0.08) / 0.7).clamp(0.0, 1.0));
      if (local <= 0) continue;
      final angle = -math.pi / 2 + i * math.pi / 2; //N, E, S, W
      final distance = lerpDouble(0.55, _distance, local)!;
      final spin = (1 - local) * math.pi / 2;
      canvas.save();
      canvas.translate(math.cos(angle) * distance, math.sin(angle) * distance);
      canvas.rotate(math.pi / 4 + spin);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: _tileSide, height: _tileSide),
        const Radius.circular(_corner),
      );
      final color = monochrome ? monochromeColor : KheloraColors.tiles[i];
      final paint = Paint()..isAntiAlias = true;
      if (monochrome) {
        paint.color = color.withValues(alpha: local);
      } else {
        paint.shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.28)!, color, Color.lerp(color, Colors.black, 0.12)!],
          stops: const [0, 0.55, 1],
        ).createShader(rect.outerRect);
        paint.color = Colors.white.withValues(alpha: local);
      }
      canvas.drawRRect(rect, paint); //paint alpha fades the shader in
      canvas.restore();
    }

    //Shared center token pops in last
    final token = Curves.easeOutBack.transform(((progress - 0.6) / 0.4).clamp(0.0, 1.0));
    if (token > 0) {
      final r = _centerRadius * token;
      if (!monochrome) {
        canvas.drawCircle(Offset.zero, r + 0.03, Paint()..color = ringColor);
      }
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()..color = monochrome ? monochromeColor : Colors.white,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(KheloraMarkPainter old) =>
      old.progress != progress || old.monochrome != monochrome || old.ringColor != ringColor;
}

///The Khelora symbol as a widget
class KheloraMark extends StatelessWidget {
  final double size;
  final double progress;

  ///Color painted behind the center token (match the surface it sits on)
  final Color ringColor;

  const KheloraMark({super.key, this.size = 48, this.progress = 1, this.ringColor = KheloraColors.navy});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Khelora',
        image: true,
        child: CustomPaint(
          size: Size.square(size),
          painter: KheloraMarkPainter(progress: progress, ringColor: ringColor),
        ),
      );
}

///"Khelora" wordmark with a gold-to-coral accent on the final letter
class KheloraWordmark extends StatelessWidget {
  final double fontSize;
  const KheloraWordmark({super.key, this.fontSize = 40});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Baloo2',
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      fontVariations: const [FontVariation('wght', 800)],
      letterSpacing: fontSize * 0.04,
      height: 1.0,
      color: Colors.white,
    );
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: 'Khelor', style: style),
        TextSpan(text: 'a', style: style.copyWith(color: KheloraColors.gold)),
      ]),
      maxLines: 1,
    );
  }
}
