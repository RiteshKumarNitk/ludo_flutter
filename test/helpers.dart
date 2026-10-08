import 'package:flutter_test/flutter_test.dart';

///Poll [condition] every 50 ms until it holds or [timeout] elapses.
///Returns whether the condition was met in time.
Future<bool> waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return true;
    await Future.delayed(const Duration(milliseconds: 50));
  }
  return condition();
}
