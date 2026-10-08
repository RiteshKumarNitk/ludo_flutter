///Plain data shared by the Ludo engine, controller and UI.
///No Flutter imports: everything here is serializable game data.
library;

///The four seat colors, declared in clockwise turn order around the board
///(green top-left, yellow top-right, blue bottom-right, red bottom-left).
enum LudoColor {
  green,
  yellow,
  blue,
  red;

  String get label => '${name[0].toUpperCase()}${name.substring(1)}';
}

enum LudoMode { vsComputer, passAndPlay }

///Bot strength. Each level is a genuinely different decision policy,
///see `LudoBot`.
enum BotDifficulty { easy, medium, hard }

///One seat at the table
class LudoSeat {
  final LudoColor color;
  final String name;
  final bool isBot;

  const LudoSeat({required this.color, required this.name, this.isBot = false});

  Map<String, dynamic> toJson() => {'color': color.name, 'name': name, 'isBot': isBot};

  factory LudoSeat.fromJson(Map<String, dynamic> json) => LudoSeat(
        color: LudoColor.values.byName(json['color'] as String),
        name: json['name'] as String,
        isBot: json['isBot'] as bool? ?? false,
      );
}

///Who is playing a match. The rules themselves are fixed and not part of
///the configuration.
class LudoMatchConfig {
  final LudoMode mode;
  final BotDifficulty difficulty;

  ///Seats in turn order
  final List<LudoSeat> seats;

  const LudoMatchConfig({required this.mode, required this.difficulty, required this.seats});

  bool get hasBots => seats.any((s) => s.isBot);

  int get humanCount => seats.where((s) => !s.isBot).length;

  ///Seat colors per player count, in turn order. The first seat sits
  ///bottom-left (red), closest to the player's thumb, and two player
  ///matches face each other diagonally.
  static List<LudoColor> colorsFor(int playerCount) {
    switch (playerCount.clamp(2, 4)) {
      case 2:
        return const [LudoColor.red, LudoColor.yellow];
      case 3:
        return const [LudoColor.red, LudoColor.green, LudoColor.yellow];
      default:
        return const [LudoColor.red, LudoColor.green, LudoColor.yellow, LudoColor.blue];
    }
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'difficulty': difficulty.name,
        'seats': [for (final s in seats) s.toJson()],
      };

  factory LudoMatchConfig.fromJson(Map<String, dynamic> json) => LudoMatchConfig(
        mode: LudoMode.values.byName(json['mode'] as String),
        difficulty: BotDifficulty.values.byName(json['difficulty'] as String),
        seats: [
          for (final s in json['seats'] as List) LudoSeat.fromJson(Map<String, dynamic>.from(s as Map)),
        ],
      );
}

///Identifies one pawn on the board
typedef PawnRef = ({LudoColor color, int index});
