import 'package:flutter/material.dart';
import 'package:ludo_flutter/board_theme.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/l10n/app_strings.dart';
import 'package:ludo_flutter/ludo_provider.dart';
import 'package:ludo_flutter/settings_provider.dart';
import 'package:ludo_flutter/widgets/board_painter.dart';
import 'package:ludo_flutter/widgets/pawn_widget.dart';
import 'package:provider/provider.dart';

import '../ludo_player.dart';

///A stack of pawns occupying one board cell
class _CellOccupants {
  final double x;
  final double y;
  final List<Pawn> pawns = [];
  _CellOccupants(this.x, this.y);
}

///Widget for the board
class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  ///Return board size
  double ludoBoard(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final available = size.width < size.height ? size.width : size.height;
    return available.clamp(280.0, 640.0);
  }

  ///Count box size
  double boxStepSize(BuildContext context) {
    return ludoBoard(context) / 15;
  }

  @override
  Widget build(BuildContext context) {
    final double boardSize = ludoBoard(context);

    ///Board skin chosen on the settings screen
    final BoardTheme theme = BoardTheme.of(context.watch<SettingsProvider>().boardTheme);
    return Container(
      margin: const EdgeInsets.all(10),
      clipBehavior: Clip.antiAlias,
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        color: theme.background,
      ),
      child: Consumer<LudoProvider>(
        builder: (context, value, child) {
          //We use `Stack` to put all widgets on top of each other
          //so we make some logic to change the order of players to make sure
          //the player on top is the one who is playing
          List<LudoPlayer> players = List.from(value.players);

          //Sort with the current player last so their pawns render on top.
          //A consistent comparator: 0 for everyone else, 1 for the current player.
          players.sort((a, b) {
            final int aTop = a.type == value.currentPlayer.type ? 1 : 0;
            final int bTop = b.type == value.currentPlayer.type ? 1 : 0;
            return aTop.compareTo(bTop);
          });

          ///Group every pawn that is on the board by its cell
          final Map<String, _CellOccupants> cells = {};
          final List<Widget> playersPawn = [];

          for (final player in players) {
            for (final pawn in player.pawns) {
              final bool highlight = player.highlighted.contains(pawn.index);
              if (pawn.step > -1) {
                final List<double> coordinates = player.path[pawn.step];
                final String key = '${coordinates[0]}_${coordinates[1]}';
                final cell = cells.putIfAbsent(
                    key, () => _CellOccupants(coordinates[0], coordinates[1]));
                cell.pawns.add(pawn);
              } else {
                ///Pawn sits in its base slot
                playersPawn.add(
                  AnimatedPositioned(
                    key: ValueKey("${pawn.type.name}_${pawn.index}"),
                    left: LudoPath.stepBox(boardSize, player.homePath[pawn.index][0]),
                    top: LudoPath.stepBox(boardSize, player.homePath[pawn.index][1]),
                    width: boxStepSize(context),
                    height: boxStepSize(context),
                    duration: const Duration(milliseconds: 200),
                    child: PawnWidget(pawn.index, pawn.type,
                        step: pawn.step, highlight: highlight),
                  ),
                );
              }
            }
          }

          ///Render every occupied board cell
          for (final cell in cells.values) {
            if (cell.pawns.length == 1) {
              // This is for 1 pawn in 1 box
              final pawn = cell.pawns.first;
              playersPawn.add(AnimatedPositioned(
                key: ValueKey("${pawn.type.name}_${pawn.index}"),
                duration: const Duration(milliseconds: 200),
                left: LudoPath.stepBox(boardSize, cell.x),
                top: LudoPath.stepBox(boardSize, cell.y),
                width: boxStepSize(context),
                height: boxStepSize(context),
                child: PawnWidget(pawn.index, pawn.type,
                    step: pawn.step, highlight: _isHighlighted(value, pawn)),
              ));
            } else {
              // Several pawns share one cell: scale them down into a 2x2 grid
              // and show a count badge (instead of the old 3px faked offset)
              playersPawn.add(_StackedPawns(
                key: ValueKey('stack_${cell.x}_${cell.y}'),
                cell: cell,
                boardSize: boardSize,
                boxSize: boxStepSize(context),
                value: value,
              ));
            }
          }

          return Center(
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                ///The painted board surface sits under every pawn
                CustomPaint(
                  painter: BoardPainter(
                    theme: theme,
                    activePlayers: value.players.map((p) => p.type).toSet(),
                  ),
                ),
                ...playersPawn,
                ...winners(context, value.winners),
                turnIndicator(context, value.currentPlayer.type, value.currentPlayer.color,
                    value.gameState, value.currentPlayer.name),
              ],
            ),
          );
        },
      ),
    );
  }

  static bool _isHighlighted(LudoProvider value, Pawn pawn) {
    final player = value.players.firstWhere((p) => p.type == pawn.type);
    return player.highlighted.contains(pawn.index);
  }

  ///This is for the turn indicator widget
  Widget turnIndicator(
      BuildContext context, LudoPlayerType turn, Color color, LudoGameState stage, String name) {
    final s = AppStrings.of(context);
    //0 is left, 1 is right
    int x = 0;
    //0 is top, 1 is bottom
    int y = 0;

    switch (turn) {
      case LudoPlayerType.green:
        x = 0;
        y = 0;
        break;
      case LudoPlayerType.yellow:
        x = 1;
        y = 0;
        break;
      case LudoPlayerType.blue:
        x = 1;
        y = 1;
        break;
      case LudoPlayerType.red:
        x = 0;
        y = 1;
        break;
    }
    String stageText = s.turnRollDice;
    switch (stage) {
      case LudoGameState.throwDice:
        stageText = s.turnRollDice;
        break;
      case LudoGameState.moving:
        stageText = s.hintPawnMoving;
        break;
      case LudoGameState.pickPawn:
        stageText = s.turnPickPawn;
        break;
      case LudoGameState.finish:
        stageText = s.hintGameOver;
        break;
    }
    final double boardSize = ludoBoard(context);
    ///Scale the hint text with the board so it stays readable on big screens
    final double baseSize = (boardSize * 0.026).clamp(9.0, 15.0);
    final double titleSize = (boardSize * 0.034).clamp(12.0, 20.0);
    return Positioned(
      top: y == 0 ? 0 : null,
      left: x == 0 ? 0 : null,
      right: x == 1 ? 0 : null,
      bottom: y == 1 ? 0 : null,
      width: boardSize * .4,
      height: boardSize * .4,
      child: IgnorePointer(
        child: Padding(
          padding: EdgeInsets.all(boxStepSize(context)),
          child: Container(
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(style: TextStyle(fontSize: baseSize, color: color), children: [
                  TextSpan(
                      text: "${s.turnAnnouncement(name)}\n",
                      style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold)),
                  TextSpan(text: stageText, style: const TextStyle(color: Colors.black)),
                ]),
              )),
        ),
      ),
    );
  }

  ///This is for the winner widget
  List<Widget> winners(BuildContext context, List<LudoPlayerType> winners) => List.generate(
        winners.length,
        (index) {
          Widget crownImage;
          if (index == 0) {
            crownImage = Image.asset("assets/images/crown/1st.png", fit: BoxFit.cover);
          } else if (index == 1) {
            crownImage = Image.asset("assets/images/crown/2nd.png", fit: BoxFit.cover);
          } else if (index == 2) {
            crownImage = Image.asset("assets/images/crown/3rd.png", fit: BoxFit.cover);
          } else {
            return Container();
          }

          //0 is left, 1 is right
          int x = 0;
          //0 is top, 1 is bottom
          int y = 0;

          switch (winners[index]) {
            case LudoPlayerType.green:
              x = 0;
              y = 0;
              break;
            case LudoPlayerType.yellow:
              x = 1;
              y = 0;
              break;
            case LudoPlayerType.blue:
              x = 1;
              y = 1;
              break;
            case LudoPlayerType.red:
              x = 0;
              y = 1;
              break;
          }
          return Positioned(
            top: y == 0 ? 0 : null,
            left: x == 0 ? 0 : null,
            right: x == 1 ? 0 : null,
            bottom: y == 1 ? 0 : null,
            width: ludoBoard(context) * .4,
            height: ludoBoard(context) * .4,
            child: Padding(
              padding: EdgeInsets.all(boxStepSize(context)),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
                child: crownImage,
              ),
            ),
          );
        },
      );
}

