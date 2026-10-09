import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/audio/sound_effects.dart';
import '../../../core/settings/app_settings.dart';
import '../data/ludo_records.dart';
import '../data/ludo_save_store.dart';
import '../engine/ludo_bot.dart';
import '../engine/ludo_engine.dart';
import '../engine/ludo_rules.dart';
import '../models/ludo_models.dart';
import '../models/ludo_state.dart';

///Timings of the match presentation. They only pace how fast the
///controller *shows* engine results; they never decide the results.
class LudoPacing {
  final Duration roll;
  final Duration step;
  final Duration captureReturn;
  final Duration botThink;
  final Duration autoMove;
  final Duration turnEnd;
  final Duration banner;

  const LudoPacing({
    required this.roll,
    required this.step,
    required this.captureReturn,
    required this.botThink,
    required this.autoMove,
    required this.turnEnd,
    required this.banner,
  });

  static const normal = LudoPacing(
    roll: Duration(milliseconds: 620),
    step: Duration(milliseconds: 170),
    captureReturn: Duration(milliseconds: 420),
    botThink: Duration(milliseconds: 520),
    autoMove: Duration(milliseconds: 380),
    turnEnd: Duration(milliseconds: 520),
    banner: Duration(milliseconds: 1300),
  );

  static const fast = LudoPacing(
    roll: Duration(milliseconds: 380),
    step: Duration(milliseconds: 105),
    captureReturn: Duration(milliseconds: 280),
    botThink: Duration(milliseconds: 280),
    autoMove: Duration(milliseconds: 220),
    turnEnd: Duration(milliseconds: 320),
    banner: Duration(milliseconds: 1000),
  );

  ///For tests: everything happens on the next tick
  static const instant = LudoPacing(
    roll: Duration.zero,
    step: Duration.zero,
    captureReturn: Duration.zero,
    botThink: Duration.zero,
    autoMove: Duration.zero,
    turnEnd: Duration.zero,
    banner: Duration.zero,
  );
}

enum LudoBannerKind { sixRollAgain, extraRoll, captured, threeSixes, noMove, playerFinished }

///Short-lived on-board announcement
class LudoBanner {
  final int id;
  final LudoBannerKind kind;
  final LudoColor color;
  final int? place;
  const LudoBanner(this.id, this.kind, this.color, {this.place});
}

///Coordinates one Ludo match: engine, animation pacing, audio, haptics,
///persistence and bot turns. Widgets read from it and send intents
///([rollDice], [selectPawn]); every rule decision is made by [LudoEngine].
class LudoController extends ChangeNotifier {
  LudoController({
    required this.records,
    required this.settings,
    LudoSaveStore? store,
    Random? random,
    LudoPacing? pacing,
  })  : store = store ?? LudoSaveStore(),
        _random = random ?? Random(),
        _pacingOverride = pacing;

  final LudoRecords records;
  final AppSettings settings;
  final LudoSaveStore store;
  final Random _random;
  final LudoPacing? _pacingOverride;

  LudoMatchConfig? _config;
  LudoState? _state;
  String? _matchId;

  bool _rolling = false;
  bool _animating = false;
  bool _paused = false;

  ///Captured pawns keep their old cell on screen until the capturing pawn
  ///arrives; the committed state already has them back in base.
  final Map<PawnRef, int> _heldSteps = {};

  LudoBanner? _banner;
  int _bannerSeq = 0;
  Timer? _bannerTimer;

  Timer? _scheduled;

  ///Bumped whenever the match changes identity, so pending async work from
  ///an older match stops touching the new one
  int _generation = 0;

  final Stopwatch _clock = Stopwatch();
  Duration _elapsedBefore = Duration.zero;

  LudoPacing get pacing =>
      _pacingOverride ?? (settings.speed == GameSpeed.fast ? LudoPacing.fast : LudoPacing.normal);

  bool get hasMatch => _state != null;
  LudoState get state => _state!;
  LudoMatchConfig get config => _config!;
  String? get matchId => _matchId;
  bool get isRolling => _rolling;
  bool get isAnimating => _animating;
  bool get isPaused => _paused;
  bool get isFinished => _state?.isFinished ?? false;
  LudoBanner? get banner => _banner;
  Duration get elapsed => _elapsedBefore + _clock.elapsed;

  bool get isHumanTurn => hasMatch && !state.isFinished && !state.currentSeat.isBot;

  bool get _idle => !_rolling && !_animating && !_paused;

  bool get canRoll => isHumanTurn && state.phase == LudoPhase.roll && _idle;

