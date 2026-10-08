import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ludo_flutter/constants.dart';

///Landing page: warms up the image cache, then routes to [HomeScreen]
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  static const List<String> _assets = [
    "assets/images/thankyou.gif",
    "assets/images/board.png",
    "assets/images/dice/1.png",
    "assets/images/dice/2.png",
    "assets/images/dice/3.png",
    "assets/images/dice/4.png",
    "assets/images/dice/5.png",
    "assets/images/dice/6.png",
    "assets/images/dice/draw.gif",
    "assets/images/crown/1st.png",
    "assets/images/crown/2nd.png",
    "assets/images/crown/3rd.png",
  ];

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _precacheImages() async {
    try {
      await Future.wait([
        for (final asset in _assets) precacheImage(AssetImage(asset), context),
      ]);
    } catch (_) {
      ///A missing asset should never block the splash screen
    }
  }

  Future<void> _prepare() async {
    ///Warm up the image cache in parallel, but give up waiting after a second
    final cacheReady = Future.any([
      _precacheImages(),
      Future<void>.delayed(const Duration(seconds: 1)),
    ]);

    ///Keep the splash on screen for a moment even on fast devices
    await Future.wait([
      cacheReady,
      Future<void>.delayed(const Duration(milliseconds: 1800)),
    ]);

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 0.4, end: 1).animate(_controller),
              child: const _LudoTitle(fontSize: 56),
            ),
            const SizedBox(height: 40),
            Image.asset("assets/images/dice/draw.gif", width: 64, height: 64),
            const SizedBox(height: 40),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

///The LUDO wordmark, each letter in a ludo color
class _LudoTitle extends StatelessWidget {
  final double fontSize;
  const _LudoTitle({required this.fontSize});

  @override
  Widget build(BuildContext context) {
    const letters = ['L', 'U', 'D', 'O'];
    const colors = [LudoColor.green, LudoColor.yellow, LudoColor.blue, LudoColor.red];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < letters.length; i++)
          Text(
            letters[i],
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: colors[i],
              letterSpacing: 2,
            ),
          ),
      ],
    );
  }
}
