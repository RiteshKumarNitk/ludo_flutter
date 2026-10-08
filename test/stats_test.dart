import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_flutter/achievements.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/game_config.dart';
import 'package:ludo_flutter/ludo_provider.dart';
import 'package:ludo_flutter/stats_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

///Play out a finished two-player match won by [winner]
LudoProvider finishedMatch({
  required LudoPlayerType winner,
  CpuDifficulty difficulty = CpuDifficulty.medium,
  bool winnerIsCpu = false,
}) {
  final p = LudoProvider();
  p.startGame(GameConfig(
    players: [
      PlayerSetup(
        color: LudoPlayerType.green,
        name: 'A',
        isCpu: winnerIsCpu && winner == LudoPlayerType.green,
      ),
      PlayerSetup(
        color: LudoPlayerType.blue,
        name: 'B',
        isCpu: winnerIsCpu && winner == LudoPlayerType.blue,
      ),
    ],
    cpuDifficulty: difficulty,
  ));
  final seat = p.player(winner);
  for (int i = 0; i < 4; i++) {
    seat.movePawn(i, seat.path.length - 1);
  }
  p.validateWin(winner);
  expect(p.isFinished, isTrue, reason: 'the rigged match must end');
  return p;
}

///A stats blob that satisfies every achievement predicate
Map<String, Object> veteranStats() => {
      'matchesPlayed': 100,
      'matchesWon': 10,
      'matchesLost': 4,
      'totalCapturesMade': 120,
      'totalCapturesTaken': 15,
      'totalSixesRolled': 60,
      'winsByColor': {'green': 3, 'yellow': 2, 'blue': 3, 'red': 2},
      'winsByDifficulty': {'easy': 4, 'medium': 4, 'hard': 2},
      'currentWinStreak': 5,
      'bestWinStreak': 5,
      'lastRecordedMatchId': -1,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fresh stats are empty and nothing is unlocked yet', () async {
    final stats = StatsProvider();
    await stats.load();
    expect(stats.matchesPlayed, 0);
    expect(stats.matchesWon, 0);
    expect(stats.currentWinStreak, 0);
    expect(stats.winsByColor[LudoPlayerType.green], 0);
    expect(unlockedAchievementCount(stats), 0);
  });

  test('a human win is recorded exactly once and survives a reload', () async {
    final stats = StatsProvider();
    await stats.load();
    final game = finishedMatch(winner: LudoPlayerType.green);
    addTearDown(game.dispose);

    stats.recordMatch(game);
    expect(stats.matchesPlayed, 1);
    expect(stats.matchesWon, 1);
    expect(stats.matchesLost, 0);
    expect(stats.currentWinStreak, 1);
    expect(stats.bestWinStreak, 1);
    expect(stats.winsByColor[LudoPlayerType.green], 1);
    expect(stats.winsByDifficulty[CpuDifficulty.medium], 1);

    ///Recording the same finished match again is a no-op
    stats.recordMatch(game);
    expect(stats.matchesPlayed, 1);
    expect(stats.matchesWon, 1);

    ///The blob round-trips through a brand new provider
    final reloaded = StatsProvider();
    await reloaded.load();
    expect(reloaded.matchesPlayed, 1);
    expect(reloaded.matchesWon, 1);
    expect(reloaded.winsByColor[LudoPlayerType.green], 1);
    expect(reloaded.lastRecordedMatchId, game.matchId);
  });

  test('a CPU win counts as a loss and breaks the streak', () async {
    final stats = StatsProvider();
    await stats.load();

    final win1 = finishedMatch(winner: LudoPlayerType.green);
    final win2 = finishedMatch(winner: LudoPlayerType.blue);
    addTearDown(win1.dispose);
    addTearDown(win2.dispose);
    stats.recordMatch(win1);
    stats.recordMatch(win2);
    expect(stats.matchesWon, 2);
    expect(stats.currentWinStreak, 2);

    final loss = finishedMatch(
      winner: LudoPlayerType.blue,
      winnerIsCpu: true,
      difficulty: CpuDifficulty.hard,
    );
    addTearDown(loss.dispose);
    stats.recordMatch(loss);
    expect(stats.matchesPlayed, 3);
    expect(stats.matchesLost, 1);
    expect(stats.currentWinStreak, 0, reason: 'the streak breaks on a loss');
    expect(stats.bestWinStreak, 2, reason: 'the best streak is history');
    expect(stats.matchesWon, 2, reason: 'a CPU win never counts as ours');
  });

  test('match ids never collide so the stats guard never skips a match', () async {
    ///Two providers built in the same instant must still get distinct ids,
    ///because lastRecordedMatchId outlives a single provider instance
    final a = LudoProvider();
    addTearDown(a.dispose);
    a.startGame(GameConfig.defaults(2), false);
    final b = LudoProvider();
    addTearDown(b.dispose);
    b.startGame(GameConfig.defaults(2), false);
    expect(a.matchId, isNot(b.matchId));

    ///A rematch in the same session keeps counting up
    final previous = b.matchId;
    b.startGame(GameConfig.defaults(2), false);
    expect(b.matchId, isNot(previous));
  });

  test('a resumed match keeps its original id', () async {
    final p = LudoProvider();
    p.startGame(GameConfig.defaults(2));
    p.player(LudoPlayerType.green).movePawn(0, 5);
    final originalId = p.matchId;
    final saved = jsonEncode(p.toSaveJson());
    p.dispose(); //cancel pending timers before swapping the store
    await Future.delayed(const Duration(milliseconds: 600));

    SharedPreferences.setMockInitialValues({LudoProvider.saveKey: saved});
    final resumed = LudoProvider();
    addTearDown(resumed.dispose);
    expect(await resumed.resumeSavedGame(), isTrue);
    expect(resumed.matchId, originalId, reason: 'resume must not change the id');
  });

  test('a corrupt stats blob falls back to defaults', () async {
    SharedPreferences.setMockInitialValues({'stats_v1': '{not json'});
    final stats = StatsProvider();
    await stats.load();
    expect(stats.matchesPlayed, 0);
    expect(unlockedAchievementCount(stats), 0);
  });

  test('a veteran profile unlocks every achievement', () async {
    SharedPreferences.setMockInitialValues({'stats_v1': jsonEncode(veteranStats())});
    final stats = StatsProvider();
    await stats.load();
    expect(unlockedAchievementCount(stats), kAchievements.length);
    for (final achievement in kAchievements) {
      expect(achievement.unlocked(stats), isTrue, reason: achievement.id);
    }
  });

  test('a single win unlocks exactly the first achievement', () async {
    SharedPreferences.setMockInitialValues({'stats_v1': jsonEncode({'matchesWon': 1})});
    final stats = StatsProvider();
    await stats.load();
    final unlockedIds = [
      for (final achievement in kAchievements)
        if (achievement.unlocked(stats)) achievement.id,
    ];
    expect(unlockedIds, ['first_win']);
  });
}
