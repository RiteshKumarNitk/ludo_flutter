import 'package:flutter/material.dart';
import 'package:ludo_flutter/achievements.dart';
import 'package:ludo_flutter/l10n/app_strings.dart';
import 'package:ludo_flutter/stats_provider.dart';
import 'package:provider/provider.dart';

///Every achievement of the game with its locked / unlocked state, derived
///from the current [StatsProvider]
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final stats = context.watch<StatsProvider>();
    final unlockedCount = unlockedAchievementCount(stats);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.achievements),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Text(
                s.unlockedOfTotal(unlockedCount, kAchievements.length),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
            for (final achievement in kAchievements)
              _AchievementTile(
                achievement: achievement,
                unlocked: achievement.unlocked(stats),
              ),
          ],
        ),
      ),
    );
  }
}

///One achievement row: badge, title, description and a check or lock
class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;

  const _AchievementTile({
    required this.achievement,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? Colors.amber.withValues(alpha: 0.18)
                  : Colors.white10,
              border: Border.all(
                color: unlocked ? Colors.amber : Colors.white24,
                width: 1.5,
              ),
            ),
            child: Icon(
              achievement.icon,
              size: 24,
              color: unlocked ? Colors.amber : Colors.white38,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: unlocked ? Colors.white : Colors.white54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            size: 22,
            color: unlocked ? Colors.amber : Colors.white24,
          ),
        ],
      ),
    );
  }
}
