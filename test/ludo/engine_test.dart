import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_flutter/games/ludo/engine/board_geometry.dart';
import 'package:ludo_flutter/games/ludo/engine/ludo_bot.dart';
import 'package:ludo_flutter/games/ludo/engine/ludo_engine.dart';
import 'package:ludo_flutter/games/ludo/engine/ludo_rules.dart';
import 'package:ludo_flutter/games/ludo/models/ludo_models.dart';
import 'package:ludo_flutter/games/ludo/models/ludo_state.dart';

const red = LudoColor.red;
const green = LudoColor.green;
const yellow = LudoColor.yellow;
const blue = LudoColor.blue;

List<LudoSeat> seats(List<LudoColor> colors) => [for (final c in colors) LudoSeat(color: c, name: c.label)];

///A match with custom pawn positions. Every pawn not listed stays in base.
LudoState board(
  List<LudoColor> colors, {
  Map<LudoColor, List<int>> steps = const {},
  Map<LudoColor, List<int>> arrivals = const {},
  int turn = 0,
  int? dice,
  LudoPhase phase = LudoPhase.roll,
  int sixStreak = 0,
}) {
  final start = LudoEngine.start(seats(colors));
  return start.copyWith(
    steps: {for (final c in colors) c: steps[c] ?? const [-1, -1, -1, -1]},
    arrivals: {for (final c in colors) c: arrivals[c] ?? const [0, 0, 0, 0]},
    turn: turn,
    dice: () => dice,
    phase: phase,
    sixStreak: sixStreak,
  );
}

///Step on [color]'s route that sits on the same cell as [other]'s [step]
int sameCell(LudoColor color, LudoColor other, int step) {
  final cell = BoardGeometry.cellOf(other, step);
  return BoardGeometry.routeOf(color).indexOf(cell!);
}

