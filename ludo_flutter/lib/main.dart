import 'package:flutter/material.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/ludo_provider.dart';
import 'package:ludo_flutter/pages/game_over_screen.dart';
import 'package:ludo_flutter/pages/game_screen.dart';
import 'package:ludo_flutter/pages/home_screen.dart';
import 'package:ludo_flutter/pages/how_to_play_screen.dart';
import 'package:ludo_flutter/pages/setup_screen.dart';
import 'package:ludo_flutter/pages/settings_screen.dart';
import 'package:ludo_flutter/pages/splash_screen.dart';
import 'package:ludo_flutter/settings_provider.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  return runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => LudoProvider()),
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
      routes: {
        '/': (_) => const SplashScreen(),
        '/home': (_) => const HomeScreen(),
        '/setup': (_) => const SetupScreen(),
        '/game': (_) => const GameScreen(),
        '/gameOver': (_) => const GameOverScreen(),
        '/howToPlay': (_) => const HowToPlayScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
