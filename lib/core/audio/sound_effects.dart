import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

///Every sound the app can play
enum Sfx {
  tap('assets/sounds/tap.wav'),
  diceRoll('assets/sounds/dice.wav'),
  step('assets/sounds/step.wav'),
  capture('assets/sounds/capture.wav'),
  home('assets/sounds/home.wav'),
  win('assets/sounds/win.wav');

  final String asset;
  const Sfx(this.asset);
}

///Fire-and-forget sound effects. Each effect owns one player so overlapping
///sounds never cut each other off. Playback never drives game timing.
class SoundEffects {
  const SoundEffects._();

  ///Synced from the settings
  static bool enabled = true;

  static final Map<Sfx, AudioPlayer> _players = {};
  static final Set<Sfx> _loaded = {};

  static Future<void> play(Sfx sfx) async {
    if (!enabled) return;
    try {
      final player = _players.putIfAbsent(sfx, AudioPlayer.new);
      if (!_loaded.contains(sfx)) {
        await player.setAsset(sfx.asset);
        _loaded.add(sfx);
      }
      await player.seek(Duration.zero);
      player.play(); //ignore: discarded_futures
    } catch (_) {
      //Missing audio support or a broken file must never break gameplay
    }
  }

  static Future<void> stop(Sfx sfx) async {
    try {
      await _players[sfx]?.stop();
    } catch (_) {}
  }
}

///Haptic feedback, used sparingly: roll, landing, capture and win
class Haptics {
  const Haptics._();

  ///Synced from the settings
  static bool enabled = true;

  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void selection() {
    if (enabled) HapticFeedback.selectionClick();
  }

  static void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (enabled) HapticFeedback.heavyImpact();
  }
}
