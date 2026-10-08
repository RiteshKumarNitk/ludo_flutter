import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class Audio {
  static AudioPlayer audioPlayer = AudioPlayer();

  ///Sound effects on/off, synced by `SettingsProvider`
  static bool enabled = true;

  ///Haptic feedback on/off, synced by `SettingsProvider`
  static bool hapticsEnabled = true;

  ///Animation speed multiplier, synced by `SettingsProvider`
  static double speed = 1.0;

  static Duration _scaled(Duration duration) {
    final double safeSpeed = speed <= 0 ? 1 : speed;
    final int ms = (duration.inMilliseconds / safeSpeed).round();
    return Duration(milliseconds: ms < 60 ? 60 : ms);
  }

  static void haptic() {
    if (hapticsEnabled) HapticFeedback.mediumImpact();
  }

  static Future<void> playMove() async {
    if (!enabled) {
      return Future.delayed(_scaled(const Duration(milliseconds: 220)));
    }
    final duration = await audioPlayer.setAsset('assets/sounds/move.wav');
    audioPlayer.play();
    return Future.delayed(_scaled(duration ?? const Duration(milliseconds: 220)));
  }

  static Future<void> playKill() async {
    if (!enabled) {
      return Future.delayed(_scaled(const Duration(milliseconds: 300)));
    }
    final duration = await audioPlayer.setAsset('assets/sounds/laugh.mp3');
    audioPlayer.play();
    return Future.delayed(_scaled(duration ?? const Duration(milliseconds: 300)));
  }

  static Future<void> rollDice() async {
    haptic();
    if (!enabled) return Future.delayed(Duration.zero);
    final duration = await audioPlayer.setAsset('assets/sounds/roll_the_dice.mp3');
    audioPlayer.play();
    return Future.delayed(_scaled(duration ?? Duration.zero));
  }
}
