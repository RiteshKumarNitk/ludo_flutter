import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_flutter/audio.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/game_config.dart';
import 'package:ludo_flutter/ludo_provider.dart';
import 'package:ludo_flutter/main.dart';
import 'package:ludo_flutter/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LudoProvider', () {
    test('startGame creates the configured players', () {
      final provider = LudoProvider();
      provider.startGame(const GameConfig(players: [
        PlayerSetup(color: LudoPlayerType.green, name: 'Rit'),
        PlayerSetup(color: LudoPlayerType.blue, name: 'Sam', isCpu: true),
      ]));

      expect(provider.players.length, 2);
      expect(provider.currentPlayer.type, LudoPlayerType.green);
      expect(provider.gameState, LudoGameState.throwDice);
      expect(provider.isFinished, isFalse);
      expect(provider.player(LudoPlayerType.green).name, 'Rit');
      expect(provider.player(LudoPlayerType.blue).isCpu, isTrue);
      provider.dispose();
    });

    test('nextTurn cycles only through active players', () {
      final provider = LudoProvider();
      provider.startGame(const GameConfig(players: [
        PlayerSetup(color: LudoPlayerType.green, name: 'A'),
        PlayerSetup(color: LudoPlayerType.blue, name: 'B'),
      ]));

      provider.nextTurn();
      expect(provider.currentPlayer.type, LudoPlayerType.blue);
      provider.nextTurn();
      expect(provider.currentPlayer.type, LudoPlayerType.green);
      provider.dispose();
    });

    test('nextTurn skips players that already won', () {
      final provider = LudoProvider();
      provider.startGame(const GameConfig(players: [
        PlayerSetup(color: LudoPlayerType.green, name: 'A'),
        PlayerSetup(color: LudoPlayerType.yellow, name: 'B'),
        PlayerSetup(color: LudoPlayerType.blue, name: 'C'),
      ]));

      provider.winners.add(LudoPlayerType.green);
      provider.nextTurn();
      expect(provider.currentPlayer.type, LudoPlayerType.yellow);
      provider.dispose();
    });

    test('match finishes when all but one player completed', () {
      final provider = LudoProvider();
      provider.startGame(const GameConfig(players: [
        PlayerSetup(color: LudoPlayerType.green, name: 'A'),
        PlayerSetup(color: LudoPlayerType.blue, name: 'B'),
      ]));

      final green = provider.player(LudoPlayerType.green);
      for (int i = 0; i < green.pawns.length; i++) {
        green.movePawn(i, green.path.length - 1);
      }
      provider.validateWin(LudoPlayerType.green);

      expect(provider.winners, [LudoPlayerType.green]);
      expect(provider.isFinished, isTrue);
      provider.dispose();
    });

    test('restartGame resets pawns, winners and turn', () {
      final provider = LudoProvider();
      const config = GameConfig(players: [
        PlayerSetup(color: LudoPlayerType.green, name: 'A'),
        PlayerSetup(color: LudoPlayerType.red, name: 'B'),
      ]);
      provider.startGame(config);

      final red = provider.player(LudoPlayerType.red);
      red.movePawn(0, 5);
      provider.winners.add(LudoPlayerType.red);
      provider.restartGame();

      expect(provider.winners, isEmpty);
      expect(provider.players.length, 2);
      expect(provider.player(LudoPlayerType.red).pawns.every((p) => p.step == -1), isTrue);
      expect(provider.currentPlayer.type, LudoPlayerType.green);
      expect(provider.config.players.first.name, 'A');
      provider.dispose();
    });

    test('cpu player rolls the dice automatically', () async {
      final soundWasEnabled = Audio.enabled;
      Audio.enabled = false;
      addTearDown(() => Audio.enabled = soundWasEnabled);

      final provider = LudoProvider();
      provider.startGame(const GameConfig(players: [
        PlayerSetup(color: LudoPlayerType.green, name: 'CPU', isCpu: true),
        PlayerSetup(color: LudoPlayerType.blue, name: 'Human'),
      ]));
      expect(provider.isCpuTurn, isTrue);

      ///The computer starts its turn on its own, no human input
      bool cpuStarted = false;
      for (int i = 0; i < 50 && !cpuStarted; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        cpuStarted = provider.diceStarted ||
            provider.gameState != LudoGameState.throwDice ||
            !provider.isCpuTurn;
      }
      expect(cpuStarted, isTrue);

      ///...and the roll resolves without any human input
      bool resolved = false;
      for (int i = 0; i < 50 && !resolved; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        resolved = !provider.diceStarted &&
            (provider.gameState != LudoGameState.throwDice || !provider.isCpuTurn);
      }
      expect(resolved, isTrue);
      provider.dispose();
    });
  });

  group('App flow', () {
    Future<void> pumpApp(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
            ChangeNotifierProvider(create: (_) => LudoProvider()),
          ],
          child: const Root(),
        ),
      );
      await tester.pump();

      ///Splash routes to the menu after ~1.8s
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }

    testWidgets('splash -> home -> setup -> game -> pause -> quit', (tester) async {
      await pumpApp(tester);
      expect(find.text('LUDO'), findsOneWidget);
      expect(find.text('How to Play'), findsOneWidget);

      ///Home -> Setup
      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();
      expect(find.text('New Game'), findsOneWidget);

      ///The start button sits below the fold on small screens
      await tester.scrollUntilVisible(find.text('Start Game'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(find.text('Start Game'), findsOneWidget);

      ///Setup -> Game
      await tester.tap(find.text('Start Game'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byIcon(Icons.pause_circle_filled_rounded), findsOneWidget);
      expect(find.text('Tap the dice to roll'), findsOneWidget);

      ///Pause menu -> Quit to menu (no pumpAndSettle: the board animates forever)
      await tester.tap(find.byIcon(Icons.pause_circle_filled_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Quit to Menu'), findsOneWidget);

      await tester.tap(find.text('Quit to Menu'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('LUDO'), findsOneWidget);
      expect(find.byIcon(Icons.pause_circle_filled_rounded), findsNothing);
    });

    testWidgets('how to play and settings are reachable from the menu', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('How to Play'));
      await tester.pumpAndSettle();
      expect(find.text('Objective'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('LUDO'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Sound effects'), findsOneWidget);
      expect(find.text('Animation speed'), findsOneWidget);

      ///Settings are persisted
      await tester.tap(find.text('Fast'));
      await tester.pumpAndSettle();
      final settings = contextOf(tester);
      expect(settings.animationSpeed, 1.6);
    });
  });
}

SettingsProvider contextOf(WidgetTester tester) {
  final element = tester.element(find.byType(MaterialApp));
  return Provider.of<SettingsProvider>(element, listen: false);
}