void main() {
  group('Board geometry', () {
    test('each route has 57 steps ending in a private home column', () {
      for (final c in LudoColor.values) {
        final route = BoardGeometry.routeOf(c);
        expect(route.length, 57);
        expect(route.toSet().length, 57, reason: 'no cell repeats');
      }
      final columns = [
        for (final c in LudoColor.values) BoardGeometry.routeOf(c).sublist(51).toSet(),
      ];
      for (int i = 0; i < 4; i++) {
        for (int j = i + 1; j < 4; j++) {
          expect(columns[i].intersection(columns[j]), isEmpty);
        }
      }
    });

    test('there are exactly eight safe cells: four starts and four stars', () {
      expect(BoardGeometry.safeCells.length, 8);
      for (final c in LudoColor.values) {
        expect(BoardGeometry.isSafe(BoardGeometry.routeOf(c).first), isTrue);
        expect(BoardGeometry.isSafe(BoardGeometry.routeOf(c)[8]), isTrue);
      }
    });
  });

  group('Movement', () {
    test('leaving base needs a 6 and lands on the start cell', () {
      expect(LudoRules.targetStep(-1, 6), 0);
      for (int d = 1; d <= 5; d++) {
        expect(LudoRules.targetStep(-1, d), isNull);
      }
    });

    test('pawns move exactly the rolled value', () {
      expect(LudoRules.targetStep(10, 4), 14);
    });

    test('exact finish: no overshoot, exact roll reaches home', () {
      expect(LudoRules.targetStep(53, 4), isNull);
      expect(LudoRules.targetStep(53, 3), BoardGeometry.homeStep);
      expect(LudoRules.targetStep(BoardGeometry.homeStep, 1), isNull);
    });

    test('a roll without legal moves passes the turn', () {
      final step = LudoEngine.roll(board([red, yellow]), 3);
      expect(step.state.phase, LudoPhase.turnOver);
      expect(step.events.whereType<NoLegalMove>(), hasLength(1));
      final next = LudoEngine.endTurn(step.state).state;
      expect(next.currentColor, yellow);
      expect(next.dice, isNull);
      expect(next.phase, LudoPhase.roll);
    });

    test('rolling a 6 enters a pawn and grants another roll', () {
      final rolled = LudoEngine.roll(board([red, yellow]), 6).state;
      expect(rolled.phase, LudoPhase.move);
      expect(LudoRules.legalMoves(rolled).map((m) => m.to), everyElement(0));
      final moved = LudoEngine.move(rolled, 2);
      expect(moved.state.stepsOf(red), [-1, -1, 0, -1]);
      expect(moved.state.phase, LudoPhase.roll);
      expect(moved.state.currentColor, red);
      expect(moved.events.whereType<ExtraRollGranted>().single.reason, ExtraRollReason.six);
    });

    test('a 6 with no legal move still grants another roll', () {
      final s = board([red, yellow], steps: {
        red: [53, 54, 55, 56],
      });
      final step = LudoEngine.roll(s, 6);
      expect(step.state.phase, LudoPhase.roll);
      expect(step.state.currentColor, red);
    });

    test('a plain move ends the turn', () {
      final s = board([red, yellow], steps: {
        red: [10, -1, -1, -1],
      });
      final moved = LudoEngine.move(LudoEngine.roll(s, 4).state, 0).state;
      expect(moved.stepsOf(red)[0], 14);
      expect(moved.phase, LudoPhase.turnOver);
    });

    test('illegal actions are rejected', () {
      final s = board([red, yellow], steps: {
        red: [10, -1, -1, -1],
      });
      expect(() => LudoEngine.move(s, 0), throwsA(isA<LudoRuleViolation>()), reason: 'move before rolling');
      final rolled = LudoEngine.roll(s, 3).state;
      expect(() => LudoEngine.roll(rolled, 4), throwsA(isA<LudoRuleViolation>()), reason: 'roll twice');
      expect(() => LudoEngine.move(rolled, 1), throwsA(isA<LudoRuleViolation>()), reason: 'pawn in base on a 3');
      expect(() => LudoEngine.endTurn(rolled), throwsA(isA<LudoRuleViolation>()), reason: 'turn not over');
      expect(() => LudoEngine.roll(s, 7), throwsA(isA<LudoRuleViolation>()));
    });
  });

  group('Three sixes', () {
    test('the third six is cancelled, earlier moves stay, turn passes', () {
      var s = board([red, yellow]);
      s = LudoEngine.move(LudoEngine.roll(s, 6).state, 0).state; //pawn out
      s = LudoEngine.move(LudoEngine.roll(s, 6).state, 0).state; //0 -> 6
      expect(s.stepsOf(red)[0], 6);
      final third = LudoEngine.roll(s, 6);
      expect(third.events.whereType<ThreeSixesForfeited>(), hasLength(1));
      expect(third.state.phase, LudoPhase.turnOver);
      expect(third.state.stepsOf(red)[0], 6, reason: 'moves of the first two sixes remain');
      final next = LudoEngine.endTurn(third.state).state;
      expect(next.currentColor, yellow);
      expect(next.sixStreak, 0);
    });

    test('a non-six resets the streak', () {
      var s = board([red, yellow], steps: {
        red: [10, -1, -1, -1],
      });
      s = LudoEngine.move(LudoEngine.roll(s, 6).state, 0).state;
      expect(s.sixStreak, 1);
      final captureRoll = LudoEngine.roll(s, 2).state;
      expect(captureRoll.sixStreak, 0);
    });
  });

  group('Captures and safe cells', () {
    test('landing on an opponent sends it home and grants a roll', () {
      final target = sameCell(yellow, red, 14);
      final s = board([red, yellow], steps: {
        red: [10, -1, -1, -1],
        yellow: [target, -1, -1, -1],
      });
      final step = LudoEngine.move(LudoEngine.roll(s, 4).state, 0);
      expect(step.state.stepsOf(red)[0], 14, reason: 'the mover stays on the cell');
      expect(step.state.stepsOf(yellow)[0], -1);
      expect(step.state.phase, LudoPhase.roll);
      expect(step.events.whereType<ExtraRollGranted>().single.reason, ExtraRollReason.capture);
      expect(step.state.stats[red]!.captures, 1);
      expect(step.state.stats[yellow]!.captured, 1);
    });

    test('pawns on a star cell cannot be captured', () {
      final star = sameCell(yellow, red, 8);
      final s = board([red, yellow], steps: {
        red: [4, -1, -1, -1],
        yellow: [star, -1, -1, -1],
      });
      final step = LudoEngine.move(LudoEngine.roll(s, 4).state, 0);
      expect(step.state.stepsOf(yellow)[0], star);
      expect(step.events.whereType<PawnCaptured>(), isEmpty);
      expect(step.state.phase, LudoPhase.turnOver);
    });

    test('a start cell is safe even for the pawn entering it', () {
      final redStart = sameCell(yellow, red, 0);
      final s = board([red, yellow], steps: {
        yellow: [redStart, -1, -1, -1],
      });
      final step = LudoEngine.move(LudoEngine.roll(s, 6).state, 0);
      expect(step.state.stepsOf(yellow)[0], redStart);
      expect(step.events.whereType<PawnCaptured>(), isEmpty);
    });

    test('only the top pawn of a shared cell is captured', () {
      final target = sameCell(yellow, red, 14);
      final blueTarget = sameCell(blue, red, 14);
      final s = board([red, yellow, blue], steps: {
        red: [10, -1, -1, -1],
        yellow: [target, target, -1, -1],
        blue: [blueTarget, -1, -1, -1],
      }, arrivals: {
        yellow: [3, 7, 0, 0],
        blue: [5, 0, 0, 0],
      });
      final step = LudoEngine.move(LudoEngine.roll(s, 4).state, 0);
      expect(step.state.stepsOf(yellow), [target, -1, -1, -1], reason: 'yellow #1 arrived last');
      expect(step.state.stepsOf(blue)[0], blueTarget);
      expect(step.events.whereType<PawnCaptured>(), hasLength(1));
    });

    test('there are no blocks: two opponent pawns never stop a move', () {
      final wall = sameCell(yellow, red, 12);
      final s = board([red, yellow], steps: {
        red: [10, -1, -1, -1],
        yellow: [wall, wall, -1, -1],
      });
      final moves = LudoRules.legalMoves(LudoEngine.roll(s, 4).state);
      expect(moves.single.to, 14, reason: 'passing the pair is allowed');
      final landing = LudoRules.legalMoves(LudoEngine.roll(s, 2).state);
      expect(landing.single.isCapture, isTrue, reason: 'landing on the pair is allowed');
    });

    test('pawns of the same color share a cell', () {
      final s = board([red, yellow], steps: {
        red: [10, 14, -1, -1],
      });
      final moved = LudoEngine.move(LudoEngine.roll(s, 4).state, 0).state;
      expect(moved.stepsOf(red), [14, 14, -1, -1]);
    });
  });

  group('Winning', () {
    test('two players: the first to bring all four pawns home wins', () {
      final s = board([red, yellow], steps: {
        red: [56, 56, 56, 53],
        yellow: [20, -1, -1, -1],
      });
      final step = LudoEngine.move(LudoEngine.roll(s, 3).state, 3);
      expect(step.state.phase, LudoPhase.finished);
      expect(step.state.ranking, [red, yellow]);
      expect(step.events.whereType<MatchFinished>(), hasLength(1));
      expect(() => LudoEngine.roll(step.state, 3), throwsA(isA<LudoRuleViolation>()));
    });

    test('a finished player gets no extra roll and is skipped afterwards', () {
      final s = board([red, green, yellow], steps: {
        red: [56, 56, 56, 50],
        green: [5, -1, -1, -1],
        yellow: [5, -1, -1, -1],
      });
      final step = LudoEngine.move(LudoEngine.roll(s, 6).state, 3);
      expect(step.state.ranking, [red]);
      expect(step.state.phase, LudoPhase.turnOver, reason: 'no extra roll after finishing');
      var next = LudoEngine.endTurn(step.state).state;
      expect(next.currentColor, green);
      next = LudoEngine.endTurn(LudoEngine.roll(next, 1).state.copyWith(phase: LudoPhase.turnOver)).state;
      expect(next.currentColor, yellow);
      next = LudoEngine.endTurn(next.copyWith(phase: LudoPhase.turnOver)).state;
      expect(next.currentColor, green, reason: 'red has finished and is skipped');
    });

    test('three players: play continues to rank the remaining seats', () {
      final s = board([red, green, yellow], steps: {
        red: [56, 56, 56, 56],
        green: [56, 56, 56, 55],
        yellow: [5, -1, -1, -1],
      }, turn: 1);
      final s2 = s.copyWith(ranking: const [red]);
      final step = LudoEngine.move(LudoEngine.roll(s2, 1).state, 3);
      expect(step.state.phase, LudoPhase.finished);
      expect(step.state.ranking, [red, green, yellow]);
    });
  });

  group('Bot', () {
    final random = Random(1);

    test('never picks an illegal move', () {
      for (final difficulty in BotDifficulty.values) {
        for (int i = 0; i < 50; i++) {
          final s = board([red, yellow], steps: {
            red: [random.nextInt(57) - 1, -1, 30, 54],
          });
          final rolled = LudoEngine.roll(s, random.nextInt(6) + 1).state;
          final pick = LudoBot.choosePawn(rolled, difficulty, random);
          final legal = LudoRules.legalMoves(rolled).map((m) => m.pawn).toSet();
          if (legal.isEmpty) {
            expect(pick, isNull);
          } else {
            expect(legal, contains(pick));
          }
        }
      }
    });

    test('medium races the furthest pawn, hard prefers a capture', () {
      final target = sameCell(yellow, red, 14);
      final s = board([red, yellow], steps: {
        red: [10, 40, -1, -1],
        yellow: [target, -1, -1, -1],
      });
      final rolled = LudoEngine.roll(s, 4).state;
      expect(LudoBot.choosePawn(rolled, BotDifficulty.medium, random), 1);
      expect(LudoBot.choosePawn(rolled, BotDifficulty.hard, random), 0);
    });

    test('hard avoids landing right in front of an opponent', () {
      //Pawn 0 would land 2 cells ahead of a yellow pawn; pawn 1 lands far away
      final danger = sameCell(yellow, red, 20);
      final s = board([red, yellow], steps: {
        red: [18, 30, -1, -1],
        yellow: [danger - 4, -1, -1, -1],
      });
      final rolled = LudoEngine.roll(s, 4).state;
      expect(LudoBot.choosePawn(rolled, BotDifficulty.hard, random), 1);
    });
  });

  test('state survives a JSON round trip', () {
    var s = LudoEngine.start(seats([red, green, yellow, blue]));
    s = LudoEngine.move(LudoEngine.roll(s, 6).state, 1).state;
    final restored = LudoState.fromJson(s.toJson());
    expect(restored.toJson(), s.toJson());
  });
}
