import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/game_card.dart';
import '../models/ludo_models.dart';

///Corner card for one seat. While it is that seat's turn the panel lights
///up in the seat color and its avatar slot turns into the dice, so the
///dice always sits right next to the player who rolls it.
class PlayerPanel extends StatelessWidget {
  final LudoSeat seat;
  final String displayName;
  final Color color;
  final bool active;

  ///Right-hand panels mirror their layout so the dice sits at the outer edge
  final bool mirrored;
  final String status;
  final int? place;
  final Widget dice;
  final double height;

  const PlayerPanel({
    super.key,
    required this.seat,
    required this.displayName,
    required this.color,
    required this.active,
    required this.mirrored,
    required this.status,
    required this.dice,
    this.place,
    this.height = 64,
  });

  @override
  Widget build(BuildContext context) {
    final slot = SizedBox.square(
      dimension: height - 14,
      child: AnimatedSwitcher(
        duration: AppMotion.normal,
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: active ? KeyedSubtree(key: const ValueKey('dice'), child: dice) : _Avatar(key: const ValueKey('avatar'), seat: seat, color: color, place: place),
      ),
    );
    final text = Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: mirrored ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.subtitle.copyWith(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontSize: 11.5,
              color: active ? AppColors.lighten(color, 0.35) : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );

    return AnimatedContainer(
      duration: AppMotion.normal,
      curve: Curves.easeOut,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        gradient: active
            ? LinearGradient(
                begin: mirrored ? Alignment.centerRight : Alignment.centerLeft,
                end: mirrored ? Alignment.centerLeft : Alignment.centerRight,
                colors: [color.withValues(alpha: 0.45), AppColors.surface],
              )
            : null,
        color: active ? null : AppColors.surface.withValues(alpha: 0.7),
        border: Border.all(color: active ? color : AppColors.outline, width: active ? 2.5 : 1.5),
        boxShadow: active ? AppShadows.glow(color, strength: 0.7) : null,
      ),
      child: Row(
        children: mirrored
            ? [text, const SizedBox(width: AppSpacing.sm), slot]
            : [slot, const SizedBox(width: AppSpacing.sm), text],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final LudoSeat seat;
  final Color color;
  final int? place;
  const _Avatar({super.key, required this.seat, required this.color, this.place});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.lighten(color, 0.25), color], center: const Alignment(-0.3, -0.4)),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(seat.isBot ? Icons.smart_toy_rounded : Icons.person_rounded, color: Colors.white, size: 24),
          ),
        ),
        if (place != null)
          Positioned(
            right: -6,
            bottom: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: place == 1 ? AppColors.gold : AppColors.surfaceRaised,
                borderRadius: AppRadius.pill,
                border: Border.all(color: AppColors.backgroundBottom, width: 1.5),
              ),
              child: Text(
                '#$place',
                style: AppTypography.label.copyWith(
                  fontSize: 10,
                  letterSpacing: 0,
                  color: place == 1 ? AppColors.onPrimary : AppColors.textPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

///Pill under the board announcing whose turn it is and what to do
class TurnStatus extends StatelessWidget {
  final Color color;
  final String title;
  final String hint;
  const TurnStatus({super.key, required this.color, required this.title, required this.hint});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.normal,
      child: GameCard(
        key: ValueKey('$title|$hint'),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        borderRadius: AppRadius.pill,
        borderColor: color.withValues(alpha: 0.8),
        shadows: null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: title.toUpperCase(), style: AppTypography.label.copyWith(color: AppColors.textPrimary, fontSize: 12.5)),
                  TextSpan(text: '  ·  $hint', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
