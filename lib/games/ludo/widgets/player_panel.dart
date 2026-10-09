import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/game_card.dart';
import '../models/ludo_models.dart';

///Where a seat's four pawns are
class PawnProgress {
  final int home;
  final int onBoard;
  const PawnProgress({required this.home, required this.onBoard});

  int get inBase => 4 - home - onBoard;
}

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
  final PawnProgress progress;

  ///Shown instead of the progress once the seat has finished
  final String? placeLabel;
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
    required this.progress,
    required this.dice,
    this.placeLabel,
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
        child: active
            ? KeyedSubtree(key: const ValueKey('dice'), child: dice)
            : _Avatar(key: const ValueKey('avatar'), seat: seat, color: color, place: place),
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
            style: AppTypography.subtitle.copyWith(fontSize: height >= 72 ? 15.5 : 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          if (placeLabel != null)
            Text(
              placeLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(fontSize: 11.5, color: AppColors.gold),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: mirrored ? Alignment.centerRight : Alignment.centerLeft,
              child: _ProgressPips(progress: progress, color: color, mirrored: mirrored),
            ),
        ],
      ),
    );

    return Semantics(
      label: '$displayName${seat.isBot ? ', bot' : ''}, ${progress.home} of 4 pawns home${active ? ', playing now' : ''}',
      child: AnimatedContainer(
        duration: AppMotion.normal,
        curve: Curves.easeOut,
        height: height,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgAll,
          gradient: active
              ? LinearGradient(
                  begin: mirrored ? Alignment.centerRight : Alignment.centerLeft,
                  end: mirrored ? Alignment.centerLeft : Alignment.centerRight,
                  colors: [color.withValues(alpha: 0.5), AppColors.surface],
                )
              : null,
          color: active ? null : AppColors.surface.withValues(alpha: 0.75),
          border: Border.all(color: active ? color : AppColors.outline, width: active ? 2.5 : 1.5),
          boxShadow: active ? AppShadows.glow(color, strength: 0.7) : null,
        ),
        child: Row(
          children: mirrored
              ? [text, const SizedBox(width: AppSpacing.sm), slot]
              : [slot, const SizedBox(width: AppSpacing.sm), text],
        ),
      ),
    );
  }
}

///Four pips: filled = home, ring = on the board, faint = still in base
class _ProgressPips extends StatelessWidget {
  final PawnProgress progress;
  final Color color;
  final bool mirrored;
  const _ProgressPips({required this.progress, required this.color, required this.mirrored});

  @override
  Widget build(BuildContext context) {
    Widget pip(int i) {
      final home = i < progress.home;
      final onBoard = !home && i < progress.home + progress.onBoard;
      return Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: home ? color : (onBoard ? Colors.transparent : AppColors.surfaceSunken),
          border: Border.all(
            color: home ? Colors.white : (onBoard ? color : AppColors.outline),
            width: home ? 1.5 : 2,
          ),
        ),
      );
    }

    final pips = [for (int i = 0; i < 4; i++) pip(i)];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...(mirrored ? pips.reversed : pips),
        const SizedBox(width: 5),
        Text('${progress.home}/4', style: AppTypography.caption.copyWith(fontSize: 11.5)),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
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
              //Scale down rather than cut off the instruction on narrow phones
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(children: [
                  TextSpan(text: title.toUpperCase(), style: AppTypography.label.copyWith(color: AppColors.textPrimary, fontSize: 13.5)),
                  TextSpan(text: '  ·  $hint', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 14)),
                  ]),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
