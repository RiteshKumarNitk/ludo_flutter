import 'dart:math';

import '../models/ludo_models.dart';
import '../models/ludo_state.dart';
import 'ludo_rules.dart';

///Computer opponent. It only ever chooses among [LudoRules.legalMoves], so
///it follows exactly the same rules as a human seat.
class LudoBot {
  const LudoBot._();

  ///Pawn index to move, or null when there is no legal move
  static int? choosePawn(LudoState state, BotDifficulty difficulty, Random random) {
    final moves = LudoRules.legalMoves(state);
    if (moves.isEmpty) return null;
    switch (difficulty) {
      case BotDifficulty.easy:
        //Any legal pawn
        return moves[random.nextInt(moves.length)].pawn;
      case BotDifficulty.medium:
        //Race the pawn that ends up furthest along
        final best = moves.map((m) => m.to).reduce(max);
        final tied = moves.where((m) => m.to == best).toList();
        return tied[random.nextInt(tied.length)].pawn;
      case BotDifficulty.hard:
        LudoMove? best;
        double bestScore = -double.infinity;
        for (final move in moves) {
          final score = _score(state, move) + random.nextDouble(); //tie-break
          if (score > bestScore) {
            bestScore = score;
            best = move;
          }
        }
        return best!.pawn;
    }
  }

  ///Hard bot evaluation: captures, getting home, safety and danger
  static double _score(LudoState state, LudoMove move) {
    double score = move.to.toDouble(); //progress
    if (move.isCapture) score += 1000;
    if (move.reachesHome) score += 600;
    if (move.leavesBase) score += 250;
    if (move.landsOnSafe) score += 200;
    final dangerAfter = LudoRules.threatsAt(state, move.color, move.to);
    score -= dangerAfter * 250;
    if (!move.leavesBase) {
      //Reward escaping from a threatened cell
      final dangerBefore = LudoRules.threatsAt(state, move.color, move.from);
      score += dangerBefore * 120;
    }
    return score;
  }
}
