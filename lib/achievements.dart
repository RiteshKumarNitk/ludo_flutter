import 'package:flutter/material.dart';

import 'constants.dart';
import 'game_config.dart';
import 'stats_provider.dart';

///A single unlockable milestone. The [unlocked] predicate is a pure
///function of the current [StatsProvider], so no extra state has to be
///persisted - the achievements always reflect the recorded stats.
class Achievement {
  ///Stable identifier, usable as a persistence key later on
  final String id;

  ///One-line display name
  final String title;

  ///Explains what the player has to do to unlock it
  final String description;

  ///Icon shown inside the achievement badge
  final IconData icon;

  ///Pure predicate deciding whether the stats currently satisfy the goal
  final bool Function(StatsProvider stats) unlocked;

  ///Create an achievement; normally declared const inside [kAchievements]
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
  });
}

///Every achievement the game offers, easiest first.
///
///Titles/descriptions are const English for now (see `l10n/app_strings.dart`);
///to localize, move them behind [AppStrings] and key them by [Achievement.id].
const List<Achievement> kAchievements = [
  Achievement(
    id: 'first_win',
    title: 'First Victory',
    description: 'Win your first match',
    icon: Icons.star_rounded,
    unlocked: _firstWin,
  ),
  Achievement(
    id: 'streak_5',
    title: 'On Fire',
    description: 'Win 5 matches in a row',
    icon: Icons.local_fire_department_rounded,
    unlocked: _streakOfFive,
  ),
  Achievement(
    id: 'wins_10',
    title: 'Double Digits',
    description: 'Win 10 matches in total',
    icon: Icons.workspace_premium_rounded,
    unlocked: _tenWins,
  ),
  Achievement(
    id: 'all_colors',
    title: 'Rainbow Racer',
    description: 'Win a match with all four colors',
    icon: Icons.palette_rounded,
    unlocked: _allColors,
  ),
  Achievement(
    id: 'hard_cpu',
    title: 'Giant Slayer',
    description: 'Win a match against the hard CPU',
    icon: Icons.smart_toy_rounded,
    unlocked: _beatHardCpu,
  ),
  Achievement(
    id: 'matches_25',
    title: 'Regular Player',
    description: 'Play 25 matches',
    icon: Icons.sports_esports_rounded,
    unlocked: _twentyFiveMatches,
  ),
  Achievement(
    id: 'captures_100',
    title: 'Pawn Hunter',
    description: 'Capture 100 enemy pawns in total',
    icon: Icons.track_changes_rounded,
    unlocked: _hundredCaptures,
  ),
  Achievement(
    id: 'sixes_50',
    title: 'Lucky Roller',
    description: 'Roll 50 sixes in total',
    icon: Icons.casino_rounded,
    unlocked: _fiftySixes,
  ),
  Achievement(
    id: 'captures_taken_10',
    title: 'Taking Hits',
    description: 'Get captured 10 times in total',
    icon: Icons.shield_rounded,
    unlocked: _tenCapturesTaken,
  ),
  Achievement(
    id: 'matches_100',
    title: 'Veteran',
    description: 'Play 100 matches',
    icon: Icons.military_tech_rounded,
    unlocked: _hundredMatches,
  ),
];

///How many achievements in [kAchievements] the [stats] currently satisfy
int unlockedAchievementCount(StatsProvider stats) {
  int count = 0;
  for (final achievement in kAchievements) {
    if (achievement.unlocked(stats)) {
      count++;
    }
  }
  return count;
}

///Unlocked by winning at least one match
bool _firstWin(StatsProvider stats) => stats.matchesWon >= 1;

///Unlocked by a five match win streak
bool _streakOfFive(StatsProvider stats) => stats.bestWinStreak >= 5;

///Unlocked by ten lifetime wins
bool _tenWins(StatsProvider stats) => stats.matchesWon >= 10;

///Unlocked by winning once with green, yellow, blue and red
bool _allColors(StatsProvider stats) {
  for (final type in LudoPlayerType.values) {
    if ((stats.winsByColor[type] ?? 0) < 1) {
      return false;
    }
  }
  return true;
}

///Unlocked by beating a match configured for the hard CPU
bool _beatHardCpu(StatsProvider stats) =>
    (stats.winsByDifficulty[CpuDifficulty.hard] ?? 0) >= 1;

///Unlocked by playing twenty-five matches
bool _twentyFiveMatches(StatsProvider stats) => stats.matchesPlayed >= 25;

///Unlocked by one hundred captures made by human seats
bool _hundredCaptures(StatsProvider stats) => stats.totalCapturesMade >= 100;

///Unlocked by fifty sixes rolled by human seats
bool _fiftySixes(StatsProvider stats) => stats.totalSixesRolled >= 50;

///Unlocked after suffering ten captures; a long-term goal
bool _tenCapturesTaken(StatsProvider stats) => stats.totalCapturesTaken >= 10;

///Unlocked by playing one hundred matches
bool _hundredMatches(StatsProvider stats) => stats.matchesPlayed >= 100;
