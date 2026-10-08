import '../models/ludo_models.dart';
import '../models/ludo_state.dart';
import 'board_geometry.dart';
import 'ludo_rules.dart';

///Something that happened while applying an action. The controller turns
///events into animation, sound and haptics; the engine never does.
sealed class LudoEvent {
  const LudoEvent();
}

class DiceRolled extends LudoEvent {
  final LudoColor color;
  final int value;
  const DiceRolled(this.color, this.value);
}

///The current seat cannot move with the rolled value
class NoLegalMove extends LudoEvent {
  final LudoColor color;
  const NoLegalMove(this.color);
}

///The third consecutive six was cancelled and the turn ends
class ThreeSixesForfeited extends LudoEvent {
  final LudoColor color;
  const ThreeSixesForfeited(this.color);
}

class PawnMoved extends LudoEvent {
  final LudoColor color;
  final int pawn;
  final int from;
  final int to;
  const PawnMoved(this.color, this.pawn, this.from, this.to);
}

class PawnCaptured extends LudoEvent {
  final LudoColor by;
  final PawnRef victim;

  ///Step the victim stood on before it was sent home
  final int victimStep;
  const PawnCaptured(this.by, this.victim, this.victimStep);
}

class PawnReachedHome extends LudoEvent {
  final LudoColor color;
  final int pawn;
  const PawnReachedHome(this.color, this.pawn);
}

class PlayerFinished extends LudoEvent {
  final LudoColor color;
  final int place;
  const PlayerFinished(this.color, this.place);
}

enum ExtraRollReason { six, capture }

class ExtraRollGranted extends LudoEvent {
  final LudoColor color;
  final ExtraRollReason reason;
  const ExtraRollGranted(this.color, this.reason);
}

class TurnPassed extends LudoEvent {
  final LudoColor from;
  final LudoColor to;
  const TurnPassed(this.from, this.to);
}

class MatchFinished extends LudoEvent {
  final List<LudoColor> ranking;
  const MatchFinished(this.ranking);
}

///The next state plus what happened on the way there
class LudoStep {
  final LudoState state;
  final List<LudoEvent> events;
  const LudoStep(this.state, this.events);
}

///Thrown when an action breaks the rules (wrong phase, illegal pawn, ...)
class LudoRuleViolation implements Exception {
  final String message;
  const LudoRuleViolation(this.message);

  @override
  String toString() => 'LudoRuleViolation: $message';
}

///Pure Ludo engine: (state, action) → next state + events.
///
///It validates every action, has no timers, randomness, audio, storage or
///Flutter dependencies, and never mutates its input.
class LudoEngine {
  const LudoEngine._();

  static LudoState start(List<LudoSeat> seats) {
    if (seats.length < 2 || seats.length > 4) {
      throw const LudoRuleViolation('Ludo needs 2 to 4 seats');
    }
    if (seats.map((s) => s.color).toSet().length != seats.length) {
      throw const LudoRuleViolation('Every seat needs its own color');
    }
    final stats = {for (final s in seats) s.color: const SeatStats()};
    stats[seats.first.color] = const SeatStats(turns: 1);
    return LudoState(
      seats: List.unmodifiable(seats),
      steps: Map.unmodifiable({for (final s in seats) s.color: List<int>.unmodifiable(List.filled(4, -1))}),
      arrivals: Map.unmodifiable({for (final s in seats) s.color: List<int>.unmodifiable(List.filled(4, 0))}),
      turn: 0,
      dice: null,
      phase: LudoPhase.roll,
      sixStreak: 0,
      ranking: const [],
      stats: Map.unmodifiable(stats),
      moveCount: 0,
    );
  }

  ///Apply a dice roll of [value] for the current seat
  static LudoStep roll(LudoState state, int value) {
    if (state.phase != LudoPhase.roll) {
      throw LudoRuleViolation('Cannot roll during ${state.phase.name}');
    }
    if (value < 1 || value > 6) throw LudoRuleViolation('Invalid dice value $value');

    final color = state.currentColor;
    final streak = value == 6 ? state.sixStreak + 1 : 0;
    final stats = Map.of(state.stats);
    if (value == 6) stats[color] = stats[color]!.copyWith(sixes: stats[color]!.sixes + 1);

    final events = <LudoEvent>[DiceRolled(color, value)];
    var next = state.copyWith(dice: () => value, sixStreak: streak, stats: Map.unmodifiable(stats));

    if (streak >= 3) {
      events.add(ThreeSixesForfeited(color));
      return LudoStep(next.copyWith(phase: LudoPhase.turnOver), events);
    }

    final moves = LudoRules.movesFor(next, color, value);
    if (moves.isEmpty) {
      events.add(NoLegalMove(color));
      if (value == 6) {
        events.add(ExtraRollGranted(color, ExtraRollReason.six));
        return LudoStep(next.copyWith(phase: LudoPhase.roll), events);
      }
      return LudoStep(next.copyWith(phase: LudoPhase.turnOver), events);
    }
    return LudoStep(next.copyWith(phase: LudoPhase.move), events);
  }

