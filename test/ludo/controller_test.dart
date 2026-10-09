import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_flutter/core/audio/sound_effects.dart';
import 'package:ludo_flutter/core/settings/app_settings.dart';
import 'package:ludo_flutter/games/ludo/controller/ludo_controller.dart';
import 'package:ludo_flutter/games/ludo/engine/board_geometry.dart';
import 'package:ludo_flutter/games/ludo/engine/ludo_engine.dart';
import 'package:ludo_flutter/games/ludo/data/ludo_records.dart';
import 'package:ludo_flutter/games/ludo/data/ludo_save_store.dart';
import 'package:ludo_flutter/games/ludo/models/ludo_models.dart';
import 'package:ludo_flutter/games/ludo/models/ludo_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_support.dart';

///Dice come from [dice] in order (then 1s); every other draw returns 0
class ScriptedRandom implements Random {
  final List<int> dice;
  ScriptedRandom(this.dice);

  @override
  int nextInt(int max) => max == 6 ? (dice.isEmpty ? 0 : dice.removeAt(0) - 1) : 0;

  @override
  double nextDouble() => 0.5;

  @override
  bool nextBool() => false;
}

LudoController controller({Random? random, LudoSaveStore? store, LudoRecords? records}) {
  final settings = AppSettings();
  SoundEffects.enabled = false;
  Haptics.enabled = false;
  return LudoController(
    records: records ?? LudoRecords(),
    settings: settings,
    store: store ?? LudoSaveStore(),
    random: random ?? Random(7),
    pacing: LudoPacing.instant,
  );
}

