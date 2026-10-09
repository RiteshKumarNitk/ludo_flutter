import 'package:flutter/material.dart';

import '../../core/branding/khelora_mark.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import 'home_screen.dart';

///Khelora intro (~1.6 s): the four tiles assemble around the center token,
///the wordmark and tagline fade in, then the launcher fades in. Runs only
///at app start; it replaces itself so it never appears again on Back.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(_openHome);
  }

  void _openHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      settings: const RouteSettings(name: '/home'),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => const HomeScreen(),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    double phase(double start, double end, [Curve curve = Curves.easeOut]) =>
        curve.transform(((_controller.value - start) / (end - start)).clamp(0.0, 1.0));

    return Scaffold(
      backgroundColor: KheloraColors.navy,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final symbol = phase(0.0, 0.25);
            final tiles = phase(0.05, 0.7, Curves.linear);
            final word = phase(0.5, 0.8);
            final tagline = phase(0.68, 0.95);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: symbol,
                  child: Transform.scale(
                    scale: 0.85 + 0.15 * symbol,
                    child: KheloraMark(size: 128, progress: tiles),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Opacity(
                  opacity: word,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - word)),
                    child: const KheloraWordmark(fontSize: 46),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Opacity(
                  opacity: tagline,
                  child: Text(
                    s.tagline,
                    style: AppTypography.subtitle.copyWith(color: AppColors.textSecondary, letterSpacing: 1.2),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