///Renders pawns that share one cell: up to four pawns arranged in a 2x2 grid,
///scaled to fit, plus a count badge when more than one pawn is present.
class _StackedPawns extends StatelessWidget {
  final _CellOccupants cell;
  final double boardSize;
  final double boxSize;
  final LudoProvider value;

  const _StackedPawns({
    super.key,
    required this.cell,
    required this.boardSize,
    required this.boxSize,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final double left = LudoPath.stepBox(boardSize, cell.x);
    final double top = LudoPath.stepBox(boardSize, cell.y);
    const double gap = 1.0;
    final double half = (boxSize - gap) / 2;

    return Positioned(
      left: left,
      top: top,
      width: boxSize,
      height: boxSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < cell.pawns.length && i < 4; i++)
            Positioned(
              left: (i % 2) * (half + gap),
              top: (i ~/ 2) * (half + gap),
              width: half,
              height: half,
              child: PawnWidget(
                cell.pawns[i].index,
                cell.pawns[i].type,
                step: cell.pawns[i].step,
                highlight: BoardWidget._isHighlighted(value, cell.pawns[i]),
              ),
            ),
          if (cell.pawns.length > 1)
            Positioned(
              right: -boxSize * 0.14,
              top: -boxSize * 0.14,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: boxSize * 0.07, vertical: boxSize * 0.02),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(boxSize),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  'x${cell.pawns.length}',
                  style: TextStyle(
                    fontSize: (boxSize * 0.22).clamp(7.0, 12.0),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
