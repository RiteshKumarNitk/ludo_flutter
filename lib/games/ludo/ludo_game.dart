import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/game_card.dart';
import '../game_definition.dart';
import 'controller/ludo_controller.dart';
import 'data/ludo_preferences.dart';
import 'data/ludo_records.dart';
import 'ludo_routes.dart';
import 'ludo_strings.dart';
import 'screens/ludo_game_screen.dart';
import 'screens/ludo_how_to_play_screen.dart';
import 'screens/ludo_records_screen.dart';
import 'screens/ludo_result_screen.dart';
import 'screens/ludo_setup_screen.dart';
import 'widgets/ludo_artwork.dart';

///Ludo's entry in the game catalog
final GameDefinition ludoGame = GameDefinition(
  id: 'ludo',
  title: 'Ludo',
  tagline: const LudoStrings().tagline,
  icon: Icons.casino_rounded,
  accent: AppColors.primary,
  artwork: (context, size) => LudoArtwork(theme: context.watch<LudoPreferences>().theme, size: size),
  playRoute: LudoRoutes.setup,
  howToPlayRoute: LudoRoutes.howToPlay,
  recordsRoute: LudoRoutes.records,
  routes: {
    LudoRoutes.setup: (_) => const LudoSetupScreen(),
    LudoRoutes.game: (_) => const LudoGameScreen(),
    LudoRoutes.result: (_) => const LudoResultScreen(),
    LudoRoutes.howToPlay: (_) => const LudoHowToPlayScreen(),
    LudoRoutes.records: (_) => const LudoRecordsScreen(),
  },
  providers: [
    ChangeNotifierProvider(create: (_) => LudoPreferences()..load()),
    ChangeNotifierProvider(create: (_) => LudoRecords()..load()),
    ChangeNotifierProvider(
      create: (context) => LudoController(
        records: context.read<LudoRecords>(),
        settings: context.read<AppSettings>(),
      ),
    ),
  ],
  settingsSection: (context) {
    final prefs = context.watch<LudoPreferences>();
    final t = LudoStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(t.sectionTitle),
        GameCard(
          shadows: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.boardTheme, style: AppTypography.subtitle),
              const SizedBox(height: AppSpacing.md),
              BoardThemePicker(selected: prefs.boardTheme, onChanged: prefs.setBoardTheme),
            ],
          ),
        ),
      ],
    );
  },
  resetSettings: (context) => context.read<LudoPreferences>().resetTheme(),
  findResumable: (context) async {
    final summary = await context.read<LudoController>().savedSummary();
    return summary == null ? null : ResumableMatch(const LudoStrings().resumeSummary(summary));
  },
  resume: (context) async {
    final navigator = Navigator.of(context);
    final ok = await context.read<LudoController>().loadSaved();
    if (ok) navigator.pushNamed(LudoRoutes.game);
    return ok;
  },
);
