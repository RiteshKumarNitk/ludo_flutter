import 'package:flutter/material.dart';

import '../../core/audio/sound_effects.dart';
import '../../core/theme/app_theme.dart';

///Rounded surface card. Tappable when [onTap] is set.
class GameCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final List<BoxShadow>? shadows;

  const GameCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1.5,
    this.borderRadius = AppRadius.lgAll,
    this.shadows = AppShadows.card,
  });

  @override
  Widget build(BuildContext context) {
    final decorated = Container(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? AppColors.outline, width: borderWidth),
        boxShadow: shadows,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return decorated;
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () {
          SoundEffects.play(Sfx.tap);
          onTap!();
        },
        child: decorated,
      ),
    );
  }
}

///Small uppercase label above a group of controls
class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm, top: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(child: Text(text, style: AppTypography.label)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

///Rounded pill tag, e.g. "COMING SOON" or "BOT"
class TagPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color? textColor;
  const TagPill(this.text, {super.key, this.color = AppColors.surfaceRaised, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.pill),
      child: Text(
        text,
        style: AppTypography.label.copyWith(fontSize: 10, color: textColor ?? AppColors.textPrimary, letterSpacing: 1),
      ),
    );
  }
}
