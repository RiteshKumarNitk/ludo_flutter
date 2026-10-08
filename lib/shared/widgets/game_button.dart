import 'package:flutter/material.dart';

import '../../core/audio/sound_effects.dart';
import '../../core/theme/app_theme.dart';

enum GameButtonVariant { primary, secondary, danger, ghost }

///Chunky "3D" game button: a colored face on a darker lip that presses
///down when tapped. Plays the tap sound.
class GameButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final GameButtonVariant variant;
  final bool expand;
  final double height;

  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GameButtonVariant.primary,
    this.expand = true,
    this.height = 58,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _pressed = false;

  (Color face, Color lip, Color text) get _colors {
    switch (widget.variant) {
      case GameButtonVariant.primary:
        return (AppColors.primary, AppColors.primaryDeep, AppColors.onPrimary);
      case GameButtonVariant.secondary:
        return (AppColors.secondary, AppColors.secondaryDeep, AppColors.textPrimary);
      case GameButtonVariant.danger:
        return (AppColors.danger, AppColors.dangerDeep, AppColors.textPrimary);
      case GameButtonVariant.ghost:
        return (AppColors.surfaceRaised, AppColors.surfaceSunken, AppColors.textPrimary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final (face, lip, text) = _colors;
    const lipHeight = 5.0;
    final offset = _pressed ? lipHeight - 1 : 0.0;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: text, size: 24),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.button.copyWith(color: text),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTap: enabled
            ? () {
                SoundEffects.play(Sfx.tap);
                widget.onPressed!();
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: SizedBox(
            height: widget.height,
            width: widget.expand ? double.infinity : null,
            child: Stack(
              children: [
                Positioned.fill(
                  top: lipHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: lip,
                      borderRadius: AppRadius.lgAll,
                      boxShadow: AppShadows.soft,
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 70),
                  left: 0,
                  right: 0,
                  top: offset,
                  bottom: lipHeight - offset,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.lgAll,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.lighten(face, 0.18), face],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Center(child: content),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
