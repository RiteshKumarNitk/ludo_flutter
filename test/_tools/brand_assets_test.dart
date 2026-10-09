//Generates every Khelora brand asset from the same painter the app uses
//(KheloraMarkPainter), so icons, splash and in-app logo always match.
//Skipped in normal runs (see dart_test.yaml). Regenerate with:
//  flutter test test/_tools --tags brand --run-skipped
@Tags(['brand'])
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_flutter/core/branding/khelora_mark.dart';

const navy = KheloraColors.navy;

///What to draw behind the mark
enum Backdrop { none, rounded, square }

Future<ui.Image> render(int px, {Backdrop backdrop = Backdrop.none, double markScale = 0.72, bool mono = false}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = px.toDouble();
  switch (backdrop) {
    case Backdrop.rounded:
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size, size), Radius.circular(size * 0.22)),
        Paint()..color = navy,
      );
    case Backdrop.square:
      canvas.drawRect(Rect.fromLTWH(0, 0, size, size), Paint()..color = navy);
    case Backdrop.none:
      break;
  }
  final mark = size * markScale;
  canvas.translate((size - mark) / 2, (size - mark) / 2);
  KheloraMarkPainter(monochrome: mono).paint(canvas, Size.square(mark));
  return recorder.endRecording().toImage(px, px);
}

Future<void> savePng(ui.Image image, String path) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

///iOS app icons must not carry an alpha channel: write a plain RGB PNG
Future<void> saveOpaquePng(ui.Image image, String path) async {
  final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  final w = image.width, h = image.height;
  final raw = BytesBuilder();
  for (int y = 0; y < h; y++) {
    raw.addByte(0); //filter: none
    for (int x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      raw.add([rgba[i], rgba[i + 1], rgba[i + 2]]);
    }
  }
  Uint8List chunk(String type, List<int> data) {
    final body = Uint8List.fromList([...type.codeUnits, ...data]);
    return Uint8List.fromList([..._u32(data.length), ...body, ..._u32(_crc32(body))]);
  }

  final header = [..._u32(w), ..._u32(h), 8, 2, 0, 0, 0]; //8-bit RGB
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
      ...chunk('IHDR', header),
      ...chunk('IDAT', ZLibEncoder().convert(raw.toBytes())),
      ...chunk('IEND', const []),
    ]);
}

