import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

///Sound effects and haptic feedback for the whole app.
///
///Each sound type gets its own [AudioPlayer] so overlapping effects
///(a capture during a dice roll, for example) never cut each other off.
class Audio {
  ///Player for pawn movement ticks (also paces the step animation)
  static final AudioPlayer _movePlayer = AudioPlayer();

  ///Player for captures
  static final AudioPlayer _killPlayer = AudioPlayer();

  ///Player for dice rolls
  static final AudioPlayer _rollPlayer = AudioPlayer();

  ///Asset currently loaded per player, so each file is only set once
  static final Map<AudioPlayer, String> _loadedAssets = {};

  static const String _moveAsset = 'assets/sounds/move.wav';
  static const String _killAsset = 'assets/sounds/laugh.mp3';
  static const String _rollAsset = 'assets/sounds/roll_the_dice.mp3';

  ///Sound effects on/off, synced by `SettingsProvider`
  static bool enabled = true;

  ///Haptic feedback on/off, synced by `SettingsProvider`
  static bool hapticsEnabled = true;

  ///Animation speed multiplier, synced by `SettingsProvider`
  static double speed = 1.0;

  ///Scale a duration by the configured animation speed
  static Duration _scaled(Duration duration) {
    final double safeSpeed = speed <= 0 ? 1 : speed;
    final int ms = (duration.inMilliseconds / safeSpeed).round();
    return Duration(milliseconds: ms < 60 ? 60 : ms);
  }

  ///Medium impact: a pawn was captured
  static void haptic() {
    if (hapticsEnabled) HapticFeedback.mediumImpact();
  }

  ///Light tap: dice roll, pawn pick, button presses
  static void hapticLight() {
    if (hapticsEnabled) HapticFeedback.lightImpact();
  }

  ///Strong buzz: match won
  static void hapticHeavy() {
    if (hapticsEnabled) HapticFeedback.heavyImpact();
  }

  ///Load the asset once, then restart playback from the beginning
  static Future<void> _start(AudioPlayer player, String asset) async {
    try {
      if (_loadedAssets[player] != asset) {
        await player.setAsset(asset);
        _loadedAssets[player] = asset;
      }
      await player.seek(Duration.zero);
      player.play(); //ignore: discarded_futures
    } catch (_) {
      ///A missing or unreadable file must never break gameplay
    }
  }

  ///Play one movement tick; the returned future paces the step animation
  static Future<void> playMove() async {
    if (!enabled) {
      return Future.delayed(_scaled(const Duration(milliseconds: 220)));
    }
    await _start(_movePlayer, _moveAsset);
    return Future.delayed(
        _scaled(_movePlayer.duration ?? const Duration(milliseconds: 220)));
  }

  ///Play the capture sting
  static Future<void> playKill() async {
    if (!enabled) {
      return Future.delayed(_scaled(const Duration(milliseconds: 300)));
    }
    await _start(_killPlayer, _killAsset);
    return Future.delayed(
        _scaled(_killPlayer.duration ?? const Duration(milliseconds: 300)));
  }

  ///Play the dice roll sound with a light haptic tick
  static Future<void> rollDice() async {
    hapticLight();
    if (!enabled) return Future.delayed(Duration.zero);
    await _start(_rollPlayer, _rollAsset);
    return Future.delayed(
        _scaled(_rollPlayer.duration ?? const Duration(milliseconds: 400)));
  }
}
