import 'package:flutter/material.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/ludo_provider.dart';
import 'package:provider/provider.dart';

///Final ranking shown when the match is decided
class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key});

  String _crownAsset(int rank) {
    final suffix = rank == 1 ? 'st' : rank == 2 ? 'nd' : 'rd';
    return 'assets/images/crown/$rank$suffix.png';
  }

  String _rankLabel(int rank) {
    switch (rank) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${rank}th';
    }
  }

  Color _playerColor(LudoPlayerType type) {
    switch (type) {
      case LudoPlayerType.green:
        return LudoColor.green;
      case LudoPlayerType.yellow:
        return LudoColor.yellow;
      case LudoPlayerType.blue:
        return LudoColor.blue;
      case LudoPlayerType.red:
        return LudoColor.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LudoProvider>();
    final ranking = [
      ...provider.winners,
      ...provider.players
          .where((player) => !provider.winners.contains(player.type))
          .map((player) => player.type),
    ];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Game Over',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
                const SizedBox(height: 12),
                Image.asset('assets/images/thankyou.gif', height: 140),
                const SizedBox(height: 16),
                for (int i = 0; i < ranking.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _playerColor(ranking[i]).withValues(alpha: i == 0 ? 0.35 : 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _playerColor(ranking[i]),
                          width: i == 0 ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (i < provider.winners.length)
                            Image.asset(_crownAsset(i + 1), width: 26, height: 26)
                          else
                            const SizedBox(width: 26, height: 26),
                          const SizedBox(width: 12),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _playerColor(ranking[i]),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              provider.player(ranking[i]).name,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _rankLabel(i + 1),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _playerColor(ranking[i]),
                            ),
                          ),
                          if (provider.player(ranking[i]).isCpu) ...[
                            const SizedBox(width: 8),
                            const Text('CPU', style: TextStyle(fontSize: 11, color: Colors.white54)),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    context.read<LudoProvider>().restartGame();
                    Navigator.of(context).pushReplacementNamed('/game');
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Play Again'),
                  style: FilledButton.styleFrom(
                    backgroundColor: LudoColor.green,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.settings.name == '/home'),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Back to Menu'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'This game made with Flutter ❤️ by Mochamad Nizwar Syafuan',
                  textAlign: TextAlign.center,
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
