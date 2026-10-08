import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio.dart';

///User settings, persisted with `shared_preferences`
class SettingsProvider extends ChangeNotifier {
  static const String _keySound = 'settings_sound';
  static const String _keyHaptics = 'settings_haptics';
  static const String _keySpeed = 'settings_animation_speed';
  static const String _keyExtraRollOnSix = 'settings_extra_roll_on_six';

  bool _sound = true;
  bool _haptics = true;
  double _animationSpeed = 1.0;
  bool _extraRollOnSix = true;
  bool _loaded = false;

  bool get sound => _sound;
  bool get haptics => _haptics;
  double get animationSpeed => _animationSpeed;
  bool get extraRollOnSix => _extraRollOnSix;
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

  Future<void> reset() async {
    _sound = true;
    _haptics = true;
    _animationSpeed = 1.0;
    _extraRollOnSix = true;
    _apply();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySound);
    await prefs.remove(_keyHaptics);
    await prefs.remove(_keySpeed);
    await prefs.remove(_keyExtraRollOnSix);
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
  }
}
