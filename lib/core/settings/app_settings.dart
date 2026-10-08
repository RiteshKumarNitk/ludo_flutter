import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/sound_effects.dart';

enum GameSpeed { normal, fast }

///App-wide preferences: sound, vibration and game speed.
///Game specific preferences (like a board theme) live with their game.
class AppSettings extends ChangeNotifier {
  static const _keySound = 'settings_sound';
  static const _keyHaptics = 'settings_haptics';
  static const _keySpeed = 'settings_game_speed';

  ///Keys written by earlier versions that are no longer used
  static const _obsoleteKeys = [
    'settings_animation_speed',
    'settings_extra_roll_on_six',
    'settings_cpu_difficulty',
  ];

  bool _sound = true;
  bool _haptics = true;
  GameSpeed _speed = GameSpeed.normal;

  bool get sound => _sound;
  bool get haptics => _haptics;
  GameSpeed get speed => _speed;

  AppSettings() {
    _apply();
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sound = prefs.getBool(_keySound) ?? true;
      _haptics = prefs.getBool(_keyHaptics) ?? true;
      final speed = prefs.getString(_keySpeed);
      if (speed != null) {
        _speed = GameSpeed.values.firstWhere((s) => s.name == speed, orElse: () => GameSpeed.normal);
      } else if ((prefs.getDouble('settings_animation_speed') ?? 1.0) > 1.2) {
        _speed = GameSpeed.fast; //migrate the old speed slider
      }
      for (final key in _obsoleteKeys) {
        await prefs.remove(key);
      }
    } catch (_) {
      //Defaults are fine when storage is unavailable
    }
    _apply();
    notifyListeners();
  }

  void setSound(bool value) {
    if (_sound == value) return;
    _sound = value;
    _changed();
  }

  void setHaptics(bool value) {
    if (_haptics == value) return;
    _haptics = value;
    _changed();
  }

  void setSpeed(GameSpeed value) {
    if (_speed == value) return;
    _speed = value;
    _changed();
  }

  Future<void> reset() async {
    _sound = true;
    _haptics = true;
    _speed = GameSpeed.normal;
    _apply();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySound);
      await prefs.remove(_keyHaptics);
      await prefs.remove(_keySpeed);
    } catch (_) {}
  }

  void _changed() {
    _apply();
    notifyListeners();
    _save();
  }

  void _apply() {
    SoundEffects.enabled = _sound;
    Haptics.enabled = _haptics;
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySound, _sound);
      await prefs.setBool(_keyHaptics, _haptics);
      await prefs.setString(_keySpeed, _speed.name);
    } catch (_) {}
  }
}