  ///Move [pawn] of the current seat with the rolled value
  static LudoStep move(LudoState state, int pawn) {
    if (state.phase != LudoPhase.move) {
      throw LudoRuleViolation('Cannot move during ${state.phase.name}');
    }
    final color = state.currentColor;
    LudoMove? chosen;
    for (final m in LudoRules.legalMoves(state)) {
      if (m.pawn == pawn) chosen = m;
    }
    if (chosen == null) throw LudoRuleViolation('Pawn $pawn of ${color.name} has no legal move');

    final moveCount = state.moveCount + 1;
    final steps = {for (final e in state.steps.entries) e.key: List.of(e.value)};
    final arrivals = {for (final e in state.arrivals.entries) e.key: List.of(e.value)};
    final stats = Map.of(state.stats);
    final events = <LudoEvent>[PawnMoved(color, pawn, chosen.from, chosen.to)];

    steps[color]![pawn] = chosen.to;
    arrivals[color]![pawn] = moveCount;

    final victim = chosen.victim;
    if (victim != null) {
      final victimStep = steps[victim.color]![victim.index];
      steps[victim.color]![victim.index] = -1;
      arrivals[victim.color]![victim.index] = 0;
      stats[color] = stats[color]!.copyWith(captures: stats[color]!.captures + 1);
      stats[victim.color] = stats[victim.color]!.copyWith(captured: stats[victim.color]!.captured + 1);
      events.add(PawnCaptured(color, victim, victimStep));
    }

    var ranking = state.ranking;
    var phase = LudoPhase.turnOver;
    if (chosen.reachesHome) {
      events.add(PawnReachedHome(color, pawn));
      if (steps[color]!.every((s) => s == BoardGeometry.homeStep)) {
        ranking = [...ranking, color];
        events.add(PlayerFinished(color, ranking.length));
        final remaining = [for (final s in state.seats) if (!ranking.contains(s.color)) s.color];
        if (remaining.length <= 1) {
          ranking = [...ranking, ...remaining];
          phase = LudoPhase.finished;
          events.add(MatchFinished(List.unmodifiable(ranking)));
        }
      }
    }

    final stillPlaying = !ranking.contains(color);
    if (phase != LudoPhase.finished && stillPlaying && (chosen.isCapture || state.dice == 6)) {
      phase = LudoPhase.roll;
      events.add(ExtraRollGranted(color, chosen.isCapture ? ExtraRollReason.capture : ExtraRollReason.six));
    }

    return LudoStep(
      state.copyWith(
        steps: Map.unmodifiable({for (final e in steps.entries) e.key: List<int>.unmodifiable(e.value)}),
        arrivals: Map.unmodifiable({for (final e in arrivals.entries) e.key: List<int>.unmodifiable(e.value)}),
        stats: Map.unmodifiable(stats),
        ranking: List.unmodifiable(ranking),
        phase: phase,
        moveCount: moveCount,
      ),
      events,
    );
  }

  ///Pass the turn to the next seat that is still playing
  static LudoStep endTurn(LudoState state) {
    if (state.phase != LudoPhase.turnOver) {
      throw LudoRuleViolation('Cannot end the turn during ${state.phase.name}');
    }
    int next = state.turn;
    for (int i = 0; i < state.seats.length; i++) {
      next = (next + 1) % state.seats.length;
      if (!state.ranking.contains(state.seats[next].color)) break;
    }
    final color = state.seats[next].color;
    final stats = Map.of(state.stats);
    stats[color] = stats[color]!.copyWith(turns: stats[color]!.turns + 1);
    return LudoStep(
      state.copyWith(
        turn: next,
        dice: () => null,
        phase: LudoPhase.roll,
        sixStreak: 0,
        stats: Map.unmodifiable(stats),
      ),
      [TurnPassed(state.currentColor, color)],
    );
  }
}
