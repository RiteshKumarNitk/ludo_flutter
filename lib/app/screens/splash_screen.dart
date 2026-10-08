import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/game_scaffold.dart';

///Short branded intro, then the launcher
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(() {
      if (mounted) Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const letters = ['L', 'U', 'D', 'O'];
    const colors = [AppColors.playerRed, AppColors.playerGreen, AppColors.playerYellow, AppColors.playerBlue];
    return Scaffold(
      backgroundColor: AppColors.backgroundBottom,
      body: GameBackground(
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < letters.length; i++)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final start = i * 0.12;
                    final t = Curves.elasticOut.transform(((_controller.value - start) / 0.6).clamp(0.0, 1.0));
                    return Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Transform.translate(offset: Offset(0, (1 - t) * -40), child: child),
                    );
                  },
                  child: Container(
                    width: 58,
                    height: 66,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors[i],
                      borderRadius: AppRadius.mdAll,
                      boxShadow: [BoxShadow(color: AppColors.darken(colors[i], 0.4), offset: const Offset(0, 5))],
                    ),
                    child: Text(letters[i], style: AppTypography.display.copyWith(fontSize: 42)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
