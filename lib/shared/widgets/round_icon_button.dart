import 'package:flutter/material.dart';

import '../../core/audio/sound_effects.dart';
import '../../core/theme/app_theme.dart';

///Circular icon button used in top bars
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? color;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 48,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.surface,
      shape: const CircleBorder(side: BorderSide(color: AppColors.outline, width: 1.5)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed == null
            ? null
            : () {
                SoundEffects.play(Sfx.tap);
                onPressed!();
              },
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.5, color: color ?? AppColors.textPrimary),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
