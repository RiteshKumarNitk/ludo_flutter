import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ludo_models.dart';
import '../widgets/board_theme.dart';

///Ludo-only preferences: board theme and the last setup choices
class LudoPreferences extends ChangeNotifier {
  static const _keyTheme = 'settings_board_theme';
  static const _keyPlayers = 'ludo_setup_players';
  static const _keyMode = 'ludo_setup_mode';
  static const _keyDifficulty = 'ludo_setup_difficulty';

  BoardThemeType boardTheme = BoardThemeType.classic;
  int playerCount = 4;
  LudoMode mode = LudoMode.vsComputer;
  BotDifficulty difficulty = BotDifficulty.medium;

  BoardTheme get theme => BoardTheme.of(boardTheme);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      boardTheme = _byName(BoardThemeType.values, prefs.getString(_keyTheme)) ?? BoardThemeType.classic;
      playerCount = (prefs.getInt(_keyPlayers) ?? 4).clamp(2, 4);
      mode = _byName(LudoMode.values, prefs.getString(_keyMode)) ?? LudoMode.vsComputer;
      difficulty = _byName(BotDifficulty.values, prefs.getString(_keyDifficulty)) ?? BotDifficulty.medium;
    } catch (_) {}
    notifyListeners();
  }

  void setBoardTheme(BoardThemeType value) {
    if (boardTheme == value) return;
    boardTheme = value;
    notifyListeners();
    _write((p) => p.setString(_keyTheme, value.name));
  }

  ///Remember the setup so the next match starts from the same choices
  void rememberSetup({required int players, required LudoMode mode, required BotDifficulty difficulty}) {
    playerCount = players;
    this.mode = mode;
    this.difficulty = difficulty;
    _write((p) async {
      await p.setInt(_keyPlayers, players);
      await p.setString(_keyMode, mode.name);
      return p.setString(_keyDifficulty, difficulty.name);
    });
  }

  Future<void> resetTheme() async {
    boardTheme = BoardThemeType.classic;
    notifyListeners();
    await _write((p) => p.remove(_keyTheme));
  }

  static T? _byName<T extends Enum>(List<T> values, String? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  Future<void> _write(Future<bool> Function(SharedPreferences prefs) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (_) {}
  }
}
