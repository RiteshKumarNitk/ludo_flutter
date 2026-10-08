import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ludo_flutter/game_config.dart';
import 'package:ludo_flutter/ludo_player.dart';
import 'package:provider/provider.dart';

import 'audio.dart';
import 'constants.dart';

class LudoProvider extends ChangeNotifier {
  ///Flags to check if pawn is moving
  bool _isMoving = false;

  ///Flags to stop pawn once disposed
  bool _stopMoving = false;

  ///Flags to freeze the match while a dialog (pause menu) is open
  bool _paused = false;

  ///Invalidated whenever the match restarts so pending timers stop touching stale state
  int _generation = 0;

  ///Timer used to drive CPU turns
  Timer? _cpuTimer;

  LudoGameState _gameState = LudoGameState.throwDice;

  ///Game state to check if the game is in throw dice state or pick pawn state
  LudoGameState get gameState => _gameState;

  LudoPlayerType _currentTurn = LudoPlayerType.green;

  int _diceResult = 0;

  GameConfig _config = GameConfig.defaults();

  ///Configuration of the current match
  GameConfig get config => _config;

  ///True while the pause menu is open
  bool get isPaused => _paused;

  ///True once the match is decided
  bool get isFinished => _gameState == LudoGameState.finish;

  ///Dice result to check the dice result of the current turn
  int get diceResult {
    if (_diceResult < 1) {
      return 1;
    } else {
      if (_diceResult > 6) {
        return 6;
      } else {
        return _diceResult;
      }
    }
  }

  bool _diceStarted = false;
  bool get diceStarted => _diceStarted;

  bool get isCpuTurn => players.isNotEmpty && currentPlayer.isCpu;

  LudoPlayer get currentPlayer => players.firstWhere((element) => element.type == _currentTurn);

  ///Fill all players
  final List<LudoPlayer> players = [];

  ///Player win, we use `LudoPlayerType` to make it easier to check
  final List<LudoPlayerType> winners = [];

  LudoPlayer player(LudoPlayerType type) => players.firstWhere((element) => element.type == type);

  ///This method will check if the pawn can kill another pawn or not by checking the step of the pawn
  bool checkToKill(LudoPlayerType type, int index, int step, List<List<double>> path) {
    if (step < 1) return false;
    bool killSomeone = false;
    for (final other in players) {
      if (other.type == type) continue;
      for (int i = 0; i < other.pawns.length; i++) {
        final pawn = other.pawns[i];
        if (pawn.step < 0) continue;
        final pawnPosition = other.path[pawn.step];
        if (LudoPath.safeArea.any((safe) => safe.toString() == pawnPosition.toString())) continue;
        if (pawnPosition.toString() == path[step - 1].toString()) {
          killSomeone = true;
          other.movePawn(i, -1);
          notifyListeners();
        }
      }
    }
    return killSomeone;
  }

  ///This is the function that will be called to throw the dice
  void throwDice() async {
    if (_paused || _isMoving || _diceStarted) return;
    if (_gameState != LudoGameState.throwDice) return;
    if (players.isEmpty || isFinished) return;
    final int generation = _generation;

    _diceStarted = true;
    notifyListeners();
    Audio.rollDice();

    //Check if already win skip
    if (winners.contains(currentPlayer.type)) {
      _diceStarted = false;
      nextTurn();
      return;
    }

    //Turn off highlight for all pawns
    currentPlayer.highlightAllPawns(false);

    await Future.delayed(const Duration(seconds: 1));
    if (generation != _generation) return;

    _diceStarted = false;
    var random = Random();
    _diceResult = random.nextBool() ? 6 : random.nextInt(6) + 1; //Random between 1 - 6
    notifyListeners();

    if (diceResult == 6) {
      currentPlayer.highlightAllPawns();
      _gameState = LudoGameState.pickPawn;
      notifyListeners();
    } else {
      /// all pawns are inside home
      if (currentPlayer.pawnInsideCount == 4) {
        return nextTurn();
      } else {
        ///Hightlight all pawn outside
        currentPlayer.highlightOutside();
        _gameState = LudoGameState.pickPawn;
        notifyListeners();
      }
    }

    ///Check and disable if any pawn already in the finish box
    for (var i = 0; i < currentPlayer.pawns.length; i++) {
      var pawn = currentPlayer.pawns[i];
      if ((pawn.step + diceResult) > currentPlayer.path.length - 1) {
        currentPlayer.highlightPawn(i, false);
      }
    }

    ///Automatically move random pawn if all pawn are in same step
    var moveablePawn = currentPlayer.pawns.where((e) => e.highlight).toList();
    if (moveablePawn.length > 1) {
      var biggestStep = moveablePawn.map((e) => e.step).reduce(max);
      if (moveablePawn.every((element) => element.step == biggestStep)) {
        var random = 1 + Random().nextInt(moveablePawn.length - 1);
        var thePawn = moveablePawn[random];
        if (thePawn.step == -1) {
          move(thePawn.type, thePawn.index, (thePawn.step + 1) + 1);
        } else {
          move(thePawn.type, thePawn.index, (thePawn.step + 1) + diceResult);
        }
        return;
      }
    }

    ///If User have 6 dice, but it inside finish line, it will make him to throw again, else it will turn to next player
    if (currentPlayer.pawns.every((element) => !element.highlight)) {
      if (diceResult == 6 && _config.extraRollOnSix) {
        _gameState = LudoGameState.throwDice;
        notifyListeners();
      } else {
        nextTurn();
        return;
      }
    }

    if (currentPlayer.pawns.where((element) => element.highlight).length == 1) {
      var index = currentPlayer.pawns.indexWhere((element) => element.highlight);
      move(currentPlayer.type, index, (currentPlayer.pawns[index].step + 1) + diceResult);
    }
  }

