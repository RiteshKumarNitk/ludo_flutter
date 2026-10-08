import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'game_config.dart';
import 'ludo_player.dart';
import 'ludo_provider.dart';

///Lifetime player statistics for this device, persisted as a single JSON
///blob under the `stats_v1` SharedPreferences key.
///
///Stored shape:
///```json
///{
///  "matchesPlayed": 0, "matchesWon": 0, "matchesLost": 0,
///  "totalCapturesMade": 0, "totalCapturesTaken": 0, "totalSixesRolled": 0,
///  "winsByColor": {"green": 0, "yellow": 0, "blue": 0, "red": 0},
///  "winsByDifficulty": {"easy": 0, "medium": 0, "hard": 0},
///  "currentWinStreak": 0, "bestWinStreak": 0,
///  "lastRecordedMatchId": -1
///}
///```
///
///A match is a "win" when its winner is a human seat, a "loss" when any
///other seat (a CPU) takes it. Capture and six totals only sum the human
///seats, so `totalCapturesMade` and `totalCapturesTaken` read as captures
///for and against the human side of the table.
class StatsProvider extends ChangeNotifier {
  ///SharedPreferences key for the whole stats blob
  static const String _key = 'stats_v1';

  int _matchesPlayed = 0;
  int _matchesWon = 0;
  int _matchesLost = 0;
  int _totalCapturesMade = 0;
  int _totalCapturesTaken = 0;
  int _totalSixesRolled = 0;
  int _currentWinStreak = 0;
  int _bestWinStreak = 0;
  int _lastRecordedMatchId = -1;
  final Map<LudoPlayerType, int> _winsByColor = {
    for (final type in LudoPlayerType.values) type: 0,
  };
  final Map<CpuDifficulty, int> _winsByDifficulty = {
    for (final difficulty in CpuDifficulty.values) difficulty: 0,
  };
  bool _loaded = false;

  ///Finished matches recorded so far
  int get matchesPlayed => _matchesPlayed;

  ///Finished matches won by a human seat
  int get matchesWon => _matchesWon;

  ///Finished matches won by nobody on the human side
  int get matchesLost => _matchesLost;

  ///Captures made by human seats across all recorded matches
  int get totalCapturesMade => _totalCapturesMade;

  ///Captures of human pawns across all recorded matches
  int get totalCapturesTaken => _totalCapturesTaken;

  ///Sixes rolled by human seats across all recorded matches
  int get totalSixesRolled => _totalSixesRolled;

  ///Wins in the current unbroken run; a loss resets it to zero
  int get currentWinStreak => _currentWinStreak;

  ///Longest win run ever recorded
  int get bestWinStreak => _bestWinStreak;

  ///Wins counted per color
  Map<LudoPlayerType, int> get winsByColor => _winsByColor;

  ///Wins counted per CPU difficulty the match was played on
  Map<CpuDifficulty, int> get winsByDifficulty => _winsByDifficulty;

  ///Win rate between 0.0 and 1.0, zero while nothing was recorded
  double get winRate =>
      _matchesPlayed == 0 ? 0.0 : _matchesWon / _matchesPlayed;

  ///`LudoProvider.matchId` of the last recorded match; used to make
  ///[recordMatch] idempotent across provider reloads
  int get lastRecordedMatchId => _lastRecordedMatchId;

  ///True once [load] has finished reading the persisted blob
  bool get loaded => _loaded;

