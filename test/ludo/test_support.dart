import 'package:ludo_flutter/games/ludo/engine/ludo_engine.dart';
import 'package:ludo_flutter/games/ludo/models/ludo_models.dart';
import 'package:ludo_flutter/games/ludo/models/ludo_state.dart';

///A two seat config: red (human) vs yellow (human or bot)
LudoMatchConfig duel({bool yellowIsBot = true, BotDifficulty difficulty = BotDifficulty.medium}) => LudoMatchConfig(
      mode: yellowIsBot ? LudoMode.vsComputer : LudoMode.passAndPlay,
      difficulty: difficulty,
      seats: [
        const LudoSeat(color: LudoColor.red, name: 'You'),
        LudoSeat(color: LudoColor.yellow, name: 'Yellow', isBot: yellowIsBot),
      ],
    );

///Plays the final move of a match so [winner] finishes first
LudoState finishedState(LudoMatchConfig config, LudoColor winner, {int winnerCaptured = 0}) {
  final start = LudoEngine.start(config.seats);
  final turn = config.seats.indexWhere((s) => s.color == winner);
  final rigged = start.copyWith(
    steps: {
      for (final s in config.seats) s.color: s.color == winner ? const [56, 56, 56, 53] : const [-1, -1, -1, -1],
    },
    turn: turn,
    stats: {
      for (final s in config.seats)
        s.color: SeatStats(turns: 10, captured: s.color == winner ? winnerCaptured : 0, sixes: 2, captures: 1),
    },
  );
  final done = LudoEngine.move(LudoEngine.roll(rigged, 3).state, 3).state;
  assert(done.isFinished);
  return done;
}

///Let zero-length timers and futures run
Future<void> settle([int rounds = 20]) async {
  for (int i = 0; i < rounds; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
