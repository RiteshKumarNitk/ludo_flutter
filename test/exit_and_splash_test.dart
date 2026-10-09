import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_flutter/app/app.dart';
import 'package:ludo_flutter/app/screens/home_screen.dart';
import 'package:ludo_flutter/app/screens/splash_screen.dart';
import 'package:ludo_flutter/core/navigation/app_routes.dart';
import 'package:ludo_flutter/games/ludo/controller/ludo_controller.dart';
import 'package:ludo_flutter/games/ludo/ludo_routes.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ludo/test_support.dart';

Future<void> frames(WidgetTester tester, [int ms = 1200]) async {
  for (int t = 0; t < ms; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

///Records SystemNavigator.pop calls instead of closing the test app
List<String> trackSystemCalls(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    calls.add(call.method);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  return calls;
}

Future<void> launch(WidgetTester tester, {String route = AppRoutes.home}) async {
  SharedPreferences.setMockInitialValues({'settings_sound': false, 'settings_haptics': false});
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = const Size(390, 844) * 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(BoardGamesApp(initialRoute: route));
  await frames(tester);
}

Future<void> finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await frames(tester, 2000);
}

void main() {
  testWidgets('the intro plays once, then leaves exactly one Home', (tester) async {
    await launch(tester, route: AppRoutes.splash);
    await frames(tester, 2500);
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Play Your Way.'), findsOneWidget);

    //Back from Home asks to exit instead of revealing a second Home or the intro
    await tester.binding.handlePopRoute();
    await frames(tester, 600);
    expect(find.text('Exit Khelora?'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    await finish(tester);
  });

  testWidgets('Back on Home: Stay keeps the app open', (tester) async {
    final calls = trackSystemCalls(tester);
    await launch(tester);
    await tester.binding.handlePopRoute();
    await frames(tester, 600);
    expect(find.text('Exit Khelora?'), findsOneWidget);
    expect(find.text('Are you sure you want to exit the game?'), findsOneWidget);

    await tester.tap(find.text('STAY'));
    await frames(tester, 600);
    expect(find.text('Exit Khelora?'), findsNothing);
    expect(find.text('PLAY'), findsOneWidget);
    expect(calls, isNot(contains('SystemNavigator.pop')));
    await finish(tester);
  });

  testWidgets('repeated Back presses never stack exit dialogs', (tester) async {
    final calls = trackSystemCalls(tester);
    await launch(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.binding.handlePopRoute(); //closes the dialog (= Stay)
    await frames(tester, 600);
    expect(find.text('Exit Khelora?'), findsNothing);
    expect(find.byType(Dialog), findsNothing);
    expect(calls, isNot(contains('SystemNavigator.pop')));

    await tester.binding.handlePopRoute();
    await frames(tester, 600);
    expect(find.text('Exit Khelora?'), findsOneWidget, reason: 'it opens again normally');
    expect(find.byType(Dialog), findsOneWidget);
    await finish(tester);
  });

  testWidgets('Exit closes the app and keeps the saved match', (tester) async {
    final calls = trackSystemCalls(tester);
    await launch(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    final controller = Provider.of<LudoController>(tester.element(find.byType(Navigator).first), listen: false);
    controller.startMatch(duel());
    await controller.leave(); //a saved match exists
    nav.pushNamed(AppRoutes.settings); //Home refreshes when it becomes visible again
    await frames(tester);
    nav.pop();
    await frames(tester);
    expect(find.text('CONTINUE'), findsOneWidget);

    //The visible Exit button opens the same confirmation
    await tester.scrollUntilVisible(find.text('Exit'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Exit'));
    await frames(tester, 600);
    await tester.tap(find.text('EXIT'));
    await frames(tester, 600);
    expect(calls, contains('SystemNavigator.pop'));
    expect(await controller.savedSummary(), isNotNull, reason: 'exiting never deletes the saved match');
    await finish(tester);
  });

  testWidgets('Back on secondary screens follows the hierarchy, not the exit dialog', (tester) async {
    await launch(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    for (final route in [LudoRoutes.setup, AppRoutes.settings, LudoRoutes.records, LudoRoutes.howToPlay]) {
      nav.pushNamed(route);
      await frames(tester);
      await tester.binding.handlePopRoute();
      await frames(tester);
      expect(find.text('Exit Khelora?'), findsNothing, reason: route);
      expect(find.text('PLAY'), findsOneWidget, reason: 'back on Home from $route');
    }

    //The game keeps its own leave confirmation
    final controller = Provider.of<LudoController>(tester.element(find.byType(Navigator).first), listen: false);
    controller.startMatch(duel());
    nav.pushNamed(LudoRoutes.game);
    await frames(tester);
    await tester.binding.handlePopRoute();
    await frames(tester, 600);
    expect(find.text('Leave game?'), findsOneWidget);
    expect(find.text('Exit Khelora?'), findsNothing);
    await controller.quit();
    await finish(tester);
  });
}