  ///Move pawn to next step and check if it can kill other pawn
  void move(LudoPlayerType type, int index, int step) async {
    if (_isMoving || _paused || isFinished) return;
    var selectedPlayer = player(type);

    ///Never move past the finish cell
    if (step > selectedPlayer.path.length) return;
    if (step < 1) return;
    if (index < 0 || index >= selectedPlayer.pawns.length) return;

    final int generation = _generation;
    _isMoving = true;
    _gameState = LudoGameState.moving;

    currentPlayer.highlightAllPawns(false);
    notifyListeners();

    for (int i = selectedPlayer.pawns[index].step; i < step; i++) {
      if (_stopMoving || generation != _generation) break;
      if (selectedPlayer.pawns[index].step == i) continue;
      selectedPlayer.movePawn(index, i);
      await Audio.playMove();
      if (generation != _generation) return;
      notifyListeners();
    }
    if (generation != _generation) {
      _isMoving = false;
      return;
    }

    if (checkToKill(type, index, step, selectedPlayer.path)) {
      _isMoving = false;
      _gameState = LudoGameState.throwDice;
      Audio.playKill();
      Audio.haptic();
      notifyListeners();
      return;
    }

    validateWin(type);
    _isMoving = false;

    if (isFinished) {
      notifyListeners();
      return;
    }

    if (diceResult == 6 && _config.extraRollOnSix) {
      _gameState = LudoGameState.throwDice;
      notifyListeners();
    } else {
      nextTurn();
    }
  }

  ///Next turn will be called when the player finish the turn
  void nextTurn() {
    if (players.isEmpty || isFinished) return;

    int index = players.indexWhere((element) => element.type == _currentTurn);
    if (index < 0) index = 0;
    for (int i = 0; i < players.length; i++) {
      index = (index + 1) % players.length;
      if (!winners.contains(players[index].type)) break;
    }

    _currentTurn = players[index].type;
    _gameState = LudoGameState.throwDice;
    notifyListeners();
  }

  ///This function will check if the pawn finish the game or not
  void validateWin(LudoPlayerType color) {
    if (winners.contains(color)) return;
    final selectedPlayer = player(color);
    if (selectedPlayer.pawns.every((element) => element.step == selectedPlayer.path.length - 1)) {
      winners.add(color);

      ///Last standing player does not need to play anymore
      if (winners.length >= players.length - 1) {
        _gameState = LudoGameState.finish;
        _cpuTimer?.cancel();
        _cpuTimer = null;
      }
    }
  }

  ///Start a brand new match with the given configuration (defaults to a 4 player match)
  void startGame([GameConfig? config]) {
    _cpuTimer?.cancel();
    _cpuTimer = null;
    _generation++;

    _config = config ?? GameConfig.defaults();
    _isMoving = false;
    _stopMoving = false;
    _paused = false;
    _diceStarted = false;
    _diceResult = 0;
    _gameState = LudoGameState.throwDice;

    winners.clear();
    players.clear();
    players.addAll([
      for (final setup in _config.players)
        LudoPlayer(setup.color, name: setup.name, isCpu: setup.isCpu),
    ]);
    _currentTurn = players.first.type;
    notifyListeners();
  }

  ///Replay the same configuration
  void restartGame() => startGame(_config);

  ///Freeze or resume the match (used by the pause menu)
  void setPaused(bool value) {
    if (_paused == value) return;
    _paused = value;
    if (value) {
      _cpuTimer?.cancel();
      _cpuTimer = null;
    }
    notifyListeners();
  }

  ///Computer players roll and pick a pawn automatically
  void _scheduleCpu() {
    if (_paused || isFinished) return;
    if (_diceStarted || _isMoving) return;
    if (players.isEmpty) return;
    if (_cpuTimer != null && _cpuTimer!.isActive) return;
    if (_gameState != LudoGameState.throwDice && _gameState != LudoGameState.pickPawn) return;
    if (!currentPlayer.isCpu) return;

    final int generation = _generation;
    final Duration delay = _gameState == LudoGameState.throwDice
        ? const Duration(milliseconds: 900)
        : const Duration(milliseconds: 700);

    _cpuTimer = Timer(delay, () {
      _cpuTimer = null;
      if (generation != _generation) return;
      if (_paused || isFinished || _isMoving || _diceStarted) return;
      if (!currentPlayer.isCpu) return;
      if (_gameState == LudoGameState.throwDice) {
        throwDice();
      } else if (_gameState == LudoGameState.pickPawn) {
        _cpuPickPawn();
      }
    });
  }

  void _cpuPickPawn() {
    if (players.isEmpty || !currentPlayer.isCpu || isFinished) return;
    final movable = currentPlayer.pawns.where((element) => element.highlight).toList();
    if (movable.isEmpty) return nextTurn();

    ///Prefer the pawn that is closest to the finish line
    movable.sort((a, b) => b.step.compareTo(a.step));
    final chosen = movable.first;
    final int target = chosen.step == -1 ? 1 : (chosen.step + 1) + diceResult;
    move(chosen.type, chosen.index, target);
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _scheduleCpu();
  }

  @override
  void dispose() {
    _stopMoving = true;
    _generation++;
    _cpuTimer?.cancel();
    _cpuTimer = null;
    super.dispose();
  }

  static LudoProvider read(BuildContext context) => context.read();
}