  ///Pawns of the current human seat that may be tapped right now
  Set<int> get selectablePawns {
    if (!isHumanTurn || state.phase != LudoPhase.move || !_idle) return const {};
    return {for (final m in LudoRules.legalMoves(state)) m.pawn};
  }

  ///Step to draw a pawn at (differs from the state only while a capture
  ///is being animated)
  int displayStep(LudoColor color, int pawn) => _heldSteps[(color: color, index: pawn)] ?? state.stepsOf(color)[pawn];

  // ---------------------------------------------------------------------------
  // Match lifecycle
  // ---------------------------------------------------------------------------

  void startMatch(LudoMatchConfig config) {
    _teardown(clearMatch: true);
    _config = config;
    _matchId = '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
    _state = LudoEngine.start(config.seats);
    _elapsedBefore = Duration.zero;
    _clock
      ..reset()
      ..start();
    notifyListeners();
    _persist();
    _advance();
  }

  ///Shows an exact match state (tests and screenshots only)
  @visibleForTesting
  void debugShow(LudoMatchConfig config, LudoState state, {String matchId = 'debug'}) {
    _teardown(clearMatch: true);
    _config = config;
    _state = state;
    _matchId = matchId;
    notifyListeners();
    _advance();
  }

  void restart() {
    final config = _config;
    if (config != null) startMatch(config);
  }

  ///Restore the suspended match. Returns false when there is none.
  Future<bool> loadSaved() async {
    final saved = await store.load();
    if (saved == null) return false;
    _teardown(clearMatch: true);
    _config = saved.config;
    _state = saved.state;
    _matchId = saved.matchId;
    _elapsedBefore = saved.elapsed;
    _clock
      ..reset()
      ..start();
    notifyListeners();
    _advance();
    return true;
  }

  Future<ResumableSummary?> savedSummary() async {
    final saved = await store.load();
    if (saved == null) return null;
    return ResumableSummary(saved.config.seats.length, saved.config.mode, [for (final s in saved.config.seats) s.color]);
  }

  ///Leave to the menu, keeping the match saved to continue later
  Future<void> leave() async {
    if (!hasMatch) return;
    final save = isFinished ? null : _snapshot();
    _teardown(clearMatch: true);
    notifyListeners();
    if (save != null) await store.save(save);
  }

  ///End the match for good
  Future<void> quit() async {
    _teardown(clearMatch: true);
    notifyListeners();
    await store.clear();
  }

  void pause() {
    if (_paused || !hasMatch) return;
    _paused = true;
    _cancelScheduled();
    _clock.stop();
    _persist();
    notifyListeners();
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    if (!isFinished) _clock.start();
    notifyListeners();
    _advance();
  }

  // ---------------------------------------------------------------------------
  // Player intents
  // ---------------------------------------------------------------------------

  void rollDice() {
    if (!canRoll) return;
    _cancelScheduled();
    _roll();
  }

  void selectPawn(int pawn) {
    if (!selectablePawns.contains(pawn)) return;
    _cancelScheduled();
    Haptics.selection();
    _move(pawn);
  }

  // ---------------------------------------------------------------------------
  // Turn flow
  // ---------------------------------------------------------------------------

  Future<void> _roll() async {
    final generation = _generation;
    _rolling = true;
    notifyListeners();
    SoundEffects.play(Sfx.diceRoll);
    Haptics.light();

    await Future<void>.delayed(pacing.roll);
    if (generation != _generation) return;

    final color = state.currentColor;
    final step = LudoEngine.roll(state, _random.nextInt(6) + 1);
    _rolling = false;
    _commit(step);

    for (final event in step.events) {
      if (event is ThreeSixesForfeited) {
        _showBanner(LudoBannerKind.threeSixes, color);
        Haptics.medium();
      } else if (event is ExtraRollGranted) {
        _showBanner(LudoBannerKind.sixRollAgain, color);
      } else if (event is NoLegalMove && step.state.phase == LudoPhase.turnOver) {
        _showBanner(LudoBannerKind.noMove, color);
      }
    }
    notifyListeners();
    _advance();
  }

