import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n/app_strings.dart';
import '../core/navigation/app_routes.dart';
import '../core/navigation/route_observer.dart';
import '../core/settings/app_settings.dart';
import '../core/theme/app_theme.dart';
import '../games/game_catalog.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';

const String appVersion = '1.0.0';

class BoardGamesApp extends StatelessWidget {
  static final Map<String, WidgetBuilder> _routes = {
    AppRoutes.splash: (_) => const SplashScreen(),
    AppRoutes.home: (_) => const HomeScreen(),
    AppRoutes.settings: (_) => const SettingsScreen(),
    for (final game in GameCatalog.games) ...game.routes,
  };

  ///Skips the splash screen (used by tests)
  final String initialRoute;

  const BoardGamesApp({super.key, this.initialRoute = AppRoutes.splash});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()..load()),
        for (final game in GameCatalog.games) ...game.providers,
      ],
      child: MaterialApp(
        title: 'Khelora',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        localizationsDelegates: const [AppStrings.delegate],
        supportedLocales: const [Locale('en')],
        navigatorObservers: [appRouteObserver],
        initialRoute: initialRoute,
        routes: _routes,
        //Open exactly the requested route (no implicit parent routes)
        onGenerateInitialRoutes: (name) => [
          MaterialPageRoute<void>(
            settings: RouteSettings(name: name),
            builder: _routes[name] ?? _routes[AppRoutes.splash]!,
          ),
        ],
      ),
    );
  }
}