List<int> _u32(int v) => [(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF];

final List<int> _crcTable = List.generate(256, (n) {
  int c = n;
  for (int k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  int c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

Future<void> loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter';
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final f in ['roboto-black.ttf', 'roboto-medium.ttf']) {
    roboto.addFont(Future.value(ByteData.view(File('$dir/$f').readAsBytesSync().buffer)));
  }
  await roboto.load();
}

///Full logo: symbol, wordmark and tagline on a transparent background
Future<ui.Image> renderFullLogo({bool onLight = false}) async {
  const w = 1600.0, h = 560.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  KheloraMarkPainter(ringColor: onLight ? Colors.white : navy).paint(canvas, const Size.square(h));
  TextPainter text(String s, double size, FontWeight weight, Color color, {double spacing = 0}) => TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
  final word = TextPainter(
    text: TextSpan(
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 230,
        fontWeight: FontWeight.w900,
        letterSpacing: 8,
        color: onLight ? navy : Colors.white,
      ),
      children: const [
        TextSpan(text: 'Khelor'),
        TextSpan(text: 'a', style: TextStyle(color: KheloraColors.gold)),
      ],
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final tagline = text('Play Your Way.', 74, FontWeight.w500, onLight ? const Color(0xFF5A6587) : const Color(0xFFC5CDE8), spacing: 3);
  const left = h + 40;
  final top = (h - word.height - tagline.height) / 2;
  word.paint(canvas, Offset(left, top));
  tagline.paint(canvas, Offset(left + 8, top + word.height));
  return recorder.endRecording().toImage(w.toInt(), h.toInt());
}

///SVG of the symbol, mirroring KheloraMarkPainter's geometry
String symbolSvg() {
  const tile = 0.30 * 1024, corner = 0.07 * 1024, dist = 0.24 * 1024, token = 0.085 * 1024;
  const colors = [('F6C453', 'FADB94'), ('4CD7A0', '8FE6C2'), ('FF6F78', 'FFA3A9'), ('6E9BFF', 'A4C0FF')];
  final b = StringBuffer()
    ..writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">')
    ..writeln('  <defs>');
  for (int i = 0; i < 4; i++) {
    b.writeln('    <linearGradient id="g$i" x1="0" y1="0" x2="1" y2="1">'
        '<stop offset="0" stop-color="#${colors[i].$2}"/><stop offset="0.55" stop-color="#${colors[i].$1}"/></linearGradient>');
  }
  b.writeln('  </defs>');
  for (int i = 0; i < 4; i++) {
    final a = -math.pi / 2 + i * math.pi / 2;
    final cx = 512 + math.cos(a) * dist, cy = 512 + math.sin(a) * dist;
    b.writeln('  <rect x="${(cx - tile / 2).toStringAsFixed(1)}" y="${(cy - tile / 2).toStringAsFixed(1)}" '
        'width="$tile" height="$tile" rx="$corner" fill="url(#g$i)" '
        'transform="rotate(45 ${cx.toStringAsFixed(1)} ${cy.toStringAsFixed(1)})"/>');
  }
  b
    ..writeln('  <circle cx="512" cy="512" r="${(token + 0.03 * 1024).toStringAsFixed(1)}" fill="#11182B"/>')
    ..writeln('  <circle cx="512" cy="512" r="${token.toStringAsFixed(1)}" fill="#FFFFFF"/>')
    ..writeln('</svg>');
  return b.toString();
}

void main() {
  setUpAll(loadFonts);

  test('generate Khelora brand assets', () async {
    //Brand source files
    await savePng(await render(1024, markScale: 1), 'branding/khelora_symbol.png');
    await savePng(await render(1024, backdrop: Backdrop.rounded), 'branding/khelora_icon.png');
    await savePng(await renderFullLogo(), 'branding/khelora_logo.png');
    await savePng(await renderFullLogo(onLight: true), 'branding/khelora_logo_on_light.png');
    File('branding/khelora_symbol.svg').writeAsStringSync(symbolSvg());

    const densities = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};
    const res = 'android/app/src/main/res';
    for (final e in densities.entries) {
      int px(double dp) => (dp * e.value).round();
      //Legacy launcher icon (pre Android 8)
      await savePng(await render(px(48), backdrop: Backdrop.rounded), '$res/mipmap-${e.key}/ic_launcher.png');
      //Adaptive icon layers: 108dp canvas, mark inside the 66dp safe zone
      await savePng(await render(px(108), markScale: 0.56), '$res/mipmap-${e.key}/ic_launcher_foreground.png');
      await savePng(
          await render(px(108), markScale: 0.56, mono: true), '$res/mipmap-${e.key}/ic_launcher_monochrome.png');
      //Native launch screen logo (pre Android 12)
      await savePng(await render(px(144), markScale: 0.9), '$res/drawable-${e.key}/splash_logo.png');
    }

    //Web
    await savePng(await render(64, backdrop: Backdrop.rounded, markScale: 0.8), 'web/favicon.png');
    await savePng(await render(192, backdrop: Backdrop.rounded), 'web/icons/Icon-192.png');
    await savePng(await render(512, backdrop: Backdrop.rounded), 'web/icons/Icon-512.png');
    await savePng(await render(192, backdrop: Backdrop.square, markScale: 0.6), 'web/icons/Icon-maskable-192.png');
    await savePng(await render(512, backdrop: Backdrop.square, markScale: 0.6), 'web/icons/Icon-maskable-512.png');

    //iOS (opaque, square: iOS applies its own corner mask)
    const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    final iconName = RegExp(r'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png');
    for (final file in Directory(ios).listSync().whereType<File>()) {
      final m = iconName.firstMatch(file.uri.pathSegments.last);
      if (m == null) continue;
      final px = (double.parse(m.group(1)!) * int.parse(m.group(2)!)).round();
      await saveOpaquePng(await render(px, backdrop: Backdrop.square), file.path);
    }
  });
}
