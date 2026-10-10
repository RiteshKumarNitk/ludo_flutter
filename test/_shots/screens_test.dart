//Renders every screen at the three target phone sizes for visual review.
//Skipped in normal runs (see dart_test.yaml). Generate with:
//  flutter test --tags screenshots --run-skipped --update-goldens
//Images land in test/_shots/out/ (git-ignored).
@Tags(['screenshots'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_flutter/app/app.dart';
import 'package:ludo_flutter/app/screens/about_dialog.dart';
import 'package:ludo_flutter/core/navigation/app_routes.dart';
import 'package:ludo_flutter/games/ludo/controller/ludo_controller.dart';
import 'package:ludo_flutter/games/ludo/data/ludo_records.dart';
import 'package:ludo_flutter/games/ludo/data/ludo_save_store.dart';
import 'package:ludo_flutter/games/ludo/engine/ludo_engine.dart';
import 'package:ludo_flutter/games/ludo/ludo_routes.dart';
import 'package:ludo_flutter/games/ludo/models/ludo_models.dart';
import 'package:ludo_flutter/games/ludo/models/ludo_state.dart';
import 'package:ludo_flutter/shared/dialogs/game_dialogs.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ludo/test_support.dart';

///Real fonts so screenshots show actual text instead of test glyph boxes
Future<void> loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter';
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String f) async => ByteData.view((await File('$dir/$f').readAsBytes()).buffer);
  final roboto = FontLoader('Roboto');
  for (final f in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-black.ttf']) {
    roboto.addFont(read(f));
  }
  await roboto.load();
  //The app's bundled brand fonts
  ByteData asset(String path) => ByteData.view(File(path).readAsBytesSync().buffer);
  await (FontLoader('Baloo2')..addFont(Future.value(asset('assets/fonts/Baloo2-Variable.ttf')))).load();
  final hind = FontLoader('Hind');
  for (final w in ['Regular', 'Medium', 'SemiBold']) {
    hind.addFont(Future.value(asset('assets/fonts/Hind-$w.ttf')));
  }
  await hind.load();
  await (FontLoader('MaterialIcons')..addFont(read('materialicons-regular.otf'))).load();
}

