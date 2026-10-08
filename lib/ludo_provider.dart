import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ludo_flutter/game_config.dart';
import 'package:ludo_flutter/ludo_player.dart';
import 'package:ludo_flutter/rules.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio.dart';
import 'constants.dart';

///A rewind point captured just before a human pawn move
class _UndoSnapshot {
  final Map<String, List<int>> steps;
  final LudoPlayerType turn;
  final int dice;
  final LudoGameState state;
  final List<LudoPlayerType> winners;
  final int consecutiveSixes;

  _UndoSnapshot({
    required this.steps,
    required this.turn,
    required this.dice,
    required this.state,
    required this.winners,
    required this.consecutiveSixes,
  });
}

class LudoProvider extends ChangeNotifier {
  ///SharedPreferences key for the suspended match
  static const String saveKey = 'saved_match';

  ///Shared RNG for dice rolls and auto-picks
  static final Random _random = Random();

  ///Test hook: when set, its value (clamped to 1..6) replaces the RNG draw
  ///in [throwDice] so scenarios like triple sixes or exact captures can be
  ///reproduced deterministically. Always null in the shipped game.
  @visibleForTesting
  int Function()? debugDiceRoll;

  ///Flags to check if pawn is moving
  bool _isMoving = false;

  ///Flags to stop pawn once disposed
  bool _stopMoving = false;

  ///Flags to freeze the match while a dialog (pause menu) is open
  bool _paused = false;

  ///Invalidated whenever the match restarts so pending timers stop touching stale state
  int _generation = 0;

  ///Incremented on every startGame so stats record each finished match once
  int _matchId = 0;

  ///Process-wide id source: seeded from the clock so ids never repeat
  ///across app launches, where [StatsProvider.lastRecordedMatchId] lives on
  static int _matchSequence = DateTime.now().millisecondsSinceEpoch;

  ///Timer used to drive CPU turns
  Timer? _cpuTimer;

  ///Debounced save of the suspended match
  Timer? _persistTimer;

  LudoGameState _gameState = LudoGameState.throwDice;

  ///Game state to check if the game is in throw dice state or pick pawn state
  LudoGameState get gameState => _gameState;

  LudoPlayerType _currentTurn = LudoPlayerType.green;

  int _diceResult = 0;

  ///Consecutive sixes rolled by the player whose turn it is
  int _consecutiveSixes = 0;

  GameConfig _config = GameConfig.defaults();

  ///Configuration of the current match
  GameConfig get config => _config;

  ///True while the pause menu is open
  bool get isPaused => _paused;

  ///True once the match is decided
  bool get isFinished => _gameState == LudoGameState.finish;

  ///Unique id of the current match, used so stats record a match only once
  int get matchId => _matchId;

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

  ///Pawns captured by each color during this match
  final Map<LudoPlayerType, int> capturesMade = {};

  ///Pawns of each color captured by opponents during this match
  final Map<LudoPlayerType, int> capturesTaken = {};

  ///Sixes rolled by each color during this match
  final Map<LudoPlayerType, int> sixesRolled = {};

  ///Rewind points captured before human moves (capped)
  final List<_UndoSnapshot> _undoStack = [];

  static const int _maxUndoDepth = 20;

  LudoPlayer player(LudoPlayerType type) => players.firstWhere((element) => element.type == type);

  ///Moves the current player may make with the current dice roll.
  ///Single source of truth for highlighting, CPU picks and legality.
  List<MoveCandidate> currentLegalMoves() {
    if (players.isEmpty || _diceResult < 1) return const [];
    return Rules.legalMoves(
      player: currentPlayer,
      dice: diceResult,
      allPlayers: players,
      exactFinish: _config.exactFinish,
      blocking: _config.blocking,
    );
  }

