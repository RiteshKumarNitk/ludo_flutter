import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_flutter/app/app.dart';
import 'package:ludo_flutter/core/navigation/app_routes.dart';
import 'package:ludo_flutter/games/ludo/controller/ludo_controller.dart';
import 'package:ludo_flutter/games/ludo/engine/ludo_engine.dart';
import 'package:ludo_flutter/games/ludo/ludo_routes.dart';
import 'package:ludo_flutter/games/ludo/models/ludo_models.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ludo/test_support.dart';

const sizes = {
  'small 320x568': Size(320, 568),
  'normal 390x844': Size(390, 844),
  'large 430x932': Size(430, 932),
};

Future<void> launch(WidgetTester tester, Size size, {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues({'settings_sound': false, 'settings_haptics': false, ...prefs});
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = size * 3;
  tester.view.padding = const FakeViewPadding(top: 72, bottom: 48); //notch + gesture bar
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const BoardGamesApp(initialRoute: AppRoutes.home));
  await frames(tester);
}

///Advance animations without waiting for the endless idle loops to settle
Future<void> frames(WidgetTester tester, [int ms = 1200]) async {
  for (int t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

LudoController controllerOf(WidgetTester tester) =>
    Provider.of<LudoController>(tester.element(find.byType(Navigator).first), listen: false);

Future<void> openRoute(WidgetTester tester, String route) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pushNamed(route);
  await frames(tester);
}

///Scroll lazy lists until [text] is built and on screen
Future<void> reveal(WidgetTester tester, String text) async {
  if (find.text(text).evaluate().isEmpty) {
    await tester.scrollUntilVisible(find.text(text), 150, scrollable: find.byType(Scrollable).last);
  }
  await tester.ensureVisible(find.text(text).last);
  await tester.pump();
}

Future<void> tapText(WidgetTester tester, String text) async {
  await reveal(tester, text);
  await tester.tap(find.text(text).last);
  await frames(tester, 600);
}

///Leave the game screen and let every timer finish before the test ends
Future<void> tearDownMatch(WidgetTester tester) async {
  await controllerOf(tester).quit();
  await tester.pumpWidget(const SizedBox());
  await frames(tester, 2000);
}

void main() {
  for (final entry in sizes.entries) {
    group(entry.key, () {
      testWidgets('home → setup → game, with leave confirmation on back', (tester) async {
        await launch(tester, entry.value);
        expect(find.text('PLAY'), findsOneWidget);
        expect(find.text('COMING SOON'), findsNWidgets(3));

        await tapText(tester, 'PLAY');
        expect(find.text('START GAME'), findsOneWidget);
        expect(find.textContaining('Extra roll'), findsNothing, reason: 'no rule switches');
        await tapText(tester, 'PASS & PLAY');
        expect(find.text('DIFFICULTY'), findsNothing, reason: 'no bots, no difficulty');
        await tapText(tester, 'VS COMPUTER');
        expect(find.text('DIFFICULTY'), findsOneWidget);

        await tapText(tester, 'START GAME');
        expect(find.text('LUDO'), findsOneWidget);
        expect(find.textContaining('YOUR TURN', findRichText: true), findsOneWidget);
        expect(find.textContaining('Tap the dice', findRichText: true), findsWidgets);

        //Android back asks before leaving
        await tester.binding.handlePopRoute();
        await frames(tester, 600);
        expect(find.text('Leave game?'), findsOneWidget);
        await tapText(tester, 'CONTINUE');
        expect(find.textContaining('YOUR TURN', findRichText: true), findsOneWidget, reason: 'still in the game');

        await tester.binding.handlePopRoute();
        await frames(tester, 600);
        await tapText(tester, 'LEAVE GAME');
        await frames(tester);
        expect(find.text('CONTINUE'), findsOneWidget, reason: 'saved match offered on home');
        expect(find.text('vs Computer'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await frames(tester, 2000);
      });

      testWidgets('pause: restart and quit need confirmation', (tester) async {
        await launch(tester, entry.value);
        controllerOf(tester).startMatch(duel());
        await openRoute(tester, LudoRoutes.game);

        await tester.tap(find.byTooltip('Pause'));
        await frames(tester, 600);
        expect(find.text('PAUSED'), findsOneWidget);
        await tapText(tester, 'RESTART');
        expect(find.text('Restart match?'), findsOneWidget);
        await tester.tapAt(const Offset(5, 5)); //outside the dialog
        await frames(tester, 600);
        expect(find.text('Restart match?'), findsOneWidget, reason: 'destructive dialogs ignore outside taps');
        await tapText(tester, 'CANCEL');
        expect(find.text('PAUSED'), findsOneWidget, reason: 'back on the pause menu');

        await tapText(tester, 'QUIT');
        expect(find.text('Quit match?'), findsOneWidget);
        await tapText(tester, 'QUIT');
        await frames(tester);
        expect(find.text('PLAY'), findsOneWidget, reason: 'quit returns home with no saved match');
        expect(find.text('CONTINUE'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        await frames(tester, 2000);
      });

      testWidgets('a busy board fits without overflow', (tester) async {
        await launch(tester, entry.value);
        const config = LudoMatchConfig(
          mode: LudoMode.vsComputer,
          difficulty: BotDifficulty.medium,
          seats: [
            LudoSeat(color: LudoColor.red, name: 'Rahul'),
            LudoSeat(color: LudoColor.green, name: 'Green Bot', isBot: true),
            LudoSeat(color: LudoColor.yellow, name: 'Yellow Bot', isBot: true),
            LudoSeat(color: LudoColor.blue, name: 'Blue Bot', isBot: true),
          ],
        );
        final start = LudoEngine.start(config.seats);
        final state = start.copyWith(steps: {
          LudoColor.red: const [0, 14, 14, 56],
          LudoColor.green: const [1, 8, -1, 53],
          LudoColor.yellow: const [-1, -1, 30, 30],
          LudoColor.blue: const [5, 40, 51, -1],
        }, dice: () => 6);
        controllerOf(tester).debugShow(config, state);
        await openRoute(tester, LudoRoutes.game);
        expect(find.text('Rahul'), findsOneWidget);
        expect(find.text('Yellow Bot'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tearDownMatch(tester);
      });

      testWidgets('result screen: win, loss and pass & play', (tester) async {
        await launch(tester, entry.value);
        final c = controllerOf(tester);

        c.debugShow(duel(), finishedState(duel(), LudoColor.red));
        await openRoute(tester, LudoRoutes.result);
        expect(find.text('YOU WIN!'), findsOneWidget);
        expect(find.text('WINNER'), findsOneWidget);
        for (final label in ['PLAY AGAIN', 'NEW GAME', 'HOME']) {
          await reveal(tester, label);
          expect(find.text(label), findsOneWidget);
        }
        await tapText(tester, 'HOME');
        expect(find.text('PLAY'), findsOneWidget);

        c.debugShow(duel(), finishedState(duel(), LudoColor.yellow));
        await openRoute(tester, LudoRoutes.result);
        expect(find.text('YOU LOST'), findsOneWidget);
        expect(find.text('Better luck next time!'), findsOneWidget);
        await tester.binding.handlePopRoute(); //Android back from the result goes home
        await frames(tester);
        expect(find.text('PLAY'), findsOneWidget);

        final friends = duel(yellowIsBot: false);
        c.debugShow(friends, finishedState(friends, LudoColor.yellow));
        await openRoute(tester, LudoRoutes.result);
        expect(find.text('GAME OVER'), findsOneWidget);
        expect(find.text('YELLOW WINS!'), findsOneWidget);
        await tapText(tester, 'PLAY AGAIN');
        expect(find.text('LUDO'), findsOneWidget, reason: 'rematch opens the game');
        await tearDownMatch(tester);
      });

      testWidgets('records, settings and how to play', (tester) async {
        await launch(tester, entry.value);
        await tester.tap(find.byTooltip('Records'));
        await frames(tester);
        expect(find.text('No matches yet'), findsOneWidget);
        await tapText(tester, 'Achievements');
        expect(find.text('0 of 10 unlocked'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await frames(tester);

        await tester.tap(find.byTooltip('Settings'));
        await frames(tester);
        expect(find.text('Board theme'), findsOneWidget);
        expect(find.textContaining('Extra roll'), findsNothing);
        await tapText(tester, 'RESET SETTINGS');
        expect(find.text('Reset settings?'), findsOneWidget);
        await tapText(tester, 'CANCEL');
        await tester.binding.handlePopRoute();
        await frames(tester);

        await tapText(tester, 'About');
        expect(find.text('Innovatex Technology Pvt. Ltd.'), findsOneWidget);
        expect(find.textContaining('does not collect'), findsOneWidget);
        await tapText(tester, 'OPEN-SOURCE LICENSES');
        expect(find.byType(LicensePage), findsOneWidget);
        await tester.binding.handlePopRoute();
        await frames(tester);
        await tapText(tester, 'CLOSE');

        await tapText(tester, 'How to play');
        await reveal(tester, '8 safe cells');
        expect(find.text('8 safe cells'), findsOneWidget);
        expect(find.textContaining('turned off'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        await frames(tester, 2000);
      });
    });
  }
}
