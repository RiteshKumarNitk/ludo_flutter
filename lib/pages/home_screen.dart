import 'package:flutter/material.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/l10n/app_strings.dart';
import 'package:ludo_flutter/ludo_provider.dart';
import 'package:provider/provider.dart';

///Main menu of the game
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasSave = false;
  Animation<double>? _secondaryAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ///Re-check for a suspended match whenever we come back from a pushed route
    final secondary = ModalRoute.of(context)?.secondaryAnimation;
    if (!identical(secondary, _secondaryAnimation)) {
      _secondaryAnimation?.removeStatusListener(_onReturnFromRoute);
      _secondaryAnimation = secondary;
      _secondaryAnimation?.addStatusListener(_onReturnFromRoute);
    }
    _refreshSave();
  }

  void _onReturnFromRoute(AnimationStatus status) {
    if (status == AnimationStatus.completed) _refreshSave();
  }

  Future<void> _refreshSave() async {
    final exists = await LudoProvider.savedMatchExists();
    if (mounted && exists != _hasSave) {
      setState(() => _hasSave = exists);
    }
  }

  Future<void> _resume(BuildContext context) async {
    final provider = context.read<LudoProvider>();
    final restored = await provider.resumeSavedGame();
    if (!context.mounted) return;
    if (restored) {
      Navigator.of(context).pushNamed('/game');
    } else {
      ///Save was corrupt or vanished; drop the stale button
      await _refreshSave();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).noSavedGame)),
      );
    }
  }

  @override
  void dispose() {
    _secondaryAnimation?.removeStatusListener(_onReturnFromRoute);
    super.dispose();
  }

  void _openAbout(BuildContext context) {
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.aboutTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.aboutDescription),
            const SizedBox(height: 12),
            Text(s.aboutCredit, style: const TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.close)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
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
                Text(
                  s.appTitle,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 6),
                ),
                const SizedBox(height: 40),
                if (_hasSave)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _resume(context),
                        child: Container(
                          width: 280,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: LudoColor.yellow, width: 2),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.history_rounded, color: LudoColor.yellow, size: 28),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  s.resumeGame,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: LudoColor.yellow,
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
                  ),
                _MenuButton(
                  label: s.play,
                  icon: Icons.play_arrow_rounded,
                  color: LudoColor.green,
                  onTap: () => Navigator.of(context).pushNamed('/setup'),
                ),
                _MenuButton(
                  label: s.howToPlay,
                  icon: Icons.help_outline_rounded,
                  color: LudoColor.yellow,
                  onTap: () => Navigator.of(context).pushNamed('/howToPlay'),
                ),
                _MenuButton(
                  label: s.settings,
                  icon: Icons.settings_outlined,
                  color: LudoColor.blue,
                  onTap: () => Navigator.of(context).pushNamed('/settings'),
                ),
                _MenuButton(
                  label: s.about,
                  icon: Icons.info_outline_rounded,
                  color: LudoColor.red,
                  onTap: () => _openAbout(context),
                ),
                _MenuButton(
                  label: s.statistics,
                  icon: Icons.bar_chart_rounded,
                  color: LudoColor.blue,
                  onTap: () => Navigator.of(context).pushNamed('/stats'),
                ),
                _MenuButton(
                  label: s.achievements,
                  icon: Icons.emoji_events_rounded,
                  color: LudoColor.yellow,
                  onTap: () => Navigator.of(context).pushNamed('/achievements'),
                ),
                const SizedBox(height: 40),
                Text(
                  s.madeWithLove,
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
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
