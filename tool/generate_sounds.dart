//Synthesizes the small UI sound effects into assets/sounds/ as 16-bit mono
//WAV files, so the app needs no audio library beyond its player.
//
//Run from the project root:  dart run tool/generate_sounds.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 22050;

void main() {
  _write('assets/sounds/tap.wav', _tap());
  _write('assets/sounds/dice.wav', _dice());
  _write('assets/sounds/step.wav', _step());
  _write('assets/sounds/capture.wav', _capture());
  _write('assets/sounds/home.wav', _home());
  _write('assets/sounds/win.wav', _win());
  stdout.writeln('Sounds written to assets/sounds/');
}

List<double> _buffer(double seconds) => List.filled((seconds * sampleRate).round(), 0.0);

///Adds a decaying tone; [harmonics] are (multiple, gain) pairs
void _tone(List<double> out, double start, double length, double freq,
    {double gain = 0.5, double decay = 6, List<(double, double)> harmonics = const [(1, 1)], double attack = 0.004}) {
  final int from = (start * sampleRate).round();
  final int count = (length * sampleRate).round();
  for (int i = 0; i < count && from + i < out.length; i++) {
    final t = i / sampleRate;
    final env = min(1.0, t / attack) * exp(-decay * t);
    double v = 0;
    for (final (mult, g) in harmonics) {
      v += g * sin(2 * pi * freq * mult * t);
    }
    out[from + i] += gain * env * v;
  }
}

///A dice rattling and settling: clicks that thin out over ~0.55 s
List<double> _dice() {
  final out = _buffer(0.6);
  final rnd = Random(11);
  double t = 0;
  int hit = 0;
  while (t < 0.5) {
    final from = (t * sampleRate).round();
    final pitch = 900 + rnd.nextDouble() * 1400;
    final gain = 0.5 * (1 - t * 1.4).clamp(0.25, 1.0);
    for (int i = 0; i < (0.025 * sampleRate).round() && from + i < out.length; i++) {
      final s = i / sampleRate;
      final env = exp(-140 * s);
      out[from + i] += gain * env * (0.6 * sin(2 * pi * pitch * s) + 0.4 * (rnd.nextDouble() * 2 - 1));
    }
    hit++;
    t += 0.03 + hit * 0.006 + rnd.nextDouble() * 0.02;
  }
  return out;
}

///A soft wooden tok for each step a pawn takes
List<double> _step() {
  final out = _buffer(0.09);
  _tone(out, 0, 0.09, 520, gain: 0.45, decay: 55, harmonics: const [(1, 1), (2.7, 0.25)]);
  return out;
}

List<double> _tap() {
  final out = _buffer(0.06);
  _tone(out, 0, 0.06, 1250, gain: 0.35, decay: 70, harmonics: const [(1, 1), (2, 0.25)]);
  return out;
}

///A short "knock back": a punchy thud plus a falling sweep
List<double> _capture() {
  final out = _buffer(0.42);
  final rnd = Random(7);
  double phase = 0;
  for (int i = 0; i < out.length; i++) {
    final t = i / sampleRate;
    final freq = 620 * exp(-5.5 * t) + 90;
    phase += 2 * pi * freq / sampleRate;
    final square = sin(phase) + 0.3 * sin(3 * phase);
    final env = min(1.0, t / 0.003) * exp(-7 * t);
    final noise = (rnd.nextDouble() * 2 - 1) * exp(-60 * t);
    out[i] = 0.42 * env * square + 0.25 * noise;
  }
  _tone(out, 0, 0.2, 110, gain: 0.45, decay: 18);
  return out;
}

///Two bright bell notes for a pawn reaching home
List<double> _home() {
  final out = _buffer(0.55);
  const bell = [(1.0, 1.0), (2.0, 0.35), (3.01, 0.12)];
  _tone(out, 0, 0.5, 987.8, gain: 0.32, decay: 7, harmonics: bell);
  _tone(out, 0.09, 0.46, 1318.5, gain: 0.32, decay: 6, harmonics: bell);
  return out;
}

///Rising arpeggio into a held major chord
List<double> _win() {
  final out = _buffer(1.5);
  const voice = [(1.0, 1.0), (2.0, 0.3), (3.0, 0.1)];
  const notes = [523.25, 659.25, 783.99, 1046.5];
  for (int i = 0; i < notes.length; i++) {
    _tone(out, i * 0.11, 0.3, notes[i], gain: 0.26, decay: 6, harmonics: voice);
  }
  for (final f in [523.25, 659.25, 783.99, 1046.5]) {
    _tone(out, 0.46, 1.0, f, gain: 0.14, decay: 2.6, harmonics: voice, attack: 0.02);
  }
  return out;
}

void _write(String path, List<double> samples) {
  double peak = 0;
  for (final s in samples) {
    peak = max(peak, s.abs());
  }
  final scale = peak > 0.95 ? 0.95 / peak : 1.0;
  final data = ByteData(44 + samples.length * 2);
  void ascii(int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); //PCM
  data.setUint16(22, 1, Endian.little); //mono
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (int i = 0; i < samples.length; i++) {
    final v = (samples[i] * scale * 32767).round().clamp(-32768, 32767);
    data.setInt16(44 + i * 2, v, Endian.little);
  }
  File(path).writeAsBytesSync(data.buffer.asUint8List());
}
