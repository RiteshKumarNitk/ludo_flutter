import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ludo_models.dart';
import '../models/ludo_state.dart';

///A suspended match
class LudoSavedMatch {
  final String matchId;
  final LudoMatchConfig config;
  final LudoState state;
  final Duration elapsed;

  const LudoSavedMatch({required this.matchId, required this.config, required this.state, required this.elapsed});

  Map<String, dynamic> toJson() => {
        'version': 2,
        'matchId': matchId,
        'config': config.toJson(),
        'state': state.toJson(),
        'elapsedMs': elapsed.inMilliseconds,
      };

  factory LudoSavedMatch.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 2) throw const FormatException('Unsupported save version');
    return LudoSavedMatch(
      matchId: json['matchId'] as String,
      config: LudoMatchConfig.fromJson(Map<String, dynamic>.from(json['config'] as Map)),
      state: LudoState.fromJson(Map<String, dynamic>.from(json['state'] as Map)),
      elapsed: Duration(milliseconds: (json['elapsedMs'] as num?)?.toInt() ?? 0),
    );
  }
}

///Persists the one suspended Ludo match. Only complete, committed engine
///states are ever written, so a save can never capture a half-done move.
class LudoSaveStore {
  static const String key = 'ludo_match_v2';

  ///Saves from before the engine rewrite cannot be restored
  static const String _legacyKey = 'saved_match';

  Future<void> _queue = Future.value();

  ///Writes are chained so they land in the order they were requested
  Future<void> save(LudoSavedMatch match) => _enqueue((prefs) => prefs.setString(key, jsonEncode(match.toJson())));

  Future<void> clear() => _enqueue((prefs) => prefs.remove(key));

  Future<LudoSavedMatch?> load() async {
    await _queue;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyKey);
      final raw = prefs.getString(key);
      if (raw == null) return null;
      try {
        final match = LudoSavedMatch.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
        if (match.state.isFinished) {
          await prefs.remove(key);
          return null;
        }
        return match;
      } catch (_) {
        await prefs.remove(key); //corrupt or outdated save
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _enqueue(Future<Object?> Function(SharedPreferences prefs) write) {
    _queue = _queue.then((_) async {
      try {
        await write(await SharedPreferences.getInstance());
      } catch (_) {
        //Persistence is best effort; it never interrupts a match
      }
    });
    return _queue;
  }
}