const botFirst = LudoMatchConfig(
  mode: LudoMode.vsComputer,
  difficulty: BotDifficulty.hard,
  seats: [
    LudoSeat(color: LudoColor.yellow, name: 'Bot', isBot: true),
    LudoSeat(color: LudoColor.red, name: 'You'),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a 6 with only base pawns moves automatically and grants another roll', () async {
    final c = controller(random: ScriptedRandom([6]));
    c.startMatch(duel());
    expect(c.canRoll, isTrue);
    c.rollDice();
    expect(c.isRolling, isTrue);
    c.rollDice(); //tapping again while rolling does nothing
    await settle();
    expect(c.state.stepsOf(LudoColor.red).where((s) => s == 0), hasLength(1));
    expect(c.state.currentColor, LudoColor.red);
    expect(c.state.phase, LudoPhase.roll);
    c.dispose();
  });

  test('three sixes through the controller: third is cancelled, turn passes to the bot', () async {
    final c = controller(random: ScriptedRandom([6, 6, 6]));
    c.startMatch(duel());
    c.rollDice();
    await settle(); //auto-entered
    c.rollDice();
    await settle();
    expect(c.selectablePawns, isNotEmpty, reason: 'two different moves: the player chooses');
    c.selectPawn(c.state.stepsOf(LudoColor.red).indexOf(0));
    await settle();
    c.rollDice();
    await settle(3);
    final red = c.state.stepsOf(LudoColor.red);
    expect(red.where((s) => s >= 0), hasLength(1), reason: 'moves from the first two sixes stay');
    expect(red.firstWhere((s) => s >= 0), 6);
    expect(c.state.stats[LudoColor.red]!.sixes, 3);
    c.dispose();
  });

  ///Step on [color]'s route that lands on the cell of [other]'s [step]
  int sameCell(LudoColor color, LudoColor other, int step) =>
      BoardGeometry.routeOf(color).indexOf(BoardGeometry.cellOf(other, step)!);

  test('a human capture returns the pawn to base and gives the same player another roll', () async {
    final c = controller(random: ScriptedRandom([4]));
    final config = duel();
    final s = LudoEngine.start(config.seats).copyWith(steps: {
      LudoColor.red: const [10, -1, -1, -1],
      LudoColor.yellow: [sameCell(LudoColor.yellow, LudoColor.red, 14), -1, -1, -1],
    });
    c.debugShow(config, s);
    c.rollDice();
    await settle(); //single legal move is played automatically
    expect(c.state.stepsOf(LudoColor.yellow), [-1, -1, -1, -1], reason: 'captured pawn is back in base');
    expect(c.state.stepsOf(LudoColor.red)[0], 14);
    expect(c.state.currentColor, LudoColor.red);
    expect(c.canRoll, isTrue, reason: 'extra turn after the capture');
    expect(c.state.stats[LudoColor.red]!.captures, 1);
    c.dispose();
  });

  test('a bot capture also earns the bot an extra roll before the turn passes', () async {
    final c = controller(random: ScriptedRandom([4, 1]));
    const config = botFirst;
    const yellowStart = 10;
    final s = LudoEngine.start(config.seats).copyWith(steps: {
      LudoColor.yellow: [yellowStart, -1, -1, -1],
      LudoColor.red: [sameCell(LudoColor.red, LudoColor.yellow, yellowStart + 4), -1, -1, -1],
    });
    c.debugShow(config, s);
    await settle(60);
    expect(c.state.stepsOf(LudoColor.red)[0], -1, reason: 'red pawn captured');
    expect(c.state.stepsOf(LudoColor.yellow)[0], yellowStart + 5, reason: 'bot rolled 4 (capture) then 1 (extra roll)');
    expect(c.state.currentColor, LudoColor.red, reason: 'turn passes after the extra roll');
    expect(c.state.stats[LudoColor.yellow]!.turns, 1, reason: 'still one turn for the bot');
    c.dispose();
  });

  test('a capture survives leave and continue with the extra roll still pending', () async {
    final store = LudoSaveStore();
    final c = controller(random: ScriptedRandom([4]), store: store);
    final config = duel();
    c.debugShow(
      config,
      LudoEngine.start(config.seats).copyWith(steps: {
        LudoColor.red: const [10, -1, -1, -1],
        LudoColor.yellow: [sameCell(LudoColor.yellow, LudoColor.red, 14), -1, -1, -1],
      }),
    );
    c.rollDice();
    await settle();
    await c.leave();

    final again = controller(store: store);
    expect(await again.loadSaved(), isTrue);
    expect(again.state.currentColor, LudoColor.red);
    expect(again.state.phase, LudoPhase.roll);
    expect(again.canRoll, isTrue);
    c.dispose();
    again.dispose();
  });

  test('humans cannot act during a bot turn or pick illegal pawns', () async {
    final c = controller();
    c.startMatch(botFirst);
    c.pause();
    expect(c.canRoll, isFalse);
    c.rollDice();
    c.selectPawn(0);
    expect(c.isRolling, isFalse);
    expect(c.state.dice, isNull);
    c.dispose();
  });

  test('pausing freezes bots; resuming continues', () async {
    final c = controller();
    c.startMatch(botFirst);
    c.pause();
    await settle(40);
    expect(c.state.moveCount, 0);
    expect(c.state.dice, isNull);
    expect(c.state.currentColor, LudoColor.yellow);
    c.resume();
    await settle(40);
    expect(c.state.dice != null || c.state.currentColor == LudoColor.red, isTrue);
    c.dispose();
  });

  test('leaving saves the match and stops bots; continuing restores it', () async {
    final store = LudoSaveStore();
    final c = controller(store: store);
    c.startMatch(botFirst);
    await settle(10);
    final id = c.matchId;
    final snapshot = c.state.toJson();
    await c.leave();
    expect(c.hasMatch, isFalse);
    await settle(40); //no bot keeps playing in the background

    final again = controller(store: store);
    expect(await again.loadSaved(), isTrue);
    again.pause();
    expect(again.matchId, id, reason: 'resume keeps the match id');
    expect(again.state.toJson(), snapshot);
    c.dispose();
    again.dispose();
  });

  test('quitting clears the saved match', () async {
    final c = controller();
    c.startMatch(duel());
    await settle();
    await c.quit();
    expect(await c.savedSummary(), isNull);
    c.dispose();
  });

  test('every match gets a new id', () async {
    final c = controller(random: Random());
    c.startMatch(duel());
    final first = c.matchId;
    c.restart();
    expect(c.matchId, isNot(first));
    c.dispose();
  });

  test('an all-bot match plays to the end and is recorded once', () async {
    final records = LudoRecords();
    final c = controller(records: records, random: Random(3));
    c.startMatch(const LudoMatchConfig(
      mode: LudoMode.vsComputer,
      difficulty: BotDifficulty.hard,
      seats: [
        LudoSeat(color: LudoColor.red, name: 'R', isBot: true),
        LudoSeat(color: LudoColor.green, name: 'G', isBot: true),
        LudoSeat(color: LudoColor.yellow, name: 'Y', isBot: true),
        LudoSeat(color: LudoColor.blue, name: 'B', isBot: true),
      ],
    ));
    for (int i = 0; i < 200000 && !c.isFinished; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(c.isFinished, isTrue);
    expect(c.state.ranking, hasLength(4));
    await settle();
    expect(records.matchesPlayed, 1);
    expect(await c.savedSummary(), isNull, reason: 'a finished match is not resumable');
    c.dispose();
  });
}
