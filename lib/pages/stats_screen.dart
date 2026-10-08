import 'package:flutter/material.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/game_config.dart';
import 'package:ludo_flutter/l10n/app_strings.dart';
import 'package:ludo_flutter/stats_provider.dart';
import 'package:provider/provider.dart';

///Lifetime statistics: headline totals, wins by color and difficulty, plus
///a reset action behind a confirmation dialog
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  ///Board color used for a seat's dot
  Color _colorOf(LudoPlayerType type) {
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

  ///Display name for a difficulty, matching the setup screen labels
  String _difficultyLabel(CpuDifficulty difficulty, AppStrings s) {
    switch (difficulty) {
      case CpuDifficulty.easy:
        return s.difficultyEasy;
      case CpuDifficulty.medium:
        return s.difficultyMedium;
      case CpuDifficulty.hard:
        return s.difficultyHard;
    }
  }

  ///Icon for a difficulty, matching the setup screen choices
  IconData _difficultyIcon(CpuDifficulty difficulty) {
    switch (difficulty) {
      case CpuDifficulty.easy:
        return Icons.sentiment_satisfied_alt_rounded;
      case CpuDifficulty.medium:
        return Icons.sentiment_neutral_rounded;
      case CpuDifficulty.hard:
        return Icons.local_fire_department_rounded;
    }
  }

  ///Small colored circle used as a row leading in the color breakdown
  Widget _colorDot(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }

  ///Ask for confirmation before wiping every recorded statistic
  void _confirmReset(BuildContext context) {
    final stats = context.read<StatsProvider>();
    final s = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.resetStatisticsTitle),
        content: Text(s.resetStatisticsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              stats.reset();
            },
            child: Text(
              s.reset,
              style: const TextStyle(color: LudoColor.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final stats = context.watch<StatsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(s.statistics),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (stats.matchesPlayed == 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  s.statsEmpty,
                  style: const TextStyle(fontSize: 13, color: Colors.white54),
                ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                  label: s.statMatchesPlayed,
                  value: '${stats.matchesPlayed}',
                ),
                _StatCard(label: s.statMatchesWon, value: '${stats.matchesWon}'),
                _StatCard(
                  label: s.statWinRate,
                  value: '${(stats.winRate * 100).round()}%',
                ),
                _StatCard(
                  label: s.statMatchesLost,
                  value: '${stats.matchesLost}',
                ),
                _StatCard(
                  label: s.statWinStreak,
                  value: '${stats.currentWinStreak}',
                ),
                _StatCard(
                  label: s.statBestStreak,
                  value: '${stats.bestWinStreak}',
                ),
                _StatCard(
                  label: s.statCapturesFor,
                  value: '${stats.totalCapturesMade}',
                ),
                _StatCard(
                  label: s.statCapturesAgainst,
                  value: '${stats.totalCapturesTaken}',
                ),
                _StatCard(
                  label: s.statSixesRolled,
                  value: '${stats.totalSixesRolled}',
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionTitle(s.winsByColor),
            _CountGroup(
              children: [
                for (final type in LudoPlayerType.values)
                  _CountRow(
                    leading: _colorDot(_colorOf(type)),
                    label: s.colorName(type),
                    count: stats.winsByColor[type] ?? 0,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionTitle(s.winsByDifficulty),
            _CountGroup(
              children: [
                for (final difficulty in CpuDifficulty.values)
                  _CountRow(
                    leading: Icon(
                      _difficultyIcon(difficulty),
                      size: 20,
                      color: Colors.white70,
                    ),
                    label: _difficultyLabel(difficulty, s),
                    count: stats.winsByDifficulty[difficulty] ?? 0,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _confirmReset(context),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(s.resetStatistics),
              style: OutlinedButton.styleFrom(
                foregroundColor: LudoColor.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///One headline number with its caption, used in the stats grid
class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

///Section heading above a group of rows
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }
}

///Dark rounded container grouping related count rows
class _CountGroup extends StatelessWidget {
  final List<Widget> children;

  const _CountGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

///A single "label ..... count" line with a leading dot or icon
class _CountRow extends StatelessWidget {
  final Widget leading;
  final String label;
  final int count;

  const _CountRow({
    required this.leading,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 15)),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
