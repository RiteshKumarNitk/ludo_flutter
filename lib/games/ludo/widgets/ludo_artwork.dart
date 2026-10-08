import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/audio/sound_effects.dart';
import '../models/ludo_models.dart';
import 'board_painter.dart';
import 'board_theme.dart';
import 'ludo_dice.dart';
import 'pawn_token.dart';

///Floating mini board with pawns and a dice, for the launcher card
class LudoArtwork extends StatefulWidget {
  final BoardTheme theme;
  final double size;
  const LudoArtwork({super.key, required this.theme, this.size = 150});

  @override
  State<LudoArtwork> createState() => _LudoArtworkState();
}

class _LudoArtworkState extends State<LudoArtwork> with SingleTickerProviderStateMixin {
  late final AnimationController _float =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size * 0.86;
    final cell = s / 15;
    final theme = widget.theme;
    Widget pin(Color color, double x, double y) => Positioned(
          left: x * cell - cell * 0.35,
          top: y * cell - cell * 1.2,
          width: cell * 1.7,
          height: cell * 2.1,
          child: CustomPaint(painter: PawnPainter(color: color)),
        );
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) {
        final t = _float.value * 2 * math.pi;
        return Transform.translate(
          offset: Offset(0, math.sin(t) * 4),
          child: Transform.rotate(angle: -0.08 + math.sin(t) * 0.015, child: child),
        );
      },
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: s,
              height: s,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(cell), boxShadow: AppShadows.board),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cell),
                child: CustomPaint(
                  painter: BoardPainter(theme: theme, activeColors: LudoColor.values.toSet()),
                ),
              ),
            ),
            pin(theme.red, 6.5, 11.5),
            pin(theme.green, 3.5, 6.5),
            pin(theme.yellow, 8.5, 3.5),
            pin(theme.blue, 11.5, 8.5),
            Positioned(
              right: 0,
              bottom: 0,
              child: Transform.rotate(angle: 0.25, child: DiceFace(value: 6, size: s * 0.3, accent: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

///Board theme picker shown in the settings screen
class BoardThemePicker extends StatelessWidget {
  final BoardThemeType selected;
  final ValueChanged<BoardThemeType> onChanged;
  const BoardThemePicker({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final type in BoardThemeType.values) ...[
          if (type.index > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Semantics(
              selected: type == selected,
              button: true,
              label: type.label,
              child: GestureDetector(
                onTap: () {
                  SoundEffects.play(Sfx.tap);
                  onChanged(type);
                },
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: type == selected ? AppColors.surfaceRaised : AppColors.surfaceSunken,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(
                      color: type == selected ? AppColors.primary : AppColors.outline,
                      width: type == selected ? 2.5 : 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: AppRadius.smAll,
                          child: CustomPaint(
                            painter: BoardPainter(theme: BoardTheme.of(type), activeColors: LudoColor.values.toSet()),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        type.label,
                        style: AppTypography.caption.copyWith(
                          color: type == selected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
