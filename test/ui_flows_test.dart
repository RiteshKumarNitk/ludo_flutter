import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/game_config.dart';
import 'package:ludo_flutter/ludo_provider.dart';
import 'package:ludo_flutter/main.dart';
import 'package:ludo_flutter/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

SettingsProvider settingsOf(WidgetTester tester) {
  final element = tester.element(find.byType(MaterialApp));
  return Provider.of<SettingsProvider>(element, listen: false);
}

LudoProvider gameOf(WidgetTester tester) {
  final element = tester.element(find.byType(MaterialApp));
  return Provider.of<LudoProvider>(element, listen: false);
}

Future<void> pumpApp(WidgetTester tester) async {
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

///Scroll the setup screen until [text] is on screen
Future<void> reveal(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 200,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Setup screen', () {
    testWidgets('rule toggles and CPU difficulty reach the GameConfig', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester);
      expect(find.text('LUDO'), findsOneWidget);

      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();
      expect(find.text('New Game'), findsOneWidget);

      ///Flip several rules (the list is scrollable)
      await reveal(tester, 'Three 6s forfeit');
      await tester.tap(find.text('Three 6s forfeit'));
      await tester.pumpAndSettle();
      await reveal(tester, 'Exact finish');
      await tester.tap(find.text('Exact finish')); //turn exact finish OFF
      await tester.pumpAndSettle();
      await reveal(tester, 'Blocking');
      await tester.tap(find.text('Blocking'));
      await tester.pumpAndSettle();

      ///Pick the hardest CPU difficulty
      await reveal(tester, 'CPU Difficulty');
      await tester.tap(find.text('Hard'));
      await tester.pumpAndSettle();

      await reveal(tester, 'Start Game');
      await tester.tap(find.text('Start Game'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      final config = gameOf(tester).config;
      expect(config.threeSixesForfeit, isTrue);
      expect(config.exactFinish, isFalse);
      expect(config.blocking, isTrue);
      expect(config.extraRollOnSix, isTrue); //untouched default
      expect(config.cpuDifficulty, CpuDifficulty.hard);
      expect(config.players.length, 4);
    });

    testWidgets('two player matches only seat green and blue', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester);

      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      await reveal(tester, 'Start Game');
      await tester.tap(find.text('Start Game'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      final game = gameOf(tester);
      expect(game.players.length, 2);
      expect(game.players.map((p) => p.type),
          containsAll([LudoPlayerType.green, LudoPlayerType.blue]));
      expect(find.byIcon(Icons.pause_circle_filled_rounded), findsOneWidget);
    });
  });

  group('Home screen resume', () {
    testWidgets('shows no resume button without a suspended match', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpApp(tester);
      expect(find.text('Resume Game'), findsNothing);
    });

    testWidgets('a suspended match can be resumed from the menu', (tester) async {
      ///Build a legitimate save payload
      final seed = LudoProvider();
      seed.startGame(const GameConfig(players: [
        PlayerSetup(color: LudoPlayerType.green, name: 'A'),
        PlayerSetup(color: LudoPlayerType.blue, name: 'B'),
      ]));
      seed.player(LudoPlayerType.green).movePawn(0, 9);
      final saved = jsonEncode(seed.toSaveJson());
      seed.dispose();

      SharedPreferences.setMockInitialValues({LudoProvider.saveKey: saved});
      await pumpApp(tester);
      expect(find.text('Resume Game'), findsOneWidget);

      await tester.tap(find.text('Resume Game'));

      ///No pumpAndSettle here: the dice ripple animates forever
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      ///We are back in the match with the pawn exactly where it was left
      expect(find.byIcon(Icons.pause_circle_filled_rounded), findsOneWidget);
      final game = gameOf(tester);
      expect(game.players.length, 2);
      expect(game.player(LudoPlayerType.green).pawns[0].step, 9);
      expect(game.player(LudoPlayerType.green).pawns[1].step, -1);
      expect(game.currentPlayer.type, LudoPlayerType.green);
    });

    testWidgets('quitting a resumed match drops the resume button', (tester) async {
      final seed = LudoProvider();
      seed.startGame(GameConfig.defaults(2));
      final saved = jsonEncode(seed.toSaveJson());
      seed.dispose();

      SharedPreferences.setMockInitialValues({LudoProvider.saveKey: saved});
      await pumpApp(tester);
      expect(find.text('Resume Game'), findsOneWidget);

      await tester.tap(find.text('Resume Game'));

      ///No pumpAndSettle here: the dice ripple animates forever
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byIcon(Icons.pause_circle_filled_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause_circle_filled_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Quit to Menu'));
      await tester.pumpAndSettle();

      expect(find.text('LUDO'), findsOneWidget);
      expect(find.text('Resume Game'), findsNothing);
      expect(await LudoProvider.savedMatchExists(), isFalse);
    });
  });
}
