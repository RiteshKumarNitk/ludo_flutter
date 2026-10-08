import '../models/ludo_models.dart';
import '../models/ludo_state.dart';
import 'board_geometry.dart';

///A legal move for the current roll
class LudoMove {
  final LudoColor color;
  final int pawn;
  final int from;
  final int to;

  ///Enemy pawn sent back to base by this move, if any
  final PawnRef? victim;

  const LudoMove({required this.color, required this.pawn, required this.from, required this.to, this.victim});

  bool get leavesBase => from < 0;
  bool get isCapture => victim != null;
  bool get reachesHome => to == BoardGeometry.homeStep;
  bool get landsOnSafe => LudoRules.isSafeStep(color, to);

  @override
  String toString() => 'LudoMove(pawn $pawn: $from -> $to${victim != null ? ', captures ${victim!.color.name}#${victim!.index}' : ''})';
}

///The fixed standard ruleset. Pure functions over [LudoState].
///
///* A pawn leaves its base only on a 6, onto its start cell.
///* Pawns move exactly the rolled number; overshooting home is not allowed.
///* Landing on an opponent outside the eight safe cells sends it home.
///  When several opponents share that cell, the one that arrived last
///  (the top of the stack) is captured. There are no blocks.
class LudoRules {
  const LudoRules._();

  ///Step a pawn at [step] reaches with [dice], or null when it cannot move
  static int? targetStep(int step, int dice) {
    if (dice < 1 || dice > 6) return null;
    if (step >= BoardGeometry.homeStep) return null;
    if (step < 0) return dice == 6 ? 0 : null;
    final to = step + dice;
    return to > BoardGeometry.homeStep ? null : to;
  }

  ///Every legal move of the current seat for the current dice value
  static List<LudoMove> legalMoves(LudoState state) {
    final dice = state.dice;
    if (dice == null || state.phase != LudoPhase.move && state.phase != LudoPhase.roll) {
      return const [];
    }
    return movesFor(state, state.currentColor, dice);
  }

  ///Moves [color] could make with [dice] on the current board
  static List<LudoMove> movesFor(LudoState state, LudoColor color, int dice) {
    final steps = state.stepsOf(color);
    final moves = <LudoMove>[];
    for (int pawn = 0; pawn < steps.length; pawn++) {
      final to = targetStep(steps[pawn], dice);
      if (to == null) continue;
      moves.add(LudoMove(color: color, pawn: pawn, from: steps[pawn], to: to, victim: victimAt(state, color, to)));
    }
    return moves;
  }

  ///Opponent pawn that [color] would capture by landing on [step]
  static PawnRef? victimAt(LudoState state, LudoColor color, int step) {
    if (step > BoardGeometry.lastTrackStep) return null; //home column is private
    final cell = BoardGeometry.cellOf(color, step)!;
    if (BoardGeometry.isSafe(cell)) return null;
    PawnRef? top;
    int topArrival = -1;
    for (final seat in state.seats) {
      if (seat.color == color) continue;
      final steps = state.stepsOf(seat.color);
      final arrivals = state.arrivals[seat.color]!;
      for (int i = 0; i < steps.length; i++) {
        if (steps[i] < 0 || steps[i] > BoardGeometry.lastTrackStep) continue;
        if (BoardGeometry.cellOf(seat.color, steps[i]) != cell) continue;
        if (arrivals[i] > topArrival) {
          topArrival = arrivals[i];
          top = (color: seat.color, index: i);
        }
      }
    }
    return top;
  }

  ///True when the cell [color]'s pawn would occupy at [step] is safe
  static bool isSafeStep(LudoColor color, int step) {
    if (step < 0 || step > BoardGeometry.lastTrackStep) return true;
    return BoardGeometry.isSafe(BoardGeometry.cellOf(color, step)!);
  }

  ///Opponent pawns that could land on [color]'s cell at [step] with one roll
  static int threatsAt(LudoState state, LudoColor color, int step) {
    if (isSafeStep(color, step)) return 0;
    final cell = BoardGeometry.cellOf(color, step)!;
    int threats = 0;
    for (final seat in state.seats) {
      if (seat.color == color || state.ranking.contains(seat.color)) continue;
      for (final enemyStep in state.stepsOf(seat.color)) {
        if (enemyStep < 0 || enemyStep > BoardGeometry.lastTrackStep) continue;
        for (int d = 1; d <= 6; d++) {
          final s = enemyStep + d;
          if (s > BoardGeometry.lastTrackStep) break;
          if (BoardGeometry.cellOf(seat.color, s) == cell) {
            threats++;
            break;
          }
        }
      }
    }
    return threats;
  }
}
