import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio.dart';
import 'board_theme.dart';
import 'game_config.dart';

///User settings, persisted with `shared_preferences`
class SettingsProvider extends ChangeNotifier {
  static const String _keySound = 'settings_sound';
  static const String _keyHaptics = 'settings_haptics';
  static const String _keySpeed = 'settings_animation_speed';
  static const String _keyExtraRollOnSix = 'settings_extra_roll_on_six';
  static const String _keyCpuDifficulty = 'settings_cpu_difficulty';
  static const String _keyBoardTheme = 'settings_board_theme';

  bool _sound = true;
  bool _haptics = true;
  double _animationSpeed = 1.0;
  bool _extraRollOnSix = true;
  CpuDifficulty _cpuDifficulty = CpuDifficulty.medium;
  BoardThemeType _boardTheme = BoardThemeType.classic;
  bool _loaded = false;

  bool get sound => _sound;
  bool get haptics => _haptics;
  double get animationSpeed => _animationSpeed;
  bool get extraRollOnSix => _extraRollOnSix;
  CpuDifficulty get cpuDifficulty => _cpuDifficulty;
  BoardThemeType get boardTheme => _boardTheme;
  bool get loaded => _loaded;

  SettingsProvider() {
    _apply();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _sound = prefs.getBool(_keySound) ?? true;
    _haptics = prefs.getBool(_keyHaptics) ?? true;
    _animationSpeed = prefs.getDouble(_keySpeed) ?? 1.0;
    _extraRollOnSix = prefs.getBool(_keyExtraRollOnSix) ?? true;
    final difficulty = prefs.getString(_keyCpuDifficulty);
    _cpuDifficulty = CpuDifficulty.medium;
    for (final d in CpuDifficulty.values) {
      if (d.name == difficulty) _cpuDifficulty = d;
    }
    final theme = prefs.getString(_keyBoardTheme);
    _boardTheme = BoardThemeType.classic;
    for (final t in BoardThemeType.values) {
      if (t.name == theme) {
        _boardTheme = t;
      }
    }
    _loaded = true;
    _apply();
    notifyListeners();
  }

  void setSound(bool value) {
    if (_sound == value) return;
    _sound = value;
    _apply();
    _save();
    notifyListeners();
  }

  void setHaptics(bool value) {
    if (_haptics == value) return;
    _haptics = value;
    _apply();
    _save();
    notifyListeners();
  }

  void setAnimationSpeed(double value) {
    if (_animationSpeed == value) return;
    _animationSpeed = value;
    _apply();
    _save();
    notifyListeners();
  }

  void setExtraRollOnSix(bool value) {
    if (_extraRollOnSix == value) return;
    _extraRollOnSix = value;
    _save();
    notifyListeners();
  }

  void setCpuDifficulty(CpuDifficulty value) {
    if (_cpuDifficulty == value) return;
    _cpuDifficulty = value;
    _save();
    notifyListeners();
  }

  void setBoardTheme(BoardThemeType value) {
    if (_boardTheme == value) return;
    _boardTheme = value;
    _save();
    notifyListeners();
  }

  Future<void> reset() async {
    _sound = true;
    _haptics = true;
    _animationSpeed = 1.0;
    _extraRollOnSix = true;
    _cpuDifficulty = CpuDifficulty.medium;
    _boardTheme = BoardThemeType.classic;
    _apply();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySound);
    await prefs.remove(_keyHaptics);
    await prefs.remove(_keySpeed);
    await prefs.remove(_keyExtraRollOnSix);
    await prefs.remove(_keyCpuDifficulty);
    await prefs.remove(_keyBoardTheme);
    notifyListeners();
  }

  void _apply() {
    Audio.enabled = _sound;
    Audio.hapticsEnabled = _haptics;
    Audio.speed = _animationSpeed;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySound, _sound);
    await prefs.setBool(_keyHaptics, _haptics);
    await prefs.setDouble(_keySpeed, _animationSpeed);
    await prefs.setBool(_keyExtraRollOnSix, _extraRollOnSix);
    await prefs.setString(_keyCpuDifficulty, _cpuDifficulty.name);
    await prefs.setString(_keyBoardTheme, _boardTheme.name);
  }
}
