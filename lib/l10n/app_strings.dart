import 'package:flutter/widgets.dart';

import '../constants.dart';

///User-facing strings of the app.
///
///The app currently ships English only, but every string the UI shows is
///routed through this class so another language can be added later by:
///1. creating e.g. `AppStringsEs` with the same getters,
///2. adding a `LocalizationsDelegate` for it in `main.dart`,
///3. listing the locale in `MaterialApp.supportedLocales`.
///
///Widget tests assert the English text, so they keep working unchanged.
class AppStrings {
  const AppStrings();

  ///The (currently only) strings bundle
  static const AppStrings en = AppStrings();

  ///Delegate that hands the bundle to the element tree
  static const LocalizationsDelegate<AppStrings> delegate = _AppStringsDelegate();

  ///Nearest strings bundle for the given context
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ?? en;

  // -------------------------------------------------------------------------
  // Main menu
  // -------------------------------------------------------------------------

  String get appTitle => 'LUDO';
  String get play => 'Play';
  String get resumeGame => 'Resume Game';
  String get howToPlay => 'How to Play';
  String get settings => 'Settings';
  String get about => 'About';
  String get noSavedGame => 'No saved game found';
  String get aboutTitle => 'About';
  String get statistics => 'Statistics';
  String get achievements => 'Achievements';
  String get aboutDescription =>
      'A classic Ludo board game for 2 to 4 players, playable against friends on one device or the computer.';
  String get aboutCredit => 'This game made with Flutter ❤️ by Mochamad Nizwar Syafuan';
  String get close => 'Close';
  String get madeWithLove => 'This game made with Flutter ❤️';

  // -------------------------------------------------------------------------
  // Setup screen
  // -------------------------------------------------------------------------

  String get newGame => 'New Game';
  String get players => 'Players';
  String get playerName => 'Player name';
  String get goesFirst => 'Goes first';
  String get cpu => 'CPU';
  String get startGame => 'Start Game';
  String get rules => 'Rules';
  String get extraRollOnSix => 'Extra roll on 6';
  String get extraRollOnSixHint => 'Roll the dice again after throwing a 6';
  String get extraRollOnCapture => 'Extra roll on capture';
  String get extraRollOnCaptureHint => 'Capture an opponent to roll again';
  String get threeSixesForfeit => 'Three 6s forfeit';
  String get threeSixesForfeitHint => 'Rolling three 6s in a row loses the turn';
  String get exactFinish => 'Exact finish';
  String get exactFinishHint => 'Need the exact roll to reach the final cell';
  String get blocking => 'Blocking';
  String get blockingHint => 'Two pawns on one cell block opponents';
  String get cpuDifficulty => 'CPU Difficulty';
  String get difficultyEasy => 'Easy';
  String get difficultyMedium => 'Medium';
  String get difficultyHard => 'Hard';
  String get difficultyHint =>
      'Easy plays random moves, Medium chases the finish, Hard sets captures and blocks.';

  // -------------------------------------------------------------------------
  // Pause menu
  // -------------------------------------------------------------------------

  String get paused => 'Paused';
  String get resume => 'Resume';
  String get restart => 'Restart';
  String get quitToMenu => 'Quit to Menu';

  // -------------------------------------------------------------------------
  // Settings screen
  // -------------------------------------------------------------------------

  String get soundEffects => 'Sound effects';
  String get soundEffectsHint => 'Dice, pawn movement and capture sounds';
  String get hapticFeedback => 'Haptic feedback';
  String get hapticFeedbackHint => 'Vibrate when rolling and capturing';
  String get animationSpeed => 'Animation speed';
  String get speedSlow => 'Slow';
  String get speedNormal => 'Normal';
  String get speedFast => 'Fast';
  String get boardTheme => 'Board theme';
  String get defaultRuleHint => 'Default rule for new matches';
  String get resetToDefaults => 'Reset to defaults';

  // -------------------------------------------------------------------------
  // Game screen
  // -------------------------------------------------------------------------

  String get pause => 'Pause';
  String get undoLastMove => 'Undo last move';
  String get cpuSeat => '(CPU)';
  String get youSeat => '(You)';
  String get hintGameOver => 'Game over';
  String get hintPaused => 'Paused';
  String get hintTapDice => 'Tap the dice to roll';
  String get hintTapPawn => 'Tap a highlighted pawn to move';
  String get hintPawnMoving => 'Pawn is moving...';
  String hintRolling(String name) => '$name is rolling...';
  String hintThinking(String name) => '$name is thinking...';

  // -------------------------------------------------------------------------
  // Game over screen
  // -------------------------------------------------------------------------

  String get gameOver => 'Game Over';
  String get playAgain => 'Play Again';
  String get backToMenu => 'Back to Menu';
  String allTimeWins(int wins, int streak) =>
      'All-time wins: $wins   ·   Best streak: $streak';

  ///Ordinal label for a placement row, e.g. 1 → '1st'
  String rankLabel(int rank) {
    switch (rank) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${rank}th';
    }
  }

  // -------------------------------------------------------------------------
  // Statistics screen
  // -------------------------------------------------------------------------

  String get statsEmpty => 'Play your first match to start filling these stats.';
  String get statMatchesPlayed => 'Matches played';
  String get statMatchesWon => 'Matches won';
  String get statWinRate => 'Win rate';
  String get statMatchesLost => 'Matches lost';
  String get statWinStreak => 'Win streak';
  String get statBestStreak => 'Best streak';
  String get statCapturesFor => 'Captures for';
  String get statCapturesAgainst => 'Captures against';
  String get statSixesRolled => 'Sixes rolled';
  String get winsByColor => 'Wins by color';
  String get winsByDifficulty => 'Wins by difficulty';
  String get resetStatistics => 'Reset statistics';
  String get resetStatisticsTitle => 'Reset statistics?';
  String get resetStatisticsBody =>
      'Every recorded match, win, capture and streak will be cleared. This cannot be undone.';
  String get cancel => 'Cancel';
  String get reset => 'Reset';

  ///Display name for a board color
  String colorName(LudoPlayerType type) {
    switch (type) {
      case LudoPlayerType.green:
        return 'Green';
      case LudoPlayerType.yellow:
        return 'Yellow';
      case LudoPlayerType.blue:
        return 'Blue';
      case LudoPlayerType.red:
        return 'Red';
    }
  }

  // -------------------------------------------------------------------------
  // Achievements screen
  // -------------------------------------------------------------------------

  String unlockedOfTotal(int unlocked, int total) => '$unlocked of $total unlocked';

  // -------------------------------------------------------------------------
  // On-board turn indicator
  // -------------------------------------------------------------------------

  String turnAnnouncement(String name) => "$name's turn!";
  String get turnRollDice => 'Roll the dice';
  String get turnPickPawn => 'Pick a pawn';
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings.en;

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
