import 'package:flutter/material.dart';
import 'package:ludo_flutter/constants.dart';

///Data model for a single pawn. Pure state, no widgets — the board renders
///a `PawnWidget` from this data on every rebuild.
class Pawn {
  ///Seat index inside the player's pawn list (0-3)
  final int index;

  ///Owner color
  final LudoPlayerType type;

  ///Current cell index on the player's path, `-1` while in base
  int step;

  Pawn(this.index, this.type, {this.step = -1});

  @override
  String toString() => 'Pawn(${type.name}#$index@$step)';
}

///This is ludo player model class which contains all the information about the player
class LudoPlayer {
  ///Player type
  final LudoPlayerType type;

  ///Display name of the player
  final String name;

  ///True when the player is controlled by the computer
  final bool isCpu;

  ///Pawn's paths
  late List<List<double>> path;

  ///Home path
  late List<List<double>> homePath;

  ///Pawn state
  final List<Pawn> pawns = [];

  ///Indices of pawns the current player may pick right now
  final Set<int> highlighted = {};

  ///Player color
  late Color color;

  LudoPlayer(this.type, {String? name, this.isCpu = false})
      : name = name ?? type.name[0].toUpperCase() + type.name.substring(1) {
    for (int i = 0; i < 4; i++) {
      pawns.add(Pawn(i, type));
    }

    ///Initialize path
    switch (type) {
      case LudoPlayerType.green:
        path = LudoPath.greenPath;
        color = LudoColor.green;
        homePath = LudoPath.greenHomePath;
        break;
      case LudoPlayerType.yellow:
        path = LudoPath.yellowPath;
        color = LudoColor.yellow;
        homePath = LudoPath.yellowHomePath;
        break;
      case LudoPlayerType.blue:
        path = LudoPath.bluePath;
        color = LudoColor.blue;
        homePath = LudoPath.blueHomePath;
        break;
      case LudoPlayerType.red:
        path = LudoPath.redPath;
        color = LudoColor.red;
        homePath = LudoPath.redHomePath;
        break;
    }
  }

  ///Get how many pawns are in the home
  int get pawnInsideCount => pawns.where((element) => element.step == -1).length;

  ///Get how many pawns are outside home
  int get pawnOutsideCount => pawns.where((element) => element.step > -1).length;

  ///Pawns the current player may pick right now
  Iterable<Pawn> get movablePawns => pawns.where((p) => highlighted.contains(p.index));

  ///Move the pawn and clear its highlight (the pick already happened)
  void movePawn(int index, int step) {
    pawns[index].step = step;
    highlighted.remove(index);
  }

  ///Highlight (or unhighlight) a single pawn
  void highlightPawn(int index, [bool highlight = true]) {
    if (highlight) {
      highlighted.add(index);
    } else {
      highlighted.remove(index);
    }
  }

  ///Highlight all the pawns
  void highlightAllPawns([bool highlight = true]) {
    if (highlight) {
      highlighted.addAll(pawns.map((e) => e.index));
    } else {
      highlighted.clear();
    }
  }

  ///Highlight pawn outside `HOME`
  void highlightOutside([bool highlight = true]) {
    for (final pawn in pawns) {
      if (pawn.step != -1) highlightPawn(pawn.index, highlight);
    }
  }

  ///Restore full pawn state (used by save/resume)
  void restoreSteps(List<int> steps) {
    for (int i = 0; i < pawns.length && i < steps.length; i++) {
      pawns[i].step = steps[i];
    }
    highlighted.clear();
  }

  List<int> saveSteps() => [for (final pawn in pawns) pawn.step];
}
