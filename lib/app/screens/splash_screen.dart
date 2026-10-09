import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

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
    return Scaffold(
      backgroundColor: const Color(0xFF11182B),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Sequence timings
            // 0.0 - 0.3: Logo symbol fades in and scales up
            // 0.1 - 0.6: 4 tiles animate into position (already handled by their own offsets, but we can do it here)
            // 0.4 - 0.8: Khelora wordmark fades in
            // 0.6 - 1.0: Tagline fades in
            
            final symbolT = Curves.easeOutCubic.transform((_controller.value / 0.3).clamp(0.0, 1.0));
            final tilesT = Curves.easeOutCubic.transform(((_controller.value - 0.1) / 0.5).clamp(0.0, 1.0));
            final wordmarkT = Curves.easeIn.transform(((_controller.value - 0.4) / 0.4).clamp(0.0, 1.0));
            final taglineT = Curves.easeIn.transform(((_controller.value - 0.6) / 0.4).clamp(0.0, 1.0));

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Symbol
                Opacity(
                  opacity: symbolT,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * symbolT),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        children: [
                          _buildTile(const Color(0xFFFF6F78), 0, 0, tilesT, -40, -40), // Top Left
                          _buildTile(const Color(0xFF4CD7A0), 1, 0, tilesT, 40, -40),  // Top Right
                          _buildTile(const Color(0xFF6E9BFF), 0, 1, tilesT, -40, 40),  // Bottom Left
                          _buildTile(const Color(0xFFF6C453), 1, 1, tilesT, 40, 40),   // Bottom Right
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Wordmark
                Opacity(
                  opacity: wordmarkT,
                  child: Text(
                    'Khelora',
                    style: AppTypography.display.copyWith(fontSize: 48, color: Colors.white, letterSpacing: 2),
                  ),
                ),
                const SizedBox(height: 8),
                // Tagline
                Opacity(
                  opacity: taglineT,
                  child: Text(
                    'Play Your Way.',
                    style: AppTypography.subtitle.copyWith(fontSize: 16, color: Colors.white70, letterSpacing: 1),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTile(Color color, int x, int y, double t, double offsetX, double offsetY) {
    // x: 0 = left, 1 = right
    // y: 0 = top, 1 = bottom
    // When t=0, they are at offsetX/Y. When t=1, they are in their final positions (which is 0 offset from grid)
    const size = 46.0;
    const spacing = 8.0;
    
    // Final positions inside the 100x100 container
    final finalLeft = x == 0 ? 0.0 : size + spacing;
    final finalTop = y == 0 ? 0.0 : size + spacing;
    
    final currentLeft = finalLeft + offsetX * (1 - t);
    final currentTop = finalTop + offsetY * (1 - t);
    
    return Positioned(
      left: currentLeft,
      top: currentTop,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
