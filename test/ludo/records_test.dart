import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_flutter/games/ludo/data/ludo_achievements.dart';
import 'package:ludo_flutter/games/ludo/data/ludo_records.dart';
import 'package:ludo_flutter/games/ludo/models/ludo_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_support.dart';

int unlocked(LudoRecords r) => ludoAchievements.where((a) => a.unlocked(r)).length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('fresh records are empty and nothing is unlocked', () async {
    final records = LudoRecords();
    await records.load();
    expect(records.isEmpty, isTrue);
    expect(unlocked(records), 0);
  });

  test('a win is recorded exactly once and survives a reload', () async {
    final records = LudoRecords();
    await records.load();
    final config = duel();
    final state = finishedState(config, LudoColor.red);

    expect(records.recordMatch(matchId: 'm1', config: config, state: state), isTrue);
    expect(records.recordMatch(matchId: 'm1', config: config, state: state), isFalse, reason: 'same match again');
    expect(records.matchesPlayed, 1);
    expect(records.matchesWon, 1);
    expect(records.currentWinStreak, 1);
    expect(records.winsByDifficulty[BotDifficulty.medium], 1);
    expect(records.flawlessWins, 1);
    await settle();

    //A new instance (an app restart) reads the same blob and the same
    //last-recorded id, so the finished match is still not counted twice
    final reloaded = LudoRecords();
    await reloaded.load();
    expect(reloaded.matchesWon, 1);
    expect(reloaded.recordMatch(matchId: 'm1', config: config, state: state), isFalse);
    expect(reloaded.recordMatch(matchId: 'm2', config: config, state: state), isTrue,
        reason: 'a new match after a restart is counted');
  });

  test('a bot win is a loss and breaks the streak', () async {
    final records = LudoRecords();
    final config = duel(difficulty: BotDifficulty.hard);
    records.recordMatch(matchId: 'a', config: config, state: finishedState(config, LudoColor.red));
    records.recordMatch(matchId: 'b', config: config, state: finishedState(config, LudoColor.red, winnerCaptured: 2));
    expect(records.currentWinStreak, 2);
    expect(records.flawlessWins, 1);

    records.recordMatch(matchId: 'c', config: config, state: finishedState(config, LudoColor.yellow));
    expect(records.matchesLost, 1);
    expect(records.currentWinStreak, 0);
    expect(records.bestWinStreak, 2);
    expect(records.matchesWon, 2);
  });

  test('pass & play matches count as played only', () async {
    final records = LudoRecords();
    final config = duel(yellowIsBot: false);
    records.recordMatch(matchId: 'p', config: config, state: finishedState(config, LudoColor.red));
    expect(records.matchesPlayed, 1);
    expect(records.passAndPlayGames, 1);
    expect(records.matchesWon, 0);
    expect(records.matchesLost, 0);
  });

  test('a corrupt blob falls back to defaults', () async {
    SharedPreferences.setMockInitialValues({'stats_v1': '{not json'});
    final records = LudoRecords();
    await records.load();
    expect(records.isEmpty, isTrue);
  });

  test('older stats blobs keep their totals', () async {
    SharedPreferences.setMockInitialValues({
      'stats_v1': jsonEncode({
        'matchesPlayed': 100,
        'matchesWon': 10,
        'matchesLost': 4,
        'totalCapturesMade': 120,
        'totalCapturesTaken': 15,
        'totalSixesRolled': 60,
        'winsByDifficulty': {'easy': 4, 'medium': 4, 'hard': 2},
        'bestWinStreak': 5,
        'lastRecordedMatchId': 3,
      }),
    });
    final records = LudoRecords();
    await records.load();
    expect(records.matchesPlayed, 100);
    expect(records.capturesMade, 120);
    final ids = [for (final a in ludoAchievements) if (a.unlocked(records)) a.id];
    expect(ids, containsAll(['first_win', 'hard_bot', 'streak_5', 'wins_10', 'sixes_50', 'captures_100', 'matches_25', 'matches_100']));
  });

  test('a single win unlocks exactly the first achievement', () async {
    SharedPreferences.setMockInitialValues({'stats_v1': jsonEncode({'matchesWon': 1})});
    final records = LudoRecords();
    await records.load();
    expect([for (final a in ludoAchievements) if (a.unlocked(records)) a.id], ['first_win']);
  });
}