Future<void> frames(WidgetTester tester, [int ms = 1500]) async {
  for (int t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

NavigatorState nav(WidgetTester t) => t.state<NavigatorState>(find.byType(Navigator).first);
T read<T>(WidgetTester t) => Provider.of<T>(t.element(find.byType(Navigator).first), listen: false);

Future<void> shot(WidgetTester tester, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('out/$name.png'));

const fourSeats = LudoMatchConfig(
  mode: LudoMode.vsComputer,
  difficulty: BotDifficulty.medium,
  seats: [
    LudoSeat(color: LudoColor.red, name: 'You'),
    LudoSeat(color: LudoColor.green, name: 'Green', isBot: true),
    LudoSeat(color: LudoColor.yellow, name: 'Yellow', isBot: true),
    LudoSeat(color: LudoColor.blue, name: 'Blue', isBot: true),
  ],
);

LudoState midGame() => LudoEngine.start(fourSeats.seats).copyWith(steps: {
      LudoColor.red: const [-1, 3, 14, 54],
      LudoColor.green: const [5, -1, -1, 56],
      LudoColor.yellow: const [-1, -1, 30, 30],
      LudoColor.blue: const [-1, 40, 56, 56],
    });

LudoState finished(LudoColor winner) {
  final others = [for (final s in fourSeats.seats) if (s.color != winner) s.color];
  return LudoEngine.start(fourSeats.seats).copyWith(
    phase: LudoPhase.finished,
    ranking: [winner, ...others],
    steps: {
      for (final s in fourSeats.seats) s.color: s.color == winner ? const [56, 56, 56, 56] : const [56, 30, -1, -1],
    },
    stats: {for (final s in fourSeats.seats) s.color: const SeatStats(captures: 2, captured: 1, sixes: 4, turns: 23)},
  );
}

void main() {
  setUpAll(loadFonts);
  const sizes = {'a320': Size(320, 568), 'b390': Size(390, 844), 'c430': Size(430, 932)};
  for (final e in sizes.entries) {
    testWidgets('splash ${e.key}', (tester) async {
      SharedPreferences.setMockInitialValues({'settings_sound': false});
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = e.value * 2;
      tester.view.padding = const FakeViewPadding(top: 48, bottom: 32);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const BoardGamesApp());
      await frames(tester, 500);
      await shot(tester, '${e.key}_00a_splash_mid');
      await frames(tester, 1000);
      await shot(tester, '${e.key}_00b_splash_end');
      await frames(tester, 1500);
      await tester.pumpWidget(const SizedBox());
      await frames(tester, 2000);
    });

    testWidgets('screens ${e.key}', (tester) async {
      SharedPreferences.setMockInitialValues({'settings_sound': false, 'settings_haptics': false});
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = e.value * 2;
      tester.view.padding = const FakeViewPadding(top: 48, bottom: 32);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const BoardGamesApp(initialRoute: AppRoutes.home));
      await frames(tester);
      final k = e.key;
      final c = read<LudoController>(tester);

      await shot(tester, '${k}_01_home');
      showExitDialog(tester.element(find.byType(Scaffold).last),
          title: 'Exit Khelora?', message: 'Are you sure you want to exit the game?', stayLabel: 'STAY', exitLabel: 'EXIT');
      await frames(tester, 600);
      await shot(tester, '${k}_01b_exit_dialog');
      nav(tester).pop();
      await frames(tester, 400);

      nav(tester).pushNamed(LudoRoutes.setup);
      await frames(tester);
      await shot(tester, '${k}_02_setup');
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -600));
      await frames(tester, 600);
      await shot(tester, '${k}_03_setup_seats');
      nav(tester).pop();
      await frames(tester);

      //Game: your turn to roll
      c.debugShow(fourSeats, midGame());
      nav(tester).pushNamed(LudoRoutes.game);
      await frames(tester);
      await shot(tester, '${k}_04_game_roll');

      //Rolled a 6: choose a glowing pawn
      c.debugShow(fourSeats, LudoEngine.roll(midGame(), 6).state);
      await frames(tester, 600);
      await shot(tester, '${k}_05_game_pick');

      //Bot's turn
      c.debugShow(fourSeats, midGame().copyWith(turn: 2));
      c.pause();
      await frames(tester, 600);
      c.resume();
      c.pause(); //freeze the bot so the frame is stable
      await frames(tester, 300);
      await shot(tester, '${k}_06_game_bot_turn');

      //Pause menu
      showPauseMenu(tester.element(find.byType(Scaffold).last));
      await frames(tester, 600);
      await shot(tester, '${k}_07_pause');
      nav(tester).pop();
      await frames(tester, 400);
      showConfirmDialog(tester.element(find.byType(Scaffold).last),
          title: 'Quit match?', message: 'This match will end and its progress will be lost.', confirmLabel: 'QUIT',
          icon: Icons.logout_rounded, destructive: true);
      await frames(tester, 600);
      await shot(tester, '${k}_08_quit_confirm');
      nav(tester).pop();
      await frames(tester, 400);

      //Leave keeps the match: home shows Continue
      await c.leave();
      nav(tester).popUntil((r) => r.isFirst);
      await LudoSaveStore().save(LudoSavedMatch(matchId: 'x', config: fourSeats, state: midGame(), elapsed: Duration.zero));
      nav(tester).pushNamed(AppRoutes.settings);
      await frames(tester, 600);
      await shot(tester, '${k}_09_settings');
      showAppAboutDialog(tester.element(find.byType(Scaffold).last));
      await frames(tester, 600);
      await shot(tester, '${k}_09b_about');
      nav(tester).pop();
      await frames(tester, 400);
      nav(tester).pop();
      await frames(tester);
      await shot(tester, '${k}_10_home_continue');

      for (final (name, state) in [('11_result_win', finished(LudoColor.red)), ('12_result_loss', finished(LudoColor.green))]) {
        c.debugShow(fourSeats, state);
        nav(tester).pushNamed(LudoRoutes.result);
        await frames(tester, 2000);
        await shot(tester, '${k}_$name');
        nav(tester).pop();
        await frames(tester);
      }

      nav(tester).pushNamed(LudoRoutes.records);
      await frames(tester);
      await shot(tester, '${k}_13_records_empty');
      nav(tester).pop();
      await frames(tester);

      final records = read<LudoRecords>(tester);
      for (int i = 0; i < 3; i++) {
        records.recordMatch(matchId: 'w$i', config: duel(), state: finishedState(duel(), LudoColor.red));
      }
      records.recordMatch(matchId: 'l', config: duel(), state: finishedState(duel(), LudoColor.yellow));
      nav(tester).pushNamed(LudoRoutes.records);
      await frames(tester);
      await shot(tester, '${k}_14_records');
      await tester.tap(find.text('Achievements'));
      await frames(tester);
      await shot(tester, '${k}_15_achievements');
      nav(tester).pop();
      await frames(tester);

      nav(tester).pushNamed(LudoRoutes.howToPlay);
      await frames(tester);
      await shot(tester, '${k}_16_howto');
      nav(tester).pop();
      await frames(tester);

      await tester.pumpWidget(const SizedBox());
      await frames(tester, 2000);
    });
  }
}
