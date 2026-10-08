import 'constants.dart';

///CPU decision style, chosen per match (seeded from settings)
enum CpuDifficulty {
  ///Random legal pawn
  easy,

  ///Classic heuristic: prefer the pawn closest to the finish
  medium,

  ///Evaluates captures, safety, blocks and danger
  hard,
}

///Setup for a single player slot in a match
class PlayerSetup {
  final LudoPlayerType color;
  final String name;
  final bool isCpu;

  const PlayerSetup({required this.color, required this.name, this.isCpu = false});

  PlayerSetup copyWith({String? name, bool? isCpu}) => PlayerSetup(
        color: color,
        name: name ?? this.name,
        isCpu: isCpu ?? this.isCpu,
      );

  Map<String, dynamic> toJson() => {'color': color.name, 'name': name, 'isCpu': isCpu};

  static PlayerSetup fromJson(Map<String, dynamic> json) => PlayerSetup(
        color: LudoPlayerType.values.byName(json['color'] as String),
        name: json['name'] as String,
        isCpu: json['isCpu'] as bool? ?? false,
      );
}

///Configuration of a match, created on the setup screen and reused on rematch
class GameConfig {
  ///Players in turn order
  final List<PlayerSetup> players;

  ///Classic rule: rolling a 6 grants another roll
  final bool extraRollOnSix;

  ///Capturing an opponent pawn grants another roll (classic rule)
  final bool captureGrantsRoll;

  ///Three consecutive 6s forfeit the turn instead of granting a third roll
  final bool threeSixesForfeit;

  ///Pawns need an exact roll to reach the final cell.
  ///When off, an overshooting roll clamps to the final cell.
  final bool exactFinish;

  ///Two or more pawns of the same color on one cell form a block that
  ///opponents can neither land on nor pass through
  final bool blocking;

  ///Decision style used by CPU seats
  final CpuDifficulty cpuDifficulty;

  const GameConfig({
    required this.players,
    this.extraRollOnSix = true,
    this.captureGrantsRoll = true,
    this.threeSixesForfeit = false,
    this.exactFinish = true,
    this.blocking = false,
    this.cpuDifficulty = CpuDifficulty.medium,
  });

  static String defaultName(LudoPlayerType type) =>
      type.name[0].toUpperCase() + type.name.substring(1);

  ///Color presets per player count, in turn order
  static List<LudoPlayerType> colorsFor(int playerCount) {
    switch (playerCount.clamp(2, 4)) {
      case 2:
        return [LudoPlayerType.green, LudoPlayerType.blue];
      case 3:
        return [LudoPlayerType.green, LudoPlayerType.yellow, LudoPlayerType.blue];
      default:
        return LudoPlayerType.values;
    }
  }

  factory GameConfig.defaults([int playerCount = 4]) => GameConfig(
        players: [
          for (final color in colorsFor(playerCount))
            PlayerSetup(color: color, name: defaultName(color)),
        ],
      );

  GameConfig copyWith({
    List<PlayerSetup>? players,
    bool? extraRollOnSix,
    bool? captureGrantsRoll,
    bool? threeSixesForfeit,
    bool? exactFinish,
    bool? blocking,
    CpuDifficulty? cpuDifficulty,
  }) =>
      GameConfig(
        players: players ?? this.players,
        extraRollOnSix: extraRollOnSix ?? this.extraRollOnSix,
        captureGrantsRoll: captureGrantsRoll ?? this.captureGrantsRoll,
        threeSixesForfeit: threeSixesForfeit ?? this.threeSixesForfeit,
        exactFinish: exactFinish ?? this.exactFinish,
        blocking: blocking ?? this.blocking,
        cpuDifficulty: cpuDifficulty ?? this.cpuDifficulty,
      );

  Map<String, dynamic> toJson() => {
        'players': [for (final p in players) p.toJson()],
        'extraRollOnSix': extraRollOnSix,
        'captureGrantsRoll': captureGrantsRoll,
        'threeSixesForfeit': threeSixesForfeit,
        'exactFinish': exactFinish,
        'blocking': blocking,
        'cpuDifficulty': cpuDifficulty.name,
      };

  factory GameConfig.fromJson(Map<String, dynamic> json) => GameConfig(
        players: [
          for (final p in (json['players'] as List))
            PlayerSetup.fromJson(Map<String, dynamic>.from(p as Map)),
        ],
        extraRollOnSix: json['extraRollOnSix'] as bool? ?? true,
        captureGrantsRoll: json['captureGrantsRoll'] as bool? ?? true,
        threeSixesForfeit: json['threeSixesForfeit'] as bool? ?? false,
        exactFinish: json['exactFinish'] as bool? ?? true,
        blocking: json['blocking'] as bool? ?? false,
        cpuDifficulty: CpuDifficulty.values.byName(
            (json['cpuDifficulty'] as String?) ?? CpuDifficulty.medium.name),
      );
}
