import 'dart:math';

import 'constants.dart';
import 'game_config.dart';
import 'ludo_player.dart';

///A legal move for the current dice roll, with all metadata the UI and the
///CPU need precomputed. Produced by [Rules.legalMoves] — pure data.
class MoveCandidate {
  ///Pawn seat index of the moving pawn
  final int pawnIndex;

  ///Current step (`-1` while in base)
  final int fromStep;

  ///Final step after the move (inclusive index on the player's path)
  final int toStep;

  ///True when the pawn leaves its base
  final bool fromBase;

  ///True when the landing cell holds at least one enemy pawn off a safe cell
  final bool isCapture;

  ///True when the landing cell is one of the eight safe cells
  final bool landsOnSafe;

  ///True when this landing puts a second pawn of the mover's color on one cell
  final bool formsBlock;

  ///How many enemy pawns could capture this landing on their next roll
  final int threatCount;

  ///True when the pawn reaches the final cell (all four pawns home = win)
  final bool reachesFinish;

  const MoveCandidate({
    required this.pawnIndex,
    required this.fromStep,
    required this.toStep,
    required this.fromBase,
    required this.isCapture,
    required this.landsOnSafe,
    required this.formsBlock,
    required this.threatCount,
    required this.reachesFinish,
  });

  @override
  String toString() =>
      'MoveCandidate(pawn:$pawnIndex $fromStep->$toStep capture:$isCapture safe:$landsOnSafe block:$formsBlock threats:$threatCount finish:$reachesFinish)';
}

///Pure game rules: legality, captures, safety, blocking and CPU decisions.
///No Flutter state — everything here is unit testable.
class Rules {
  const Rules._();

  ///The eight safe cells (four colored start cells + four star cells)
  static bool isSafeCell(List<double> cell) =>
      LudoPath.safeArea.any((safe) => safe[0] == cell[0] && safe[1] == cell[1]);

  ///Final step a pawn must land on for the given roll, or `null` when the
  ///roll is illegal. A pawn already on the final cell can never move.
  ///Leaving base requires a 6 and always lands on the start cell (step 0).
  static int? targetStep(int step, int dice, int pathLength, {required bool exactFinish}) {
    if (step >= pathLength - 1) return null; //already home
    if (step < 0) return dice == 6 ? 0 : null;
    final int raw = step + dice;
    if (raw > pathLength - 1) return exactFinish ? null : pathLength - 1;
    return raw;
  }

  static String _cellKey(List<double> cell) => '${cell[0]}_${cell[1]}';

  ///Map of every on-board pawn's cell to (color, pawnIndex, step)
  static Map<String, List<(LudoPlayerType, int, int)>> occupancy(List<LudoPlayer> players) {
    final Map<String, List<(LudoPlayerType, int, int)>> map = {};
    for (final player in players) {
      for (final pawn in player.pawns) {
        if (pawn.step < 0) continue;
        map.putIfAbsent(_cellKey(player.path[pawn.step]), () => []).add((
          player.type,
          pawn.index,
          pawn.step,
        ));
      }
    }
    return map;
  }

  ///All legal moves for [player] with [dice], honouring exact-finish and
  ///blocking rules. This single function drives pawn highlighting, CPU picks
  ///and legality checks, so the three can never disagree.
  static List<MoveCandidate> legalMoves({
    required LudoPlayer player,
    required int dice,
    required List<LudoPlayer> allPlayers,
    required bool exactFinish,
    required bool blocking,
  }) {
    final int pathLength = player.path.length;
    final occ = occupancy(allPlayers);
    final List<MoveCandidate> moves = [];

    for (final pawn in player.pawns) {
      final int? toStep = targetStep(pawn.step, dice, pathLength, exactFinish: exactFinish);
      if (toStep == null) continue;

      final List<double> landing = player.path[toStep];

      ///Blocking: enemies with 2+ pawns on one cell stop both landing and passing
      if (blocking && _blocked(player, pawn.step, toStep, occ)) continue;

      final bool fromBase = pawn.step < 0;
      final bool safe = isSafeCell(landing);

      ///Captures: enemy pawns on the landing cell, never on a safe cell
      bool capture = false;
      if (!safe) {
        final occupants = occ[_cellKey(landing)] ?? const [];
        capture = occupants.any((o) => o.$1 != player.type);
      }

      ///My own stack on the landing cell becomes a block with this pawn
      final myThere = (occ[_cellKey(landing)] ?? const [])
          .where((o) => o.$1 == player.type && o.$2 != pawn.index)
          .length;
      final bool formsBlock = myThere + 1 >= 2;

      ///Threats: enemy pawns that can reach the landing cell with a 1-6 roll.
      ///Safe landings are never threatened, so the count stays 0 there.
      int threats = 0;
      if (!safe && !fromBase) {
        for (final other in allPlayers) {
          if (other.type == player.type) continue;
          for (final op in other.pawns) {
            if (op.step < 0) continue; //base exits land on a safe start cell
            if (_canReach(other, op.step, landing, dice: 6, exactFinish: exactFinish)) {
              threats++;
            }
          }
        }
      }

      moves.add(MoveCandidate(
        pawnIndex: pawn.index,
        fromStep: pawn.step,
        toStep: toStep,
        fromBase: fromBase,
        isCapture: capture,
        landsOnSafe: safe,
        formsBlock: formsBlock,
        threatCount: threats,
        reachesFinish: toStep == pathLength - 1,
      ));
    }
    return moves;
  }

