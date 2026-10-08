import '../engine/board_geometry.dart';
import 'ludo_models.dart';

///What the current seat is expected to do next
enum LudoPhase {
  ///Waiting for the current seat to roll
  roll,

  ///A roll was made and the seat must pick one of its legal moves
  move,

  ///The turn is over (no move, three sixes or a plain move) and passes on
  ///with `LudoEngine.endTurn`
  turnOver,

  ///The match is decided
  finished,
}

///Per-seat counters for the current match
class SeatStats {
  final int captures;
  final int captured;
  final int sixes;
  final int turns;

  const SeatStats({this.captures = 0, this.captured = 0, this.sixes = 0, this.turns = 0});

  SeatStats copyWith({int? captures, int? captured, int? sixes, int? turns}) => SeatStats(
        captures: captures ?? this.captures,
        captured: captured ?? this.captured,
        sixes: sixes ?? this.sixes,
        turns: turns ?? this.turns,
      );

  Map<String, dynamic> toJson() => {'captures': captures, 'captured': captured, 'sixes': sixes, 'turns': turns};

  factory SeatStats.fromJson(Map<String, dynamic> json) => SeatStats(
        captures: (json['captures'] as num?)?.toInt() ?? 0,
        captured: (json['captured'] as num?)?.toInt() ?? 0,
        sixes: (json['sixes'] as num?)?.toInt() ?? 0,
        turns: (json['turns'] as num?)?.toInt() ?? 0,
      );
}

///Immutable snapshot of a Ludo match. Produced and consumed by `LudoEngine`.
class LudoState {
  ///Seats in turn order
  final List<LudoSeat> seats;

  ///Step of every pawn per color (-1 base, 0-55 route, 56 home)
  final Map<LudoColor, List<int>> steps;

  ///Move number at which each pawn arrived on its current cell. Decides
  ///which pawn is on top of a shared cell (the most recent arrival).
  final Map<LudoColor, List<int>> arrivals;

  ///Index into [seats] of the seat whose turn it is
  final int turn;

  ///Last rolled value in this turn, null before the seat has rolled
  final int? dice;

  final LudoPhase phase;

  ///Consecutive sixes rolled in the current turn
  final int sixStreak;

  ///Colors in the order they finished. Complete once [phase] is finished.
  final List<LudoColor> ranking;

  final Map<LudoColor, SeatStats> stats;

  ///Number of pawn moves made so far
  final int moveCount;

  const LudoState({
    required this.seats,
    required this.steps,
    required this.arrivals,
    required this.turn,
    required this.dice,
    required this.phase,
    required this.sixStreak,
    required this.ranking,
    required this.stats,
    required this.moveCount,
  });

  LudoSeat get currentSeat => seats[turn];

  LudoColor get currentColor => seats[turn].color;

  bool get isFinished => phase == LudoPhase.finished;

  LudoColor? get winner => ranking.isEmpty ? null : ranking.first;

  LudoSeat seatOf(LudoColor color) => seats.firstWhere((s) => s.color == color);

  List<int> stepsOf(LudoColor color) => steps[color]!;

  int pawnsHome(LudoColor color) => steps[color]!.where((s) => s == BoardGeometry.homeStep).length;

  ///1-based finishing place, or null while the color is still playing
  int? placeOf(LudoColor color) {
    final i = ranking.indexOf(color);
    return i < 0 ? null : i + 1;
  }

  LudoState copyWith({
    Map<LudoColor, List<int>>? steps,
    Map<LudoColor, List<int>>? arrivals,
    int? turn,
    int? Function()? dice,
    LudoPhase? phase,
    int? sixStreak,
    List<LudoColor>? ranking,
    Map<LudoColor, SeatStats>? stats,
    int? moveCount,
  }) =>
      LudoState(
        seats: seats,
        steps: steps ?? this.steps,
        arrivals: arrivals ?? this.arrivals,
        turn: turn ?? this.turn,
        dice: dice != null ? dice() : this.dice,
        phase: phase ?? this.phase,
        sixStreak: sixStreak ?? this.sixStreak,
        ranking: ranking ?? this.ranking,
        stats: stats ?? this.stats,
        moveCount: moveCount ?? this.moveCount,
      );

  Map<String, dynamic> toJson() => {
        'seats': [for (final s in seats) s.toJson()],
        'steps': {for (final e in steps.entries) e.key.name: e.value},
        'arrivals': {for (final e in arrivals.entries) e.key.name: e.value},
        'turn': turn,
        'dice': dice,
        'phase': phase.name,
        'sixStreak': sixStreak,
        'ranking': [for (final c in ranking) c.name],
        'stats': {for (final e in stats.entries) e.key.name: e.value.toJson()},
        'moveCount': moveCount,
      };

  factory LudoState.fromJson(Map<String, dynamic> json) {
    final seats = [
      for (final s in json['seats'] as List) LudoSeat.fromJson(Map<String, dynamic>.from(s as Map)),
    ];
    Map<LudoColor, List<int>> readLists(String key) {
      final raw = Map<String, dynamic>.from(json[key] as Map);
      return Map.unmodifiable({
        for (final seat in seats)
          seat.color: List<int>.unmodifiable((raw[seat.color.name] as List).map((e) => (e as num).toInt())),
      });
    }

    final rawStats = Map<String, dynamic>.from(json['stats'] as Map);
    final steps = readLists('steps');
    for (final list in steps.values) {
      if (list.length != BoardGeometry.pawnsPerPlayer ||
          list.any((s) => s < -1 || s > BoardGeometry.homeStep)) {
        throw const FormatException('Invalid pawn steps');
      }
    }
    final turn = (json['turn'] as num).toInt();
    if (turn < 0 || turn >= seats.length) throw const FormatException('Invalid turn');
    return LudoState(
      seats: List.unmodifiable(seats),
      steps: steps,
      arrivals: readLists('arrivals'),
      turn: turn,
      dice: (json['dice'] as num?)?.toInt(),
      phase: LudoPhase.values.byName(json['phase'] as String),
      sixStreak: (json['sixStreak'] as num?)?.toInt() ?? 0,
      ranking: List.unmodifiable([for (final c in json['ranking'] as List) LudoColor.values.byName(c as String)]),
      stats: Map.unmodifiable({
        for (final seat in seats)
          seat.color: SeatStats.fromJson(Map<String, dynamic>.from((rawStats[seat.color.name] ?? const {}) as Map)),
      }),
      moveCount: (json['moveCount'] as num?)?.toInt() ?? 0,
    );
  }
}
