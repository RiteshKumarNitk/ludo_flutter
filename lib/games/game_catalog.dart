import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'game_definition.dart';
import 'ludo/ludo_game.dart';

///Every game the launcher knows about, featured game first
class GameCatalog {
  const GameCatalog._();

  static final List<GameDefinition> games = [
    ludoGame,
    const GameDefinition.comingSoon(
      id: 'snakes_ladders',
      title: 'Snakes & Ladders',
      tagline: 'Climb up, slide down',
      icon: Icons.stairs_rounded,
      accent: AppColors.playerGreen,
    ),
    const GameDefinition.comingSoon(
      id: 'chess',
      title: 'Chess',
      tagline: 'The classic duel',
      icon: Icons.castle_rounded,
      accent: AppColors.playerBlue,
    ),
    const GameDefinition.comingSoon(
      id: 'carrom',
      title: 'Carrom',
      tagline: 'Flick and pocket',
      icon: Icons.adjust_rounded,
      accent: AppColors.playerRed,
    ),
  ];

  static GameDefinition get featured => games.firstWhere((g) => g.isAvailable);

  static Iterable<GameDefinition> get available => games.where((g) => g.isAvailable);

  static Iterable<GameDefinition> get comingSoon => games.where((g) => !g.isAvailable);
}