  ///This method will check if the pawn can kill another pawn or not by checking the landing cell
  bool _resolveCaptures(LudoPlayerType type, int landingStep, List<List<double>> path) {
    if (landingStep < 0) return false;
    if (Rules.isSafeCell(path[landingStep])) return false;
    bool killSomeone = false;
    final List<double> landing = path[landingStep];
    for (final other in players) {
      if (other.type == type) continue;
      for (int i = 0; i < other.pawns.length; i++) {
        final pawn = other.pawns[i];
        if (pawn.step < 0) continue;
        final pawnPosition = other.path[pawn.step];
        if (pawnPosition[0] == landing[0] && pawnPosition[1] == landing[1]) {
          killSomeone = true;
          other.movePawn(i, -1);
          capturesMade[type] = (capturesMade[type] ?? 0) + 1;
          capturesTaken[other.type] = (capturesTaken[other.type] ?? 0) + 1;
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
    Audio.rollDice(); //fire and forget: sound + light haptic

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
    final forced = debugDiceRoll?.call();
    //Uniform random between 1 - 6, or the clamped test override
    _diceResult = forced == null
        ? _random.nextInt(6) + 1
        : (forced < 1 ? 1 : (forced > 6 ? 6 : forced));
    if (_diceResult == 6) {
      _consecutiveSixes++;
      sixesRolled[currentPlayer.type] = (sixesRolled[currentPlayer.type] ?? 0) + 1;
    } else {
      _consecutiveSixes = 0;
    }
    notifyListeners();

    ///Classic variation: a third consecutive 6 forfeits the turn
    if (_config.threeSixesForfeit && _diceResult == 6 && _consecutiveSixes >= 3) {
      nextTurn();
      return;
    }

    final moves = currentLegalMoves();

    if (moves.isEmpty) {
      ///No legal move: re-roll on a 6 (when allowed) or pass the turn
      if (diceResult == 6 && _config.extraRollOnSix) {
        _gameState = LudoGameState.throwDice;
        notifyListeners();
      } else {
        nextTurn();
      }
      return;
    }

    for (final move in moves) {
      currentPlayer.highlightPawn(move.pawnIndex);
    }
    _gameState = LudoGameState.pickPawn;
    notifyListeners();

    ///CPU selects through the difficulty-aware brain
    if (currentPlayer.isCpu) return;

    ///Automatically move when only one pawn can move, or all candidates
    ///sit on the same step (the outcome is identical either way)
    if (moves.length == 1) {
      move(currentPlayer.type, moves.first.pawnIndex, moves.first.toStep);
      return;
    }
    if (moves.every((m) => m.fromStep == moves.first.fromStep)) {
      final chosen = moves[_random.nextInt(moves.length)];
      move(currentPlayer.type, chosen.pawnIndex, chosen.toStep);
    }
  }

  ///UI entry point for tapping a pawn: validates the pick against the
  ///current legal moves (exact finish, blocking, base exit) and executes it.
  void pickAndMove(int pawnIndex) {
    if (_isMoving || _paused || isFinished) return;
    if (_gameState != LudoGameState.pickPawn) return;
    if (currentPlayer.isCpu) return;
    final moves = currentLegalMoves();
    MoveCandidate? match;
    for (final m in moves) {
      if (m.pawnIndex == pawnIndex) match = m;
    }
    if (match == null) return;
    Audio.hapticLight(); //the player committed to a pawn
    move(currentPlayer.type, match.pawnIndex, match.toStep);
  }

  ///Move pawn to next step and check if it can kill other pawn
  void move(LudoPlayerType type, int index, int toStep) async {
    if (_isMoving || _paused || isFinished) return;
    if (type != _currentTurn) return;
    var selectedPlayer = player(type);

    ///Never move past the finish cell
    if (toStep > selectedPlayer.path.length - 1) return;
    if (toStep < 0) return;
    if (index < 0 || index >= selectedPlayer.pawns.length) return;

    ///Only human moves are rewindable; capture the state before the pick
    if (!selectedPlayer.isCpu) _pushUndo();

    final int generation = _generation;
    _isMoving = true;
    _gameState = LudoGameState.moving;

    currentPlayer.highlightAllPawns(false);
    notifyListeners();

    final int fromStep = selectedPlayer.pawns[index].step;
    for (int i = fromStep + 1; i <= toStep; i++) {
      if (_stopMoving || generation != _generation) break;
      selectedPlayer.movePawn(index, i);
      await Audio.playMove();
      if (generation != _generation) return;
      notifyListeners();
    }
    if (generation != _generation) {
      _isMoving = false;
      return;
    }

    final bool captured = _resolveCaptures(type, toStep, selectedPlayer.path);
    if (captured) {
      Audio.playKill();
      Audio.haptic();
    }

    validateWin(type);
    _isMoving = false;

    if (isFinished) {
      Audio.hapticHeavy();
      notifyListeners();
      return;
    }

    final bool extraRoll = (diceResult == 6 && _config.extraRollOnSix) ||
        (captured && _config.captureGrantsRoll);
    if (extraRoll) {
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
    _consecutiveSixes = 0;
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
        _clearSavedMatch();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Undo
  // ---------------------------------------------------------------------------

  void _pushUndo() {
    _undoStack.add(_UndoSnapshot(
      steps: {for (final p in players) p.type.name: p.saveSteps()},
      turn: _currentTurn,
      dice: _diceResult,
      state: _gameState,
      winners: List.of(winners),
      consecutiveSixes: _consecutiveSixes,
    ));
    if (_undoStack.length > _maxUndoDepth) _undoStack.removeAt(0);
  }

  ///True when the player can take back their most recent move
  bool get canUndo {
    if (isFinished || _isMoving || _diceStarted || _paused) return false;
    if (players.isEmpty || currentPlayer.isCpu) return false;
    return _findUndoSnapshot() != null;
  }

  _UndoSnapshot? _findUndoSnapshot() {
    for (int i = _undoStack.length - 1; i >= 0; i--) {
      if (_undoStack[i].turn == _currentTurn) return _undoStack[i];
    }
    return null;
  }

  ///Rewind to the moment just before the current player's most recent move
  void undoLastMove() {
    if (!canUndo) return;
    final snapshot = _findUndoSnapshot();
    if (snapshot == null) return;

    ///Drop every snapshot newer than the one we restore
    while (_undoStack.isNotEmpty && !identical(_undoStack.last, snapshot)) {
      _undoStack.removeLast();
    }
    _undoStack.removeLast();

    _generation++;
    _cpuTimer?.cancel();
    _cpuTimer = null;
    _isMoving = false;
    _diceStarted = false;
    _paused = false;

    _currentTurn = snapshot.turn;
    _diceResult = snapshot.dice;
    _consecutiveSixes = snapshot.consecutiveSixes;
    winners
      ..clear()
      ..addAll(snapshot.winners);

    for (final player in players) {
      player.restoreSteps(snapshot.steps[player.type.name] ?? List.filled(4, -1));
      player.highlightAllPawns(false);
    }

    _gameState = snapshot.state == LudoGameState.moving
        ? LudoGameState.pickPawn
        : snapshot.state;

    ///Recompute highlights so the restored pick is playable again
    if (_gameState == LudoGameState.pickPawn) {
      final moves = currentLegalMoves();
      if (moves.isEmpty) {
        _gameState = LudoGameState.throwDice;
      } else {
        for (final m in moves) {
          currentPlayer.highlightPawn(m.pawnIndex);
        }
      }
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Save / resume
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toSaveJson() => {
        'config': _config.toJson(),
        'steps': {for (final p in players) p.type.name: p.saveSteps()},
        'turn': _currentTurn.name,
        'dice': _diceResult,
        'state': _gameState.name,
        'winners': [for (final w in winners) w.name],
        'sixes': _consecutiveSixes,
        'capturesMade': {for (final e in capturesMade.entries) e.key.name: e.value},
        'capturesTaken': {for (final e in capturesTaken.entries) e.key.name: e.value},
        'sixesRolled': {for (final e in sixesRolled.entries) e.key.name: e.value},
        'matchId': _matchId,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      };

  ///Schedule a debounced persist; multiple notifies collapse into one write
  void _schedulePersist() {
    if (isFinished || players.isEmpty) return;
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 500), _persistNow);
  }

  ///Write immediately when the state is stable (turn boundaries, pause, lifecycle)
  void flushSave() {
    _persistTimer?.cancel();
    _persistTimer = null;
    if (_isMoving || _diceStarted || isFinished || players.isEmpty) return;
    _persistNow();
  }

  void _persistNow() async {
    if (_isMoving || _diceStarted || isFinished || players.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(saveKey, jsonEncode(toSaveJson()));
    } catch (_) {
      ///Persistence is best-effort; a failed write never breaks the match
    }
  }

  Future<void> _clearSavedMatch() async {
    _persistTimer?.cancel();
    _persistTimer = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(saveKey);
    } catch (_) {}
  }

  ///True when a suspended match is waiting on the menu
  static Future<bool> savedMatchExists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(saveKey) != null;
    } catch (_) {
      return false;
    }
  }

  ///Restore the suspended match. Returns false when nothing usable was saved.
  Future<bool> resumeSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(saveKey);
    if (raw == null) return false;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final config = GameConfig.fromJson(Map<String, dynamic>.from(json['config'] as Map));
      startGame(config, false);

      final steps = Map<String, dynamic>.from(json['steps'] as Map);
      for (final player in players) {
        final list = (steps[player.type.name] as List?)?.cast<int>();
        if (list != null) player.restoreSteps(list);
      }

      winners
        ..clear()
        ..addAll(((json['winners'] as List?) ?? const [])
            .map((e) => LudoPlayerType.values.byName(e as String)));

      _currentTurn = LudoPlayerType.values.byName(json['turn'] as String);
      _diceResult = (json['dice'] as num?)?.toInt() ?? 0;
      _consecutiveSixes = (json['sixes'] as num?)?.toInt() ?? 0;

      ///Keep the suspended match's id so resuming never re-records or
      ///skips the match in the lifetime statistics
      final savedMatchId = (json['matchId'] as num?)?.toInt();
      if (savedMatchId != null) _matchId = savedMatchId;

      _restoreCounters(capturesMade, json['capturesMade']);
      _restoreCounters(capturesTaken, json['capturesTaken']);
      _restoreCounters(sixesRolled, json['sixesRolled']);

      final stateName = json['state'] as String? ?? LudoGameState.throwDice.name;
      LudoGameState state = LudoGameState.values.firstWhere(
        (s) => s.name == stateName,
        orElse: () => LudoGameState.throwDice,
      );
      if (state == LudoGameState.moving || state == LudoGameState.finish) {
        state = LudoGameState.throwDice;
      }
      _gameState = state;

      if (_gameState == LudoGameState.pickPawn) {
        final moves = currentLegalMoves();
        if (moves.isEmpty) {
          _gameState = LudoGameState.throwDice;
        } else {
          for (final m in moves) {
            currentPlayer.highlightPawn(m.pawnIndex);
          }
        }
      }

      notifyListeners();
      return true;
    } catch (_) {
      ///Corrupt save: drop it and let the caller start fresh
      await prefs.remove(saveKey);
      return false;
    }
  }

