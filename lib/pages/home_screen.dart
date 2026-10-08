import 'package:flutter/material.dart';
import 'package:ludo_flutter/constants.dart';

///Main menu of the game
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A classic Ludo board game for 2 to 4 players, playable against friends on one device or the computer.'),
            SizedBox(height: 12),
            Text('This game made with Flutter ❤️ by Mochamad Nizwar Syafuan', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset("assets/images/board.png", width: 200, height: 200),
                const SizedBox(height: 8),
                const Text(
                  'LUDO',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 6),
                ),
                const SizedBox(height: 40),
                _MenuButton(
                  label: 'Play',
                  icon: Icons.play_arrow_rounded,
                  color: LudoColor.green,
                  onTap: () => Navigator.of(context).pushNamed('/setup'),
                ),
                _MenuButton(
                  label: 'How to Play',
                  icon: Icons.help_outline_rounded,
                  color: LudoColor.yellow,
                  onTap: () => Navigator.of(context).pushNamed('/howToPlay'),
                ),
                _MenuButton(
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                  color: LudoColor.blue,
                  onTap: () => Navigator.of(context).pushNamed('/settings'),
                ),
                _MenuButton(
                  label: 'About',
                  icon: Icons.info_outline_rounded,
                  color: LudoColor.red,
                  onTap: () => _openAbout(context),
                ),
                const SizedBox(height: 40),
                const Text(
                  'This game made with Flutter ❤️',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 280,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
