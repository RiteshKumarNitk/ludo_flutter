import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'round_icon_button.dart';

///Gradient game-table background with a faint dotted pattern
class GameBackground extends StatelessWidget {
  final Widget child;
  const GameBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.background),
      child: CustomPaint(painter: const _DotsPainter(), child: child),
    );
  }
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.035);
    const gap = 26.0;
    for (double y = gap / 2; y < size.height; y += gap) {
      final offset = (y / gap).floor().isEven ? 0.0 : gap / 2;
      for (double x = offset; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
    }
    //Soft glow behind the top of the screen
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        AppColors.secondary.withValues(alpha: 0.22),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: Offset(size.width * 0.5, 0), radius: math.max(size.width, 300)));
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) => false;
}

///Standard screen frame: background, safe area and a game-style top bar
class GameScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget> actions;
  final Widget? bottom;

  ///Shows a back button when the route can pop
  final bool showBack;

  const GameScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions = const [],
    this.bottom,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = showBack && Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (title != null || canPop || actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        if (canPop)
                          RoundIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                            onPressed: () => Navigator.of(context).maybePop(),
                          )
                        else
                          const SizedBox(width: 48),
                        Expanded(
                          child: title == null
                              ? const SizedBox.shrink()
                              : Text(
                                  title!,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.title,
                                ),
                        ),
                        if (actions.isEmpty) const SizedBox(width: 48) else ...actions,
                      ],
                    ),
                  ),
                ),
              Expanded(child: body),
              if (bottom != null) bottom!,
            ],
          ),
        ),
      ),
    );
  }
}
