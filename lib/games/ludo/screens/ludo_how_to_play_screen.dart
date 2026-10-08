import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/game_scaffold.dart';
import '../data/ludo_preferences.dart';
import '../widgets/board_theme.dart';
import '../widgets/ludo_dice.dart';
import '../widgets/pawn_token.dart';

///The fixed rules, each with a small illustration drawn from the same
///widgets as the board so the explanation always matches what you see.
class LudoHowToPlayScreen extends StatelessWidget {
  const LudoHowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<LudoPreferences>().theme;
    return GameScaffold(
      title: AppStrings.of(context).howToPlay,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
        children: [
          _Rule(
            art: Row(mainAxisSize: MainAxisSize.min, children: [
              for (final c in [theme.red, theme.green, theme.yellow, theme.blue]) _Pin(color: c, size: 26),
            ]),
            title: 'Race all four pawns home',
            body: 'Move your four pawns around the board and into your colored home column. '
                'The first player to bring all four into the center wins.',
          ),
          _Rule(
            art: const Row(mainAxisSize: MainAxisSize.min, children: [
              DiceFace(value: 6, size: 40),
              Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted),
            ]),
            artTrailing: _StartCell(theme: theme),
            title: 'Roll a 6 to start',
            body: 'A pawn leaves its base only on a 6 and enters on your colored start cell.',
          ),
          const _Rule(
            art: Row(mainAxisSize: MainAxisSize.min, children: [
              DiceFace(value: 4, size: 40),
            ]),
            title: 'Move exactly what you roll',
            body: 'Tap the dice, then tap one of your glowing pawns. Only pawns that can legally '
                'move glow. If just one move is possible it is played for you.',
          ),
          const _Rule(
            art: Row(mainAxisSize: MainAxisSize.min, children: [
              DiceFace(value: 6, size: 34),
              SizedBox(width: 4),
              Icon(Icons.replay_rounded, color: AppColors.primary),
            ]),
            title: 'Six rolls again',
            body: 'Every 6 gives you another roll after your move.',
          ),
          const _Rule(
            art: Row(mainAxisSize: MainAxisSize.min, children: [
              DiceFace(value: 6, size: 26),
              SizedBox(width: 2),
              DiceFace(value: 6, size: 26),
              SizedBox(width: 2),
              _CrossedDice(),
            ]),
            title: 'Three sixes in a row',
            body: 'A third 6 in a row is cancelled and your turn ends. '
                'Moves you made with the first two sixes stay.',
          ),
          _Rule(
            art: Stack(clipBehavior: Clip.none, children: [
              _Pin(color: theme.blue, size: 30),
              Positioned(left: 16, top: -6, child: _Pin(color: theme.red, size: 30)),
            ]),
            title: 'Capture and roll again',
            body: 'Land on an opponent outside a safe cell to send it back to its base. '
                'Capturing gives you an extra roll. If several opponents share that cell, '
                'only the top one is captured.',
          ),
          _Rule(
            art: Row(mainAxisSize: MainAxisSize.min, children: [
              _StartCell(theme: theme),
              const SizedBox(width: AppSpacing.sm),
              _StarCell(theme: theme),
            ]),
            title: '8 safe cells',
            body: 'Every cell marked with a star is safe: the four colored start cells and the '
                'four star cells on the track. Pawns there cannot be captured.',
          ),
          _Rule(
            art: Row(mainAxisSize: MainAxisSize.min, children: [
              _Pin(color: theme.green, size: 26),
              _Pin(color: theme.green, size: 26),
            ]),
            title: 'No blocks',
            body: 'Any number of pawns may share a cell, and pawns can always pass each other.',
          ),
          _Rule(
            art: _HomeColumn(color: theme.red),
            title: 'Exact roll to finish',
            body: 'The arrow shows where your pawns turn into your home column. Reaching the '
                'center needs the exact number; a pawn that would overshoot cannot move.',
          ),
          const _Rule(
            art: Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 40),
            title: 'Winning',
            body: 'All four pawns home wins. With 3 or 4 players the game continues until the '
                'remaining places are decided.',
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  final Widget art;
  final Widget? artTrailing;
  final String title;
  final String body;
  const _Rule({required this.art, this.artTrailing, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GameCard(
        shadows: null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 84,
              height: 64,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.surfaceSunken, borderRadius: AppRadius.mdAll),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [art, if (artTrailing != null) artTrailing!]),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.subtitle),
                  const SizedBox(height: AppSpacing.xs),
                  Text(body, style: AppTypography.body.copyWith(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  final Color color;
  final double size;
  const _Pin({required this.color, required this.size});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size * 1.25, child: CustomPaint(painter: PawnPainter(color: color)));
}

class _Cell extends StatelessWidget {
  final Color fill;
  final Color star;
  const _Cell({required this.fill, required this.star});

  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: fill, border: Border.all(color: const Color(0xFFC9CDD8), width: 1.5)),
        child: Icon(Icons.star_rounded, color: star, size: 26),
      );
}

class _StartCell extends StatelessWidget {
  final BoardTheme theme;
  const _StartCell({required this.theme});

  @override
  Widget build(BuildContext context) => _Cell(fill: theme.red, star: Colors.white);
}

class _StarCell extends StatelessWidget {
  final BoardTheme theme;
  const _StarCell({required this.theme});

  @override
  Widget build(BuildContext context) => _Cell(fill: theme.trackFill, star: theme.starColor);
}

class _CrossedDice extends StatelessWidget {
  const _CrossedDice();

  @override
  Widget build(BuildContext context) => const Stack(alignment: Alignment.center, children: [
        Opacity(opacity: 0.5, child: DiceFace(value: 6, size: 26)),
        Icon(Icons.close_rounded, color: AppColors.danger, size: 30),
      ]);
}

class _HomeColumn extends StatelessWidget {
  final Color color;
  const _HomeColumn({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.arrow_upward_rounded, color: color, size: 20),
      for (int i = 0; i < 3; i++)
        Container(
          width: 16,
          height: 26,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
      const SizedBox(width: 2),
      Icon(Icons.flag_rounded, color: color, size: 22),
    ]);
  }
}
