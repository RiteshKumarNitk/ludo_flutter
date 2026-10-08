import 'package:flutter/material.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/l10n/app_strings.dart';

///Rules of the game.
///
///The bar title goes through [AppStrings]; the article body below is
///long-form English content and migrates together with a future locale.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(AppStrings.of(context).howToPlay),
          backgroundColor: Colors.transparent),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: const [
            _Section(
              title: 'Objective',
              body: 'Be the first player to bring all four of your pawns from your base to the '
                  'finish square in the middle of the board.',
            ),
            _Section(
              title: 'Getting started',
              body: 'A pawn leaves your base only when you roll a 6. Roll the dice by tapping it, '
                  'then tap a highlighted pawn to move it.',
            ),
            _Section(
              title: 'Moving',
              body: 'Your pawn moves as many cells forward as the number you rolled. '
                  'A pawn already on the board moves with every roll, not just on a 6.',
            ),
            _Section(
              title: 'Rolling a 6',
              body: 'Rolling a 6 lets you roll again after your move (can be turned off in the '
                  'game setup) and is the only way to bring a new pawn out of your base.',
            ),
            _Section(
              title: 'Capturing',
              body: 'Land on a cell occupied by an opponent\'s pawn to send that pawn back to its '
                  'base. Capturing lets you roll again.',
            ),
            _Section(
              title: 'Safe cells',
              body: 'Cells marked with a star (the colored start cells and the four arrow cells) '
                  'are safe: pawns standing there cannot be captured.',
            ),
            _Section(
              title: 'Winning',
              body: 'The first player with all four pawns in the finish square wins. In a 2 or 3 '
                  'player game the match ends as soon as all but one player has finished.',
            ),
            _Section(
              title: 'Tips',
              body: 'Roll a 6 to free a trapped pawn, keep a pawn on safe cells when you are '
                  'leading, and race the pawn closest to the finish when you are behind.',
            ),
            SizedBox(height: 16),
            _ColorLegend(),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ColorLegend extends StatelessWidget {
  const _ColorLegend();

  @override
  Widget build(BuildContext context) {
    const entries = [
      (LudoColor.green, 'Green'),
      (LudoColor.yellow, 'Yellow'),
      (LudoColor.blue, 'Blue'),
      (LudoColor.red, 'Red'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final (color, label) in entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }
}
