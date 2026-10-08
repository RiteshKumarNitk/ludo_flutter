import 'package:flutter/material.dart';

import '../models/ludo_models.dart';
import 'ludo_records.dart';

///A milestone computed from [LudoRecords]; nothing extra is persisted
class LudoAchievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int target;
  final int Function(LudoRecords records) progressOf;

  const LudoAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    required this.progressOf,
  });

  int progress(LudoRecords records) => progressOf(records).clamp(0, target);

  bool unlocked(LudoRecords records) => progressOf(records) >= target;
}

const List<LudoAchievement> ludoAchievements = [
  LudoAchievement(
    id: 'first_win',
    title: 'First Victory',
    description: 'Win a match against the computer',
    icon: Icons.star_rounded,
    target: 1,
    progressOf: _wins,
  ),
  LudoAchievement(
    id: 'flawless',
    title: 'Untouchable',
    description: 'Win without losing a single pawn',
    icon: Icons.shield_rounded,
    target: 1,
    progressOf: _flawless,
  ),
  LudoAchievement(
    id: 'hard_bot',
    title: 'Giant Slayer',
    description: 'Beat the Hard computer',
    icon: Icons.smart_toy_rounded,
    target: 1,
    progressOf: _hardWins,
  ),
  LudoAchievement(
    id: 'full_table',
    title: 'Full Table',
    description: 'Win a 4-player match',
    icon: Icons.groups_rounded,
    target: 1,
    progressOf: _fourPlayerWins,
  ),
  LudoAchievement(
    id: 'streak_5',
    title: 'On Fire',
    description: 'Win 5 matches in a row',
    icon: Icons.local_fire_department_rounded,
    target: 5,
    progressOf: _bestStreak,
  ),
  LudoAchievement(
    id: 'wins_10',
    title: 'Double Digits',
    description: 'Win 10 matches',
    icon: Icons.workspace_premium_rounded,
    target: 10,
    progressOf: _wins,
  ),
  LudoAchievement(
    id: 'sixes_50',
    title: 'Lucky Roller',
    description: 'Roll 50 sixes',
    icon: Icons.casino_rounded,
    target: 50,
    progressOf: _sixes,
  ),
  LudoAchievement(
    id: 'captures_100',
    title: 'Pawn Hunter',
    description: 'Capture 100 pawns',
    icon: Icons.gps_fixed_rounded,
    target: 100,
    progressOf: _captures,
  ),
  LudoAchievement(
    id: 'matches_25',
    title: 'Regular',
    description: 'Play 25 matches',
    icon: Icons.sports_esports_rounded,
    target: 25,
    progressOf: _played,
  ),
  LudoAchievement(
    id: 'matches_100',
    title: 'Veteran',
    description: 'Play 100 matches',
    icon: Icons.military_tech_rounded,
    target: 100,
    progressOf: _played,
  ),
];

int _wins(LudoRecords r) => r.matchesWon;
int _flawless(LudoRecords r) => r.flawlessWins;
int _hardWins(LudoRecords r) => r.winsByDifficulty[BotDifficulty.hard] ?? 0;
int _fourPlayerWins(LudoRecords r) => r.fourPlayerWins;
int _bestStreak(LudoRecords r) => r.bestWinStreak;
int _sixes(LudoRecords r) => r.sixesRolled;
int _captures(LudoRecords r) => r.capturesMade;
int _played(LudoRecords r) => r.matchesPlayed;
