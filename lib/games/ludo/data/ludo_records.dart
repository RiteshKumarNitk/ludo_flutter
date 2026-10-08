import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ludo_models.dart';
import '../models/ludo_state.dart';

///Lifetime Ludo statistics on this device.
///
///Wins, losses, streaks and per-player totals are counted for matches
///against the computer, where "you" are the human seats. Pass & play
///matches only add to the played counters.
class LudoRecords extends ChangeNotifier {
  static const String _key = 'stats_v1';

  int matchesPlayed = 0;
  int matchesWon = 0;
  int matchesLost = 0;
  int passAndPlayGames = 0;
  int capturesMade = 0;
  int pawnsLost = 0;
  int sixesRolled = 0;
  int currentWinStreak = 0;
  int bestWinStreak = 0;
  int flawlessWins = 0;
  int fourPlayerWins = 0;
  final Map<BotDifficulty, int> winsByDifficulty = {for (final d in BotDifficulty.values) d: 0};

  ///Id of the last match recorded. Persisted together with the stats and
  ///compared against a unique per-match id, so a match is counted exactly
  ///once even across app restarts.
  String? _lastRecordedMatchId;

  bool get isEmpty => matchesPlayed == 0;

  int get vsComputerGames => matchesWon + matchesLost;

  double get winRate => vsComputerGames == 0 ? 0 : matchesWon / vsComputerGames;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) _apply(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      //Unreadable stats start from zero
    }
    notifyListeners();
  }

  ///Record a finished match once. Returns true when it was counted.
  bool recordMatch({required String matchId, required LudoMatchConfig config, required LudoState state}) {
    if (!state.isFinished || matchId == _lastRecordedMatchId) return false;
    _lastRecordedMatchId = matchId;
    matchesPlayed++;

    if (!config.hasBots) {
      passAndPlayGames++;
    } else {
      final humans = [for (final s in state.seats) if (!s.isBot) s.color];
      final winner = state.winner;
      final humanWon = winner != null && humans.contains(winner);
      if (humanWon) {
        matchesWon++;
        currentWinStreak++;
        if (currentWinStreak > bestWinStreak) bestWinStreak = currentWinStreak;
        winsByDifficulty[config.difficulty] = (winsByDifficulty[config.difficulty] ?? 0) + 1;
        if (state.stats[winner]!.captured == 0) flawlessWins++;
        if (state.seats.length == 4) fourPlayerWins++;
      } else {
        matchesLost++;
        currentWinStreak = 0;
      }
      for (final color in humans) {
        final stats = state.stats[color]!;
        capturesMade += stats.captures;
        pawnsLost += stats.captured;
        sixesRolled += stats.sixes;
      }
    }
    notifyListeners();
    _save();
    return true;
  }

  Future<void> reset() async {
    matchesPlayed = matchesWon = matchesLost = passAndPlayGames = 0;
    capturesMade = pawnsLost = sixesRolled = 0;
    currentWinStreak = bestWinStreak = flawlessWins = fourPlayerWins = 0;
    for (final d in BotDifficulty.values) {
      winsByDifficulty[d] = 0;
    }
    notifyListeners();
    //Keep the last match id so a just-finished match is not counted again
    await _save();
  }

  Map<String, dynamic> _toJson() => {
        'matchesPlayed': matchesPlayed,
        'matchesWon': matchesWon,
        'matchesLost': matchesLost,
        'passAndPlayGames': passAndPlayGames,
        'totalCapturesMade': capturesMade,
        'totalCapturesTaken': pawnsLost,
        'totalSixesRolled': sixesRolled,
        'currentWinStreak': currentWinStreak,
        'bestWinStreak': bestWinStreak,
        'flawlessWins': flawlessWins,
        'fourPlayerWins': fourPlayerWins,
        'winsByDifficulty': {for (final e in winsByDifficulty.entries) e.key.name: e.value},
        'lastRecordedMatchKey': _lastRecordedMatchId,
      };

  void _apply(Map<String, dynamic> json) {
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;
    matchesPlayed = read('matchesPlayed');
    matchesWon = read('matchesWon');
    matchesLost = read('matchesLost');
    passAndPlayGames = read('passAndPlayGames');
    capturesMade = read('totalCapturesMade');
    pawnsLost = read('totalCapturesTaken');
    sixesRolled = read('totalSixesRolled');
    currentWinStreak = read('currentWinStreak');
    bestWinStreak = read('bestWinStreak');
    flawlessWins = read('flawlessWins');
    fourPlayerWins = read('fourPlayerWins');
    _lastRecordedMatchId = json['lastRecordedMatchKey'] as String?;
    final byDifficulty = json['winsByDifficulty'];
    if (byDifficulty is Map) {
      for (final d in BotDifficulty.values) {
        winsByDifficulty[d] = (byDifficulty[d.name] as num?)?.toInt() ?? 0;
      }
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_toJson()));
    } catch (_) {}
  }
}