  ///Read stats from SharedPreferences. A missing or corrupt key falls back
  ///to defaults instead of throwing.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          _applyJson(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (_) {
      ///Corrupt or unreadable stats are dropped in favour of defaults
    }
    _loaded = true;
    notifyListeners();
  }

  ///Record a finished match exactly once. Calling this repeatedly for the
  ///same match (or while it is still running) changes nothing, because the
  ///persisted [lastRecordedMatchId] guard matches [LudoProvider.matchId].
  ///Also updates the win streaks and the per-color / per-difficulty wins.
  void recordMatch(LudoProvider game) {
    if (!game.isFinished) {
      return;
    }
    if (game.matchId == _lastRecordedMatchId) {
      return;
    }
    _lastRecordedMatchId = game.matchId;
    _matchesPlayed++;

    final winner = game.winners.isNotEmpty ? game.winners.first : null;
    final winnerSeat = winner == null ? null : _seatOf(game, winner);
    if (winner != null && winnerSeat != null && !winnerSeat.isCpu) {
      _matchesWon++;
      _currentWinStreak++;
      if (_currentWinStreak > _bestWinStreak) {
        _bestWinStreak = _currentWinStreak;
      }
      _winsByColor[winner] = (_winsByColor[winner] ?? 0) + 1;
      final difficulty = game.config.cpuDifficulty;
      _winsByDifficulty[difficulty] = (_winsByDifficulty[difficulty] ?? 0) + 1;
    } else {
      _matchesLost++;
      _currentWinStreak = 0;
    }

    for (final seat in game.players) {
      if (seat.isCpu) {
        continue;
      }
      _totalCapturesMade += game.capturesMade[seat.type] ?? 0;
      _totalCapturesTaken += game.capturesTaken[seat.type] ?? 0;
      _totalSixesRolled += game.sixesRolled[seat.type] ?? 0;
    }

    notifyListeners();
    _save();
  }

  ///Wipe every statistic and remove the persisted blob
  Future<void> reset() async {
    _matchesPlayed = 0;
    _matchesWon = 0;
    _matchesLost = 0;
    _totalCapturesMade = 0;
    _totalCapturesTaken = 0;
    _totalSixesRolled = 0;
    _currentWinStreak = 0;
    _bestWinStreak = 0;
    _lastRecordedMatchId = -1;
    for (final type in LudoPlayerType.values) {
      _winsByColor[type] = 0;
    }
    for (final difficulty in CpuDifficulty.values) {
      _winsByDifficulty[difficulty] = 0;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    notifyListeners();
  }

  ///Write the whole stats blob; persistence is best-effort
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_toJson()));
    } catch (_) {
      ///A failed write never breaks the screen showing the stats
    }
  }

  ///Serialize every field into the documented blob shape
  Map<String, dynamic> _toJson() => {
        'matchesPlayed': _matchesPlayed,
        'matchesWon': _matchesWon,
        'matchesLost': _matchesLost,
        'totalCapturesMade': _totalCapturesMade,
        'totalCapturesTaken': _totalCapturesTaken,
        'totalSixesRolled': _totalSixesRolled,
        'winsByColor': {
          for (final entry in _winsByColor.entries) entry.key.name: entry.value,
        },
        'winsByDifficulty': {
          for (final entry in _winsByDifficulty.entries)
            entry.key.name: entry.value,
        },
        'currentWinStreak': _currentWinStreak,
        'bestWinStreak': _bestWinStreak,
        'lastRecordedMatchId': _lastRecordedMatchId,
      };

  ///Copy whatever is usable out of a decoded blob, field by field
  void _applyJson(Map<String, dynamic> json) {
    _matchesPlayed = _readInt(json, 'matchesPlayed', 0);
    _matchesWon = _readInt(json, 'matchesWon', 0);
    _matchesLost = _readInt(json, 'matchesLost', 0);
    _totalCapturesMade = _readInt(json, 'totalCapturesMade', 0);
    _totalCapturesTaken = _readInt(json, 'totalCapturesTaken', 0);
    _totalSixesRolled = _readInt(json, 'totalSixesRolled', 0);
    _currentWinStreak = _readInt(json, 'currentWinStreak', 0);
    _bestWinStreak = _readInt(json, 'bestWinStreak', 0);
    _lastRecordedMatchId = _readInt(json, 'lastRecordedMatchId', -1);
    _readColorWins(json['winsByColor']);
    _readDifficultyWins(json['winsByDifficulty']);
  }

  ///Read one integer field, falling back when it is missing or mistyped
  static int _readInt(Map<String, dynamic> json, String key, int fallback) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }

  ///Refill every color with the stored count (or zero)
  void _readColorWins(dynamic raw) {
    if (raw is! Map) {
      return;
    }
    for (final type in LudoPlayerType.values) {
      final value = raw[type.name];
      _winsByColor[type] = value is num ? value.toInt() : 0;
    }
  }

  ///Refill every difficulty with the stored count (or zero)
  void _readDifficultyWins(dynamic raw) {
    if (raw is! Map) {
      return;
    }
    for (final difficulty in CpuDifficulty.values) {
      final value = raw[difficulty.name];
      _winsByDifficulty[difficulty] = value is num ? value.toInt() : 0;
    }
  }

  ///Find the seat that plays [type], or null when it is not seated
  static LudoPlayer? _seatOf(LudoProvider game, LudoPlayerType type) {
    for (final seat in game.players) {
      if (seat.type == type) {
        return seat;
      }
    }
    return null;
  }
}