  static void _restoreCounters(Map<LudoPlayerType, int> target, dynamic raw) {
    target.clear();
    if (raw is Map) {
      for (final entry in raw.entries) {
        target[LudoPlayerType.values.byName(entry.key as String)] =
            (entry.value as num?)?.toInt() ?? 0;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  ///Start a brand new match with the given configuration (defaults to a 4 player match)
  void startGame([GameConfig? config, bool persist = true]) {
    _cpuTimer?.cancel();
    _cpuTimer = null;
    _persistTimer?.cancel();
    _persistTimer = null;
    _generation++;
    _matchId = ++_matchSequence;

    _config = config ?? GameConfig.defaults();
    _isMoving = false;
    _stopMoving = false;
    _paused = false;
    _diceStarted = false;
    _diceResult = 0;
    _consecutiveSixes = 0;
    _gameState = LudoGameState.throwDice;

    winners.clear();
    capturesMade.clear();
    capturesTaken.clear();
    sixesRolled.clear();
    _undoStack.clear();
    players.clear();
    players.addAll([
      for (final setup in _config.players)
        LudoPlayer(setup.color, name: setup.name, isCpu: setup.isCpu),
    ]);
    _currentTurn = players.first.type;
    notifyListeners();
    if (persist) _schedulePersist();
  }

  ///Replay the same configuration
  void restartGame() => startGame(_config);

  ///Quit the current match and drop the suspended save
  void quitMatch() {
    _generation++;
    _cpuTimer?.cancel();
    _cpuTimer = null;
    _clearSavedMatch();
    players.clear();
    winners.clear();
    _undoStack.clear();
    _gameState = LudoGameState.throwDice;
    notifyListeners();
  }

  ///Freeze or resume the match (used by the pause menu)
  void setPaused(bool value) {
    if (_paused == value) return;
    _paused = value;
    if (value) {
      _cpuTimer?.cancel();
      _cpuTimer = null;
      flushSave();
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
    final moves = currentLegalMoves();
    if (moves.isEmpty) return nextTurn();

    final chosenIndex = Rules.chooseCpuPawn(
      moves,
      _config.cpuDifficulty,
      pathLength: currentPlayer.path.length,
      random: _random,
    );
    if (chosenIndex == null) return nextTurn();
    final chosen = moves.firstWhere((m) => m.pawnIndex == chosenIndex);
    move(currentPlayer.type, chosen.pawnIndex, chosen.toStep);
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
    _scheduleCpu();
    _schedulePersist();
  }

  @override
  void dispose() {
    _stopMoving = true;
    _generation++;
    _cpuTimer?.cancel();
    _cpuTimer = null;
    _persistTimer?.cancel();
    _persistTimer = null;
    super.dispose();
  }

  static LudoProvider read(BuildContext context) => context.read();
}
