import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_flutter/audio.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/game_config.dart';
import 'package:ludo_flutter/ludo_player.dart';
import 'package:ludo_flutter/ludo_provider.dart';
import 'package:ludo_flutter/rules.dart';
import 'package:shared_preferences/shared_preferences.dart';

///Poll [condition] until it holds or [timeout] elapses
Future<bool> waitFor(bool Function() condition, {Duration timeout = const Duration(seconds: 8)}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return true;
    await Future.delayed(const Duration(milliseconds: 50));
  }
  return condition();
}

LudoPlayer makePlayer(LudoPlayerType type) => LudoPlayer(type, name: type.name);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Rules.targetStep', () {
    test('leaving base requires a 6 and lands on the start cell', () {
      expect(Rules.targetStep(-1, 6, 57, exactFinish: true), 0);
      expect(Rules.targetStep(-1, 5, 57, exactFinish: true), isNull);
      expect(Rules.targetStep(-1, 6, 57, exactFinish: false), 0);
    });

    test('a pawn on the final cell never moves', () {
      expect(Rules.targetStep(56, 1, 57, exactFinish: true), isNull);
      expect(Rules.targetStep(56, 6, 57, exactFinish: false), isNull);
    });

    test('exact finish blocks an overshoot, relaxed finish clamps', () {
      expect(Rules.targetStep(54, 6, 57, exactFinish: true), isNull);
      expect(Rules.targetStep(54, 6, 57, exactFinish: false), 56);
      expect(Rules.targetStep(54, 2, 57, exactFinish: true), 56);
      expect(Rules.targetStep(10, 3, 57, exactFinish: true), 13);
    });
  });

  group('Rules.legalMoves', () {
    test('captures are only legal off a safe cell', () {
      final green = makePlayer(LudoPlayerType.green);
      final blue = makePlayer(LudoPlayerType.blue);
      green.movePawn(0, 10);
      final landing = green.path[12];
      expect(Rules.isSafeCell(landing), isFalse);

      ///Put a blue pawn on green's landing cell
      final blueStep = blue.path.indexWhere((c) => c[0] == landing[0] && c[1] == landing[1]);
      expect(blueStep, greaterThan(0));
      blue.movePawn(0, blueStep);

      final moves = Rules.legalMoves(
        player: green,
        dice: 2,
        allPlayers: [green, blue],
        exactFinish: true,
        blocking: false,
      );
      final move = moves.firstWhere((m) => m.pawnIndex == 0);
      expect(move.isCapture, isTrue);
    });

    test('an enemy on a safe cell cannot be captured', () {
      final green = makePlayer(LudoPlayerType.green);
      final blue = makePlayer(LudoPlayerType.blue);

      ///Find a safe cell on green's path and a matching blue step
      int safeStep = -1;
      for (int i = 1; i < green.path.length - 1; i++) {
        if (Rules.isSafeCell(green.path[i])) {
          safeStep = i;
          break;
        }
      }
      expect(safeStep, greaterThan(0));
      green.movePawn(0, safeStep - 2);
      final landing = green.path[safeStep];
      final blueStep = blue.path.indexWhere((c) => c[0] == landing[0] && c[1] == landing[1]);
      blue.movePawn(0, blueStep);

      final moves = Rules.legalMoves(
        player: green,
        dice: 2,
        allPlayers: [green, blue],
        exactFinish: true,
        blocking: false,
      );
      final move = moves.firstWhere((m) => m.pawnIndex == 0);
      expect(move.landsOnSafe, isTrue);
      expect(move.isCapture, isFalse);
    });

    test('an enemy stack blocks passage only when blocking is enabled', () {
      final green = makePlayer(LudoPlayerType.green);
      final blue = makePlayer(LudoPlayerType.blue);
      green.movePawn(0, 10);

      ///Two blue pawns standing on the cell green wants to cross
      final landing = green.path[12];
      expect(Rules.isSafeCell(landing), isFalse);
      final blueStep = blue.path.indexWhere((c) => c[0] == landing[0] && c[1] == landing[1]);
      blue.movePawn(0, blueStep);
      blue.movePawn(1, blueStep);

      final open = Rules.legalMoves(
        player: green,
        dice: 2,
        allPlayers: [green, blue],
        exactFinish: true,
        blocking: false,
      );
      expect(open.any((m) => m.pawnIndex == 0), isTrue);

      final blocked = Rules.legalMoves(
        player: green,
        dice: 2,
        allPlayers: [green, blue],
        exactFinish: true,
        blocking: true,
      );
      expect(blocked.any((m) => m.pawnIndex == 0), isFalse);
    });

    test('a pawn one roll from home reports reachesFinish', () {
      final green = makePlayer(LudoPlayerType.green);
      green.movePawn(0, green.path.length - 3);
      final moves = Rules.legalMoves(
        player: green,
        dice: 2,
        allPlayers: [green],
        exactFinish: true,
        blocking: false,
      );
      expect(moves.single.reachesFinish, isTrue);
      expect(moves.single.toStep, green.path.length - 1);
    });
  });

  group('Rules.chooseCpuPawn', () {
    const capture = MoveCandidate(
      pawnIndex: 2,
      fromStep: 4,
      toStep: 6,
      fromBase: false,
      isCapture: true,
      landsOnSafe: false,
      formsBlock: false,
      threatCount: 0,
      reachesFinish: false,
    );
    const progress = MoveCandidate(
      pawnIndex: 0,
      fromStep: 40,
      toStep: 45,
      fromBase: false,
      isCapture: false,
      landsOnSafe: false,
      formsBlock: false,
      threatCount: 0,
      reachesFinish: false,
    );

    test('hard prefers a capture over plain progress', () {
      final pick = Rules.chooseCpuPawn(
        [progress, capture],
        CpuDifficulty.hard,
        pathLength: 57,
        random: Random(7),
      );
      expect(pick, 2);
    });

    test('medium races the pawn closest to the finish', () {
      final pick = Rules.chooseCpuPawn(
        [capture, progress],
        CpuDifficulty.medium,
        pathLength: 57,
        random: Random(7),
      );
      expect(pick, 0);
    });

    test('easy always returns a legal pawn and null on no moves', () {
      final rng = Random(11);
      for (int i = 0; i < 20; i++) {
        final pick = Rules.chooseCpuPawn(
          [progress, capture],
          CpuDifficulty.easy,
          pathLength: 57,
          random: rng,
        );
        expect(pick, anyOf(0, 2));
      }
      expect(
        Rules.chooseCpuPawn([], CpuDifficulty.easy, pathLength: 57, random: rng),
        isNull,
      );
    });

    test('hard avoids walking into capture range', () {
      const safeFinish = MoveCandidate(
        pawnIndex: 1,
        fromStep: 50,
        toStep: 53,
        fromBase: false,
        isCapture: false,
        landsOnSafe: true,
        formsBlock: false,
        threatCount: 0,
        reachesFinish: false,
      );
      const exposed = MoveCandidate(
        pawnIndex: 3,
        fromStep: 40,
        toStep: 44,
        fromBase: false,
        isCapture: false,
        landsOnSafe: false,
        formsBlock: false,
        threatCount: 3,
        reachesFinish: false,
      );
      final pick = Rules.chooseCpuPawn(
        [exposed, safeFinish],
        CpuDifficulty.hard,
        pathLength: 57,
        random: Random(3),
      );
      expect(pick, 1);
    });
  });

  group('GameConfig serialization', () {
    test('round-trips every rule and the difficulty', () {
      const config = GameConfig(
        players: [
          PlayerSetup(color: LudoPlayerType.green, name: 'A'),
          PlayerSetup(color: LudoPlayerType.red, name: 'B', isCpu: true),
        ],
        extraRollOnSix: false,
        captureGrantsRoll: false,
        threeSixesForfeit: true,
        exactFinish: false,
        blocking: true,
        cpuDifficulty: CpuDifficulty.hard,
      );
      final restored = GameConfig.fromJson(jsonDecode(jsonEncode(config.toJson())));
      expect(restored.extraRollOnSix, isFalse);
      expect(restored.captureGrantsRoll, isFalse);
      expect(restored.threeSixesForfeit, isTrue);
      expect(restored.exactFinish, isFalse);
      expect(restored.blocking, isTrue);
      expect(restored.cpuDifficulty, CpuDifficulty.hard);
      expect(restored.players.length, 2);
      expect(restored.players[1].isCpu, isTrue);
      expect(restored.players[1].name, 'B');
    });
  });

  group('Undo', () {
    test('rewinds the human move and the reply played after it', () async {
      final soundWasEnabled = Audio.enabled;
      Audio.enabled = false;
      addTearDown(() => Audio.enabled = soundWasEnabled);
      SharedPreferences.setMockInitialValues({});

      final provider = LudoProvider();
      addTearDown(provider.dispose);
      provider.startGame(const GameConfig(
        players: [
          PlayerSetup(color: LudoPlayerType.green, name: 'A'),
          PlayerSetup(color: LudoPlayerType.blue, name: 'B'),
        ],
        extraRollOnSix: false,
      ));

      ///Green has one pawn on the board so every roll yields a move
      final green = provider.player(LudoPlayerType.green);
      green.movePawn(0, 5);
      expect(provider.canUndo, isFalse); //no completed move yet

      provider.throwDice();
      expect(
        await waitFor(() =>
            provider.currentPlayer.type == LudoPlayerType.blue ||
            provider.gameState == LudoGameState.pickPawn),
        isTrue,
      );
      final greenDice = provider.diceResult;
      if (provider.gameState == LudoGameState.pickPawn) {
        provider.pickAndMove(0);
      }
      expect(await waitFor(
        () => provider.currentPlayer.type == LudoPlayerType.blue,
      ), isTrue);
      expect(provider.player(LudoPlayerType.green).pawns[0].step, greaterThan(5));
      expect(provider.canUndo, isFalse); //not green's turn

      ///Play out blue's turn until green is up again
      for (int guard = 0; guard < 20 && provider.currentPlayer.type != LudoPlayerType.green; guard++) {
        if (provider.gameState == LudoGameState.throwDice) {
          provider.throwDice();
          await waitFor(
            () => provider.gameState != LudoGameState.throwDice ||
                provider.currentPlayer.type != LudoPlayerType.blue,
          );
        }
        if (provider.gameState == LudoGameState.pickPawn) {
          provider.pickAndMove(provider.currentLegalMoves().first.pawnIndex);
          await waitFor(() => provider.currentPlayer.type != LudoPlayerType.blue);
        }
        await Future.delayed(const Duration(milliseconds: 50));
      }
      expect(provider.currentPlayer.type, LudoPlayerType.green);

      expect(provider.canUndo, isTrue);
      final stepBeforeUndo = provider.player(LudoPlayerType.green).pawns[0].step;
      expect(stepBeforeUndo, greaterThan(5));

      provider.undoLastMove();
      expect(provider.currentPlayer.type, LudoPlayerType.green);
      expect(provider.player(LudoPlayerType.green).pawns[0].step, 5);
      expect(provider.diceResult, greenDice);
      expect(provider.gameState, LudoGameState.pickPawn);
      expect(provider.player(LudoPlayerType.green).highlighted, contains(0));
    });
  });

  group('Save / resume', () {
    test('a fresh match can be suspended and restored', () async {
      SharedPreferences.setMockInitialValues({});
      final soundWasEnabled = Audio.enabled;
      Audio.enabled = false;
      addTearDown(() => Audio.enabled = soundWasEnabled);

      final provider = LudoProvider();
      provider.startGame(const GameConfig(
        players: [
          PlayerSetup(color: LudoPlayerType.green, name: 'A'),
          PlayerSetup(color: LudoPlayerType.blue, name: 'B', isCpu: true),
        ],
        threeSixesForfeit: true,
        cpuDifficulty: CpuDifficulty.hard,
      ));
      provider.player(LudoPlayerType.green).movePawn(0, 12);
      provider.player(LudoPlayerType.green).movePawn(1, 3);

      final saved = jsonEncode(provider.toSaveJson());
      provider.dispose(); //cancel pending timers before swapping the store
      await Future.delayed(const Duration(milliseconds: 600));

      SharedPreferences.setMockInitialValues({LudoProvider.saveKey: saved});
      expect(await LudoProvider.savedMatchExists(), isTrue);

      final resumed = LudoProvider();
      addTearDown(resumed.dispose);
      expect(await resumed.resumeSavedGame(), isTrue);
      expect(resumed.players.length, 2);
      expect(resumed.player(LudoPlayerType.green).pawns[0].step, 12);
      expect(resumed.player(LudoPlayerType.green).pawns[1].step, 3);
      expect(resumed.player(LudoPlayerType.blue).pawns.every((p) => p.step == -1), isTrue);
      expect(resumed.config.threeSixesForfeit, isTrue);
      expect(resumed.config.cpuDifficulty, CpuDifficulty.hard);
      expect(resumed.currentPlayer.type, LudoPlayerType.green);
      expect(resumed.isFinished, isFalse);
    });

    test('a corrupt save is dropped instead of crashing', () async {
      SharedPreferences.setMockInitialValues({LudoProvider.saveKey: '{not json'});
      final provider = LudoProvider();
      addTearDown(provider.dispose);
      expect(await provider.resumeSavedGame(), isFalse);
      expect(await LudoProvider.savedMatchExists(), isFalse);
    });

    test('quitMatch clears the suspended match', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = LudoProvider();
      addTearDown(provider.dispose);
      provider.startGame(GameConfig.defaults(2));
      provider.flushSave();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(await LudoProvider.savedMatchExists(), isTrue);

      provider.quitMatch();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(await LudoProvider.savedMatchExists(), isFalse);
      expect(provider.players, isEmpty);
    });
  });
}
