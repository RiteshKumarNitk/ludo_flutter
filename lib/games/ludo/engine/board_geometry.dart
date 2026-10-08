import '../models/ludo_models.dart';

///A cell of the 15x15 board grid
typedef Cell = ({int x, int y});

///Static geometry of the Ludo board: every color's route and the safe cells.
///
///Each route has 57 steps: 0-50 run around the shared track, 51-55 are the
///color's private home column and 56 is the final home cell. A pawn in its
///base has step -1.
class BoardGeometry {
  const BoardGeometry._();

  static const int pawnsPerPlayer = 4;
  static const int lastTrackStep = 50;
  static const int homeStep = 56;

  ///Green's route. The other colors are this route rotated 90° clockwise
  ///around the board center, once per seat.
  static const List<List<int>> _greenRoute = [
    [1, 6], [2, 6], [3, 6], [4, 6], [5, 6], //
    [6, 5], [6, 4], [6, 3], [6, 2], [6, 1], [6, 0],
    [7, 0],
    [8, 0], [8, 1], [8, 2], [8, 3], [8, 4], [8, 5],
    [9, 6], [10, 6], [11, 6], [12, 6], [13, 6], [14, 6],
    [14, 7],
    [14, 8], [13, 8], [12, 8], [11, 8], [10, 8], [9, 8],
    [8, 9], [8, 10], [8, 11], [8, 12], [8, 13], [8, 14],
    [7, 14],
    [6, 14], [6, 13], [6, 12], [6, 11], [6, 10], [6, 9],
    [5, 8], [4, 8], [3, 8], [2, 8], [1, 8], [0, 8],
    [0, 7],
    //Home column and final home cell
    [1, 7], [2, 7], [3, 7], [4, 7], [5, 7], [6, 7],
  ];

  ///Track steps (on green's route) of the eight safe cells: every color's
  ///start cell (0, 13, 26, 39) and the four star cells (8, 21, 34, 47).
  static const List<int> _safeTrackSteps = [0, 8, 13, 21, 26, 34, 39, 47];

  static final Map<LudoColor, List<Cell>> _routes = {
    for (final color in LudoColor.values) color: _buildRoute(color),
  };

  static final Set<Cell> safeCells = {for (final s in _safeTrackSteps) _routes[LudoColor.green]![s]};

  static final Set<Cell> startCells = {for (final c in LudoColor.values) _routes[c]!.first};

  static List<Cell> _buildRoute(LudoColor color) {
    final int turns = color.index; //green 0, yellow 1, blue 2, red 3
    return List.unmodifiable([
      for (final p in _greenRoute) _rotate((x: p[0], y: p[1]), turns),
    ]);
  }

  static Cell _rotate(Cell cell, int quarterTurns) {
    Cell c = cell;
    for (int i = 0; i < quarterTurns; i++) {
      c = (x: 14 - c.y, y: c.x);
    }
    return c;
  }

  static List<Cell> routeOf(LudoColor color) => _routes[color]!;

  ///Board cell of a pawn at [step], or null while it is in its base
  static Cell? cellOf(LudoColor color, int step) => step < 0 ? null : _routes[color]![step];

  static bool isSafe(Cell cell) => safeCells.contains(cell);

  ///Top-left cell of each color's 6x6 base quadrant
  static Cell quadrantOrigin(LudoColor color) {
    switch (color) {
      case LudoColor.green:
        return (x: 0, y: 0);
      case LudoColor.yellow:
        return (x: 9, y: 0);
      case LudoColor.blue:
        return (x: 9, y: 9);
      case LudoColor.red:
        return (x: 0, y: 9);
    }
  }

  ///Base slot of [pawn], as a top-left offset in cell units
  static ({double x, double y}) baseSlot(LudoColor color, int pawn) {
    const slots = [(1.5, 1.5), (3.5, 1.5), (1.5, 3.5), (3.5, 3.5)];
    final origin = quadrantOrigin(color);
    final (dx, dy) = slots[pawn];
    return (x: origin.x + dx, y: origin.y + dy);
  }
}