  ///True when any enemy color holds 2+ pawns on an intermediate or landing cell
  static bool _blocked(
    LudoPlayer player,
    int fromStep,
    int toStep,
    Map<String, List<(LudoPlayerType, int, int)>> occ,
  ) {
    for (int i = fromStep + 1; i <= toStep; i++) {
      final occupants = occ[_cellKey(player.path[i])] ?? const [];
      final byColor = <LudoPlayerType, int>{};
      for (final (color, _, _) in occupants) {
        if (color == player.type) continue;
        byColor[color] = (byColor[color] ?? 0) + 1;
      }
      if (byColor.values.any((count) => count >= 2)) return true;
    }
    return false;
  }

  ///True when the pawn at [step] can land exactly on [cell] within [dice] rolls
  static bool _canReach(
    LudoPlayer player,
    int step,
    List<double> cell, {
    required int dice,
    required bool exactFinish,
  }) {
    final int last = player.path.length - 1;
    for (int k = 1; k <= dice; k++) {
      final int raw = step + k;
      if (raw > last) {
        if (exactFinish) break; //cannot overshoot, later rolls are further away
        if (player.path[last][0] == cell[0] && player.path[last][1] == cell[1]) return true;
        break;
      }
      if (player.path[raw][0] == cell[0] && player.path[raw][1] == cell[1]) return true;
    }
    return false;
  }

  ///Pick the pawn the CPU moves. Returns `null` when [moves] is empty.
  static int? chooseCpuPawn(
    List<MoveCandidate> moves,
    CpuDifficulty difficulty, {
    required int pathLength,
    Random? random,
  }) {
    if (moves.isEmpty) return null;
    final Random rng = random ?? Random();

    switch (difficulty) {
      case CpuDifficulty.easy:
        return moves[rng.nextInt(moves.length)].pawnIndex;

      case CpuDifficulty.medium:
        ///Classic heuristic: race the pawn closest to the finish
        int best = moves.first.toStep;
        for (final move in moves) {
          if (move.toStep > best) best = move.toStep;
        }
        final tied = moves.where((m) => m.toStep == best).toList();
        return tied[rng.nextInt(tied.length)].pawnIndex;

      case CpuDifficulty.hard:
        MoveCandidate? best;
        double bestScore = -double.infinity;
        for (final move in moves) {
          double score = move.toStep.toDouble(); //progress
          if (move.isCapture) score += 1000;
          if (move.reachesFinish) score += 600;
          if (move.landsOnSafe) score += 300;
          if (move.fromBase) score += 250; //get pawns out of the base
          if (move.formsBlock) score += 150;
          score -= move.threatCount * 250; //never walk into capture range
          score += rng.nextDouble(); //tiny random tie-break
          if (score > bestScore) {
            bestScore = score;
            best = move;
          }
        }
        return best?.pawnIndex;
    }
  }

  ///Human-friendly description of what a candidate does (used by tests)
  static String describe(MoveCandidate move) {
    final List<String> tags = [];
    if (move.fromBase) tags.add('leaves base');
    if (move.isCapture) tags.add('capture');
    if (move.landsOnSafe) tags.add('safe');
    if (move.formsBlock) tags.add('block');
    if (move.reachesFinish) tags.add('finish');
    if (move.threatCount > 0) tags.add('${move.threatCount} threats');
    return tags.isEmpty ? 'advance' : tags.join(', ');
  }
}
