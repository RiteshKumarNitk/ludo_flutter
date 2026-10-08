import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_flutter/audio.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/game_config.dart';
import 'package:ludo_flutter/ludo_provider.dart';
import 'package:ludo_flutter/rules.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

///Two human seats; every rule defaults except the ones passed in
GameConfig twoPlayer({
  bool extraRollOnSix = true,
  bool captureGrantsRoll = true,
  bool threeSixesForfeit = false,
  bool exactFinish = true,
}) =>
    GameConfig(
      players: const [
        PlayerSetup(color: LudoPlayerType.green, name: 'A'),
        PlayerSetup(color: LudoPlayerType.blue, name: 'B'),
      ],
      extraRollOnSix: extraRollOnSix,
      captureGrantsRoll: captureGrantsRoll,
      threeSixesForfeit: threeSixesForfeit,
      exactFinish: exactFinish,
    );

int onBoard(LudoProvider provider, LudoPlayerType color) =>
    provider.player(color).pawns.where((p) => p.step >= 0).length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late bool soundWasEnabled;
  setUp(() {
    soundWasEnabled = Audio.enabled;
    Audio.enabled = false;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => Audio.enabled = soundWasEnabled);

  group('three consecutive sixes', () {
    test('forfeit the turn when the classic rule is enabled', () async {
      final p = LudoProvider();
      addTearDown(p.dispose);
      p.debugDiceRoll = () => 6;
      p.startGame(twoPlayer(threeSixesForfeit: true));
      expect(p.currentPlayer.type, LudoPlayerType.green);

      ///First six: everyone sits in base, the auto-exit earns the extra roll
      p.throwDice();
      expect(
        await waitFor(() => p.gameState == LudoGameState.throwDice && !p.diceStarted),
        isTrue,
        reason: 'roll one resolves back into the throw state',
      );
      expect(p.currentPlayer.type, LudoPlayerType.green);
      expect(onBoard(p, LudoPlayerType.green), 1);

      ///Second six: candidates now differ, so the pick waits for the player
      p.throwDice();
      expect(await waitFor(() => p.gameState == LudoGameState.pickPawn), isTrue);
      final basePick = p.currentLegalMoves().firstWhere((m) => m.fromBase);
      p.pickAndMove(basePick.pawnIndex);
      expect(
        await waitFor(() => p.gameState == LudoGameState.throwDice && !p.diceStarted),
        isTrue,
        reason: 'the extra roll after a six arrives',
      );
      expect(p.currentPlayer.type, LudoPlayerType.green);
      expect(onBoard(p, LudoPlayerType.green), 2);

      ///Third six hands the turn over instead of rolling again
      p.throwDice();
      expect(
        await waitFor(() => p.currentPlayer.type == LudoPlayerType.blue),
        isTrue,
        reason: 'the third six forfeits the turn',
      );
      expect(p.gameState, LudoGameState.throwDice);
      expect(onBoard(p, LudoPlayerType.green), 2);
    });

    test('grant a third roll when the forfeit rule is off', () async {
      final p = LudoProvider();
      addTearDown(p.dispose);
      p.debugDiceRoll = () => 6;
      p.startGame(twoPlayer(threeSixesForfeit: false));

      ///First six: uniform base exits auto-play into the extra roll
      p.throwDice();
      expect(
        await waitFor(() => p.gameState == LudoGameState.throwDice && !p.diceStarted),
        isTrue,
      );
      expect(p.currentPlayer.type, LudoPlayerType.green);

      ///Second six: mixed candidates wait for the pick, then re-roll
      p.throwDice();
      expect(await waitFor(() => p.gameState == LudoGameState.pickPawn), isTrue);
      p.pickAndMove(p.currentLegalMoves().first.pawnIndex);
      expect(
        await waitFor(() => p.gameState == LudoGameState.throwDice && !p.diceStarted),
        isTrue,
      );
      expect(p.currentPlayer.type, LudoPlayerType.green);

      ///Third six: no forfeit, green simply picks again
      p.throwDice();
      expect(await waitFor(() => p.gameState == LudoGameState.pickPawn), isTrue);
      expect(p.currentPlayer.type, LudoPlayerType.green);
      expect(p.gameState, LudoGameState.pickPawn);
    });
  });

  group('capture grants an extra roll', () {
    ///Green stands two cells before an unsafe blue pawn, forced dice: 2
    Future<LudoProvider> captureMatch({required bool captureGrantsRoll}) async {
      final p = LudoProvider();
      p.debugDiceRoll = () => 2;
      p.startGame(twoPlayer(captureGrantsRoll: captureGrantsRoll, extraRollOnSix: false));
      final green = p.player(LudoPlayerType.green);
      final blue = p.player(LudoPlayerType.blue);
      green.movePawn(0, 10);
      final landing = green.path[12];
      expect(Rules.isSafeCell(landing), isFalse);
      final blueStep = blue.path.indexWhere((c) => c[0] == landing[0] && c[1] == landing[1]);
      expect(blueStep, greaterThan(0));
      blue.movePawn(0, blueStep);
      return p;
    }

    test('keeps the turn for the captor when enabled', () async {
      final p = await captureMatch(captureGrantsRoll: true);
      addTearDown(p.dispose);

      p.throwDice();
      expect(
        await waitFor(() => p.player(LudoPlayerType.blue).pawns[0].step == -1),
        isTrue,
        reason: 'the blue pawn is sent back to base',
      );
      expect(
        await waitFor(() => p.gameState == LudoGameState.throwDice && !p.diceStarted),
        isTrue,
        reason: 'the capture rolls again',
      );
      expect(p.currentPlayer.type, LudoPlayerType.green);
      expect(p.capturesMade[LudoPlayerType.green], 1);
    });

    test('passes the turn when disabled', () async {
      final p = await captureMatch(captureGrantsRoll: false);
      addTearDown(p.dispose);

      p.throwDice();
      expect(
        await waitFor(() => p.currentPlayer.type == LudoPlayerType.blue),
        isTrue,
        reason: 'the turn passes after the capture',
      );
      expect(p.player(LudoPlayerType.blue).pawns[0].step, -1);
      expect(p.gameState, LudoGameState.throwDice);
    });
  });

  group('exact finish', () {
    test('an overshooting roll passes the turn instead of moving', () async {
      final p = LudoProvider();
      addTearDown(p.dispose);
      p.debugDiceRoll = () => 6;
      p.startGame(twoPlayer(exactFinish: true, extraRollOnSix: false));

      ///All four green pawns are one six short of the final cell
      final green = p.player(LudoPlayerType.green);
      for (int i = 0; i < 4; i++) {
        green.movePawn(i, 51 + i);
      }

      p.throwDice();
      expect(
        await waitFor(() => p.currentPlayer.type == LudoPlayerType.blue),
        isTrue,
        reason: 'no legal move means the turn passes',
      );
      for (int i = 0; i < 4; i++) {
        expect(green.pawns[i].step, 51 + i, reason: 'no pawn moved past the finish');
      }
      expect(p.gameState, LudoGameState.throwDice);
    });

    test('a relaxed finish clamps onto the final cell', () async {
      final p = LudoProvider();
      addTearDown(p.dispose);
      p.debugDiceRoll = () => 6;
      p.startGame(twoPlayer(exactFinish: false, extraRollOnSix: false));

      final green = p.player(LudoPlayerType.green);
      for (int i = 0; i < 4; i++) {
        green.movePawn(i, 51 + i);
      }

      p.throwDice();
      expect(await waitFor(() => p.gameState == LudoGameState.pickPawn), isTrue);
      p.pickAndMove(p.currentLegalMoves().first.pawnIndex);
      expect(
        await waitFor(() => p.currentPlayer.type == LudoPlayerType.blue),
        isTrue,
        reason: 'the clamped move ends the turn',
      );
      expect(green.pawns.where((pawn) => pawn.step == green.path.length - 1).length, 1);
    });
  });
}
