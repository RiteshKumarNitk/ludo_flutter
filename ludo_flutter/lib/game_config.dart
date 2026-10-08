import 'constants.dart';

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
}

///Configuration of a match, created on the setup screen and reused on rematch
class GameConfig {
  ///Players in turn order
  final List<PlayerSetup> players;

  ///Classic rule: rolling a 6 grants another roll
  final bool extraRollOnSix;

  const GameConfig({required this.players, this.extraRollOnSix = true});

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

  GameConfig copyWith({List<PlayerSetup>? players, bool? extraRollOnSix}) => GameConfig(
        players: players ?? this.players,
        extraRollOnSix: extraRollOnSix ?? this.extraRollOnSix,
      );
}
