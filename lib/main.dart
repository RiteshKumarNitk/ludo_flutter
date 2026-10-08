import 'package:flutter/material.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/l10n/app_strings.dart';
import 'package:ludo_flutter/ludo_provider.dart';
import 'package:ludo_flutter/pages/achievements_screen.dart';
import 'package:ludo_flutter/pages/game_over_screen.dart';
import 'package:ludo_flutter/pages/game_screen.dart';
import 'package:ludo_flutter/pages/home_screen.dart';
import 'package:ludo_flutter/pages/how_to_play_screen.dart';
import 'package:ludo_flutter/pages/setup_screen.dart';
import 'package:ludo_flutter/pages/settings_screen.dart';
import 'package:ludo_flutter/pages/splash_screen.dart';
import 'package:ludo_flutter/pages/stats_screen.dart';
import 'package:ludo_flutter/settings_provider.dart';
import 'package:ludo_flutter/stats_provider.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  return runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => LudoProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()..load()),
      ],
      child: const Root(),
    ),
  );
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ludo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: LudoColor.green,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF14141f),
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(LudoColor.green),
        ),
      ),
      initialRoute: '/',

      ///Localization: English only for now, the infrastructure is in place
      ///(see lib/l10n/app_strings.dart for how to add a language)
      localizationsDelegates: const [AppStrings.delegate],
      supportedLocales: const [Locale('en')],
      routes: {
        '/': (_) => const SplashScreen(),
        '/home': (_) => const HomeScreen(),
        '/setup': (_) => const SetupScreen(),
        '/game': (_) => const GameScreen(),
        '/gameOver': (_) => const GameOverScreen(),
        '/howToPlay': (_) => const HowToPlayScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/stats': (_) => const StatsScreen(),
        '/achievements': (_) => const AchievementsScreen(),
      },
    );
  }
}