  Future<void> _move(int pawn) async {
    final generation = _generation;
    final color = state.currentColor;
    final step = LudoEngine.move(state, pawn);
    final moved = step.events.whereType<PawnMoved>().first;
    final capture = step.events.whereType<PawnCaptured>().firstOrNull;
    final cells = moved.from < 0 ? 1 : moved.to - moved.from;

    if (capture != null) _heldSteps[capture.victim] = capture.victimStep;
    _animating = true;
    _commit(step); //state first: the board animates toward it
    notifyListeners();

    //Step ticks run on the same pacing as the board animation
    for (int i = 0; i < cells; i++) {
      if (i > 0) await Future<void>.delayed(pacing.step);
      if (generation != _generation) return;
      SoundEffects.play(Sfx.step);
    }
    await Future<void>.delayed(pacing.step);
    if (generation != _generation) return;
    Haptics.selection();

    if (capture != null) {
      _heldSteps.remove(capture.victim);
      SoundEffects.play(Sfx.capture);
      Haptics.medium();
      _showBanner(LudoBannerKind.captured, color);
      notifyListeners();
      await Future<void>.delayed(pacing.captureReturn);
      if (generation != _generation) return;
    }

    final finished = step.events.whereType<MatchFinished>().isNotEmpty;
    for (final event in step.events) {
      if (event is PawnReachedHome && !finished) {
        SoundEffects.play(Sfx.home);
      } else if (event is PlayerFinished && !finished) {
        _showBanner(LudoBannerKind.playerFinished, event.color, place: event.place);
      } else if (event is ExtraRollGranted && capture == null) {
        _showBanner(LudoBannerKind.extraRoll, color);
      }
    }
    if (finished) {
      _clock.stop();
      SoundEffects.play(Sfx.win);
      Haptics.heavy();
    }

    _animating = false;
    notifyListeners();
    _advance();
  }

  ///Schedules whatever happens next without player input: bot actions,
  ///automatic single moves and passing a finished turn.
  void _advance() {
    if (!hasMatch || !_idle) return;
    _cancelScheduled();
    final s = state;
    switch (s.phase) {
      case LudoPhase.finished:
        return;
      case LudoPhase.turnOver:
        _schedule(pacing.turnEnd, s, () {
          _commit(LudoEngine.endTurn(s));
          notifyListeners();
          _advance();
        });
      case LudoPhase.roll:
        if (s.currentSeat.isBot) _schedule(pacing.botThink, s, _roll);
      case LudoPhase.move:
        if (s.currentSeat.isBot) {
          _schedule(pacing.botThink, s, () {
            final pawn = LudoBot.choosePawn(s, config.difficulty, _random);
            if (pawn != null) _move(pawn);
          });
        } else {
          //Move automatically when every choice leads to the same result
          final moves = LudoRules.legalMoves(s);
          if (moves.isNotEmpty && moves.every((m) => m.from == moves.first.from)) {
            _schedule(pacing.autoMove, s, () => _move(moves.first.pawn));
          }
        }
    }
  }

  void _schedule(Duration delay, LudoState expected, void Function() action) {
    final generation = _generation;
    _scheduled = Timer(delay, () {
      _scheduled = null;
      if (generation != _generation || _paused || !identical(_state, expected)) return;
      action();
    });
  }

  void _cancelScheduled() {
    _scheduled?.cancel();
    _scheduled = null;
  }

  void _commit(LudoStep step) {
    _state = step.state;
    if (step.state.isFinished) {
      records.recordMatch(matchId: _matchId!, config: config, state: step.state);
      store.clear();
    } else {
      _persist();
    }
  }

  void _showBanner(LudoBannerKind kind, LudoColor color, {int? place}) {
    _bannerTimer?.cancel();
    _banner = LudoBanner(++_bannerSeq, kind, color, place: place);
    _bannerTimer = Timer(pacing.banner, () {
      _banner = null;
      notifyListeners();
    });
  }

  LudoSavedMatch _snapshot() =>
      LudoSavedMatch(matchId: _matchId!, config: config, state: state, elapsed: elapsed);

  void _persist() {
    if (!hasMatch || isFinished) return;
    store.save(_snapshot());
  }

  void _teardown({required bool clearMatch}) {
    _generation++;
    _cancelScheduled();
    _bannerTimer?.cancel();
    _bannerTimer = null;
    _banner = null;
    _rolling = false;
    _animating = false;
    _paused = false;
    _heldSteps.clear();
    _clock.stop();
    if (clearMatch) {
      _state = null;
      _config = null;
      _matchId = null;
    }
  }

  @override
  void dispose() {
    _teardown(clearMatch: false);
    super.dispose();
  }
}

///What the launcher shows about a suspended match
class ResumableSummary {
  final int players;
  final LudoMode mode;
  final List<LudoColor> colors;
  const ResumableSummary(this.players, this.mode, this.colors);
}
