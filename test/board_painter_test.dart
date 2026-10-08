import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_flutter/board_theme.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/widgets/board_painter.dart';

///Paint one 600x600 board (40 px per grid cell) into a raster image
Future<ui.Image> renderBoard(BoardThemeType type, Set<LudoPlayerType> active) async {
  const size = Size.square(600);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  BoardPainter(theme: BoardTheme.of(type), activePlayers: active).paint(canvas, size);
  return recorder.endRecording().toImage(600, 600);
}

///Color at the center of grid cell ([col], [row]), both 0..14
Future<Color> cellPixel(ui.Image image, int col, int row) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final cell = image.width / 15;
  final x = ((col + 0.5) * cell).round();
  final y = ((row + 0.5) * cell).round();
  final offset = (y * image.width + x) * 4;
  return Color.fromARGB(
    data!.getUint8(offset + 3),
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
  );
}

///Whether [a] and [b] differ by at most [tolerance] on every channel
bool closeTo(Color a, Color b, {int tolerance = 16}) =>
    ((a.r - b.r).abs() * 255) <= tolerance &&
    ((a.g - b.g).abs() * 255) <= tolerance &&
    ((a.b - b.b).abs() * 255) <= tolerance;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the classic board paints quadrants, yard, track, stars and pinwheel', () async {
    final theme = BoardTheme.of(BoardThemeType.classic);
    final img = await renderBoard(BoardThemeType.classic, LudoPlayerType.values.toSet());

    expect(closeTo(await cellPixel(img, 0, 0), theme.green), isTrue, reason: 'green quadrant');
    expect(closeTo(await cellPixel(img, 14, 14), theme.blue), isTrue, reason: 'blue quadrant');
    expect(closeTo(await cellPixel(img, 3, 3), theme.yardFill), isTrue, reason: 'inner yard');
    expect(closeTo(await cellPixel(img, 2, 6), theme.trackFill), isTrue, reason: 'plain track cell');
    expect(
      closeTo(await cellPixel(img, 6, 2), theme.trackFill),
      isFalse,
      reason: 'star marker drawn on the safe cell',
    );
    expect(closeTo(await cellPixel(img, 6, 7), theme.green), isTrue, reason: 'west pinwheel');
    expect(closeTo(await cellPixel(img, 7, 6), theme.yellow), isTrue, reason: 'north pinwheel');
    expect(closeTo(await cellPixel(img, 8, 7), theme.blue), isTrue, reason: 'east pinwheel');
    expect(closeTo(await cellPixel(img, 7, 8), theme.red), isTrue, reason: 'south pinwheel');
    img.dispose();
  });

  test('inactive corners are dimmed while seated corners keep their color', () async {
    final theme = BoardTheme.of(BoardThemeType.classic);
    final full = await renderBoard(BoardThemeType.classic, LudoPlayerType.values.toSet());
    final duel = await renderBoard(BoardThemeType.classic, {
      LudoPlayerType.green,
      LudoPlayerType.blue,
    });

    ///Yellow and red sit out in a green vs blue match
    expect(closeTo(await cellPixel(duel, 14, 0), theme.yellow), isFalse, reason: 'yellow dimmed');
    expect(
      closeTo(await cellPixel(duel, 14, 0), await cellPixel(full, 14, 0), tolerance: 4),
      isFalse,
      reason: 'dim overlay visibly changes the corner',
    );

    ///The two seats in play keep their full color
    expect(
      closeTo(await cellPixel(duel, 0, 0), await cellPixel(full, 0, 0), tolerance: 4),
      isTrue,
      reason: 'green corner untouched',
    );
    expect(
      closeTo(await cellPixel(duel, 14, 14), await cellPixel(full, 14, 14), tolerance: 4),
      isTrue,
      reason: 'blue corner untouched',
    );
    full.dispose();
    duel.dispose();
  });

  test('switching the theme repaints the board with a new palette', () async {
    final players = LudoPlayerType.values.toSet();
    final classic = await renderBoard(BoardThemeType.classic, players);
    final midnight = await renderBoard(BoardThemeType.midnight, players);
    final pastel = await renderBoard(BoardThemeType.pastel, players);

    ///Midnight swaps the white track for a dark one
    expect(
      closeTo(await cellPixel(midnight, 2, 6), await cellPixel(classic, 2, 6)),
      isFalse,
      reason: 'midnight track is dark',
    );

    ///The page background between the arms changes per theme too
    expect(
      closeTo(await cellPixel(midnight, 0, 6), await cellPixel(classic, 0, 6)),
      isFalse,
      reason: 'midnight background is dark',
    );
    expect(
      closeTo(await cellPixel(pastel, 0, 6), await cellPixel(midnight, 0, 6)),
      isFalse,
      reason: 'pastel background is light',
    );

    ///Quadrant colors are re-tinted per theme
    expect(
      closeTo(await cellPixel(midnight, 0, 0), await cellPixel(pastel, 0, 0)),
      isFalse,
      reason: 'green quadrant differs between themes',
    );
    classic.dispose();
    midnight.dispose();
    pastel.dispose();
  });
}
