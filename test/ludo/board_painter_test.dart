import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_flutter/games/ludo/engine/board_geometry.dart';
import 'package:ludo_flutter/games/ludo/models/ludo_models.dart';
import 'package:ludo_flutter/games/ludo/widgets/board_painter.dart';
import 'package:ludo_flutter/games/ludo/widgets/board_theme.dart';

///Paint a 600x600 board (40 px per cell) into an image
Future<ui.Image> render(BoardThemeType type, Set<LudoColor> active) {
  final recorder = ui.PictureRecorder();
  BoardPainter(theme: BoardTheme.of(type), activeColors: active).paint(Canvas(recorder), const Size.square(600));
  return recorder.endRecording().toImage(600, 600);
}

Future<Color> pixel(ui.Image image, num x, num y) async {
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final offset = ((y * 40).round() * image.width + (x * 40).round()) * 4;
  return Color.fromARGB(data.getUint8(offset + 3), data.getUint8(offset), data.getUint8(offset + 1), data.getUint8(offset + 2));
}

Future<Color> cellCenter(ui.Image image, int col, int row) => pixel(image, col + 0.5, row + 0.5);

bool close(Color a, Color b, {int tolerance = 16}) =>
    ((a.r - b.r).abs() * 255) <= tolerance && ((a.g - b.g).abs() * 255) <= tolerance && ((a.b - b.b).abs() * 255) <= tolerance;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final all = LudoColor.values.toSet();

  test('quadrants, track and center triangles use the theme colors', () async {
    final theme = BoardTheme.of(BoardThemeType.classic);
    final img = await render(BoardThemeType.classic, all);
    expect(close(await cellCenter(img, 0, 0), theme.green), isTrue);
    expect(close(await cellCenter(img, 14, 14), theme.blue), isTrue);
    expect(close(await cellCenter(img, 3, 3), theme.yardFill), isTrue);
    expect(close(await cellCenter(img, 2, 6), theme.trackFill), isTrue);
    expect(close(await cellCenter(img, 6, 7), theme.green), isTrue);
    expect(close(await cellCenter(img, 7, 6), theme.yellow), isTrue);
    expect(close(await cellCenter(img, 8, 7), theme.blue), isTrue);
    expect(close(await cellCenter(img, 7, 8), theme.red), isTrue);
    img.dispose();
  });

  test('every one of the 8 safe cells carries a star marker', () async {
    final theme = BoardTheme.of(BoardThemeType.classic);
    final img = await render(BoardThemeType.classic, all);
    for (final cell in BoardGeometry.safeCells) {
      final isStart = BoardGeometry.startCells.contains(cell);
      final owner = LudoColor.values.firstWhere((c) => BoardGeometry.routeOf(c).first == cell,
          orElse: () => LudoColor.green);
      final base = isStart ? theme.colorOf(owner) : theme.trackFill;
      expect(close(await cellCenter(img, cell.x, cell.y), base), isFalse, reason: 'star on $cell');
      //The cell corner shows the plain fill, so the marker is a star, not a recolor
      expect(close(await pixel(img, cell.x + 0.12, cell.y + 0.12), base), isTrue, reason: 'fill on $cell');
    }
    img.dispose();
  });

  test('unused corners are dimmed, seated corners keep their color', () async {
    final full = await render(BoardThemeType.classic, all);
    final duel = await render(BoardThemeType.classic, {LudoColor.red, LudoColor.yellow});
    expect(close(await cellCenter(duel, 0, 0), await cellCenter(full, 0, 0), tolerance: 4), isFalse, reason: 'green dimmed');
    expect(close(await cellCenter(duel, 14, 14), await cellCenter(full, 14, 14), tolerance: 4), isFalse, reason: 'blue dimmed');
    expect(close(await cellCenter(duel, 14, 0), await cellCenter(full, 14, 0), tolerance: 4), isTrue, reason: 'yellow kept');
    expect(close(await cellCenter(duel, 0, 14), await cellCenter(full, 0, 14), tolerance: 4), isTrue, reason: 'red kept');
    full.dispose();
    duel.dispose();
  });

  test('themes repaint with their own palette', () async {
    final classic = await render(BoardThemeType.classic, all);
    final midnight = await render(BoardThemeType.midnight, all);
    final pastel = await render(BoardThemeType.pastel, all);
    expect(close(await cellCenter(midnight, 2, 6), await cellCenter(classic, 2, 6)), isFalse);
    expect(close(await cellCenter(midnight, 0, 0), await cellCenter(pastel, 0, 0)), isFalse);
    classic.dispose();
    midnight.dispose();
    pastel.dispose();
  });
}
