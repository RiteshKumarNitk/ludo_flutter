import 'package:flutter/widgets.dart';

import 'controller/ludo_controller.dart';
import 'models/ludo_models.dart';

///Ludo's user-facing strings (English). Kept beside the game so a future
///game never depends on them.
class LudoStrings {
  const LudoStrings();

  static LudoStrings of(BuildContext context) => const LudoStrings();

  String get title => 'Ludo';
  String get tagline => 'The classic race home';
  String get players => '2–4 players';

  //Setup
  String get setupTitle => 'New match';
  String get playersLabel => 'PLAYERS';
  String get modeLabel => 'MODE';
  String get difficultyLabel => 'DIFFICULTY';
  String get seatsLabel => 'AT THE TABLE';
  String get vsComputer => 'VS COMPUTER';
  String get vsComputerHint => 'You against bots';
  String get passAndPlay => 'PASS & PLAY';
  String get passAndPlayHint => 'Friends on one phone';
  String get easy => 'Easy';
  String get medium => 'Medium';
  String get hard => 'Hard';
  String difficultyHint(BotDifficulty d) {
    switch (d) {
      case BotDifficulty.easy:
        return 'Bots pick any legal move.';
      case BotDifficulty.medium:
        return 'Bots race their leading pawn home.';
      case BotDifficulty.hard:
        return 'Bots hunt captures, play safe and dodge danger.';
    }
  }

  String get startGame => 'START GAME';
  String get human => 'Human';
  String get bot => 'Bot';
  String get tapToRename => 'Tap a name to rename';
  String get tapSeatToggle => 'Tap Human / Bot to switch a seat';
  String get renameTitle => 'Player name';
  String get save => 'SAVE';
  String get you => 'You';
  String playerN(int n) => 'Player $n';
  String botName(LudoColor c) => '${c.label} Bot';
  String get goesFirst => 'Goes first';
  String get replaceSavedTitle => 'Start a new match?';
  String get replaceSavedBody => 'Your unfinished match will be replaced.';
  String get startNew => 'START NEW';

  //Game
  String get pause => 'Pause';
  String get leaveTitle => 'Leave game?';
  String get leaveBody => 'Your match is saved. You can continue it from the home screen.';
  String get continueGame => 'CONTINUE';
  String get leaveGame => 'LEAVE GAME';
  String get yourTurn => 'Your turn';
  String turnOf(String name) => "$name's turn";
  String get tapDice => 'Tap the dice to roll';
  String get pickPawn => 'Tap a glowing pawn to move';
  String get moving => 'Moving…';
  String get rolling => 'Rolling…';
  String thinking(String name) => '$name is thinking…';
  String get paused => 'Paused';
  String get finishedLabel => 'Finished';
  String pawnsHome(int n) => '$n/4 home';
  String get passing => 'Passing the dice…';
  String get botThinking => 'Thinking…';

  String banner(LudoBanner banner, String name) {
    switch (banner.kind) {
      case LudoBannerKind.sixRollAgain:
        return 'Six! Roll again';
      case LudoBannerKind.extraRoll:
        return 'Extra roll!';
      case LudoBannerKind.captured:
        return 'Captured! Roll again';
      case LudoBannerKind.threeSixes:
        return 'Three sixes — turn lost';
      case LudoBannerKind.noMove:
        return 'No moves';
      case LudoBannerKind.playerFinished:
        return '$name finished ${ordinal(banner.place ?? 1)}!';
    }
  }

  //Result
  String get youWin => 'YOU WIN!';
  String get youLost => 'YOU LOST';
  String get gameOver => 'GAME OVER';
  String winsTitle(String name) => '${name.toUpperCase()} WINS!';
  String get betterLuck => 'Better luck next time!';
  String get greatGame => 'What a game!';
  String finishedPlace(String place) => 'You finished $place';
  String get winner => 'WINNER';
  String get standings => 'STANDINGS';
  String get duration => 'Duration';
  String get turns => 'Turns';
  String get captures => 'Captures';
  String get sixes => 'Sixes';
  String get home => 'Home';
  String get playAgain => 'PLAY AGAIN';
  String get newGame => 'NEW GAME';
  String get homeButton => 'HOME';

  String ordinal(int n) {
    switch (n) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${n}th';
    }
  }

  String modeName(LudoMode mode) => mode == LudoMode.vsComputer ? 'vs Computer' : 'Pass & Play';

  String resumeSummary(ResumableSummary s) => '${s.players} players · ${modeName(s.mode)}';

  //Settings
  String get boardTheme => 'Board theme';
  String get sectionTitle => 'LUDO';

  //Records
  String get records => 'Records';
  String get statistics => 'Statistics';
  String get achievements => 'Achievements';
  String get noMatchesTitle => 'No matches yet';
  String get noMatchesBody => 'Finish your first match and your records will show up here.';
  String get playLudo => 'PLAY LUDO';
  String get wins => 'Wins';
  String get losses => 'Losses';
  String get winRate => 'Win rate';
  String get played => 'Played';
  String get bestStreak => 'Best streak';
  String get currentStreak => 'Current streak';
  String get pawnsCaptured => 'Pawns captured';
  String get pawnsLost => 'Pawns lost';
  String get sixesRolled => 'Sixes rolled';
  String get passAndPlayGames => 'Pass & play';
  String get vsComputerStats => 'VS COMPUTER';
  String get winsByDifficulty => 'WINS BY DIFFICULTY';
  String get resetRecords => 'Reset records';
  String get resetRecordsTitle => 'Reset records?';
  String get resetRecordsBody => 'All statistics and achievement progress will be cleared. This cannot be undone.';
  String unlockedOf(int a, int b) => '$a of $b unlocked';
  String get achievementsHint => 'Play against the computer to unlock achievements.';
  String difficultyName(BotDifficulty d) => d == BotDifficulty.easy
      ? easy
      : d == BotDifficulty.medium
          ? medium
          : hard;
}
