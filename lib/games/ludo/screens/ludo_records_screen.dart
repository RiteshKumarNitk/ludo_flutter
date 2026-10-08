import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/dialogs/game_dialogs.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/game_scaffold.dart';
import '../../../shared/widgets/segmented_choice.dart';
import '../data/ludo_achievements.dart';
import '../data/ludo_records.dart';
import '../ludo_routes.dart';
import '../ludo_strings.dart';
import '../models/ludo_models.dart';

///Statistics and achievements in one place
class LudoRecordsScreen extends StatefulWidget {
  const LudoRecordsScreen({super.key});

  @override
  State<LudoRecordsScreen> createState() => _LudoRecordsScreenState();
}

class _LudoRecordsScreenState extends State<LudoRecordsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final t = LudoStrings.of(context);
    final records = context.watch<LudoRecords>();
    return GameScaffold(
      title: t.records,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.sm),
            child: SegmentedChoice<int>(
              options: [
                ChoiceOption(0, t.statistics, icon: Icons.bar_chart_rounded),
                ChoiceOption(1, t.achievements, icon: Icons.emoji_events_rounded),
              ],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppMotion.normal,
              child: _tab == 0
                  ? KeyedSubtree(key: const ValueKey('stats'), child: _StatsTab(records: records))
                  : KeyedSubtree(key: const ValueKey('achievements'), child: _AchievementsTab(records: records)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final LudoRecords records;
  const _StatsTab({required this.records});

  Future<void> _confirmReset(BuildContext context) async {
    final t = LudoStrings.of(context);
    final ok = await showConfirmDialog(context,
        title: t.resetRecordsTitle,
        message: t.resetRecordsBody,
        confirmLabel: t.resetRecords.toUpperCase(),
        icon: Icons.delete_outline_rounded,
        destructive: true);
    if (ok) records.reset();
  }

  @override
  Widget build(BuildContext context) {
    final t = LudoStrings.of(context);
    if (records.isEmpty) {
      return EmptyState(
        icon: Icons.emoji_events_rounded,
        title: t.noMatchesTitle,
        message: t.noMatchesBody,
        actionLabel: t.playLudo,
        onAction: () => Navigator.of(context).pushReplacementNamed(LudoRoutes.setup),
      );
    }
    final maxDifficulty = math.max(1, records.winsByDifficulty.values.fold<int>(0, math.max));
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xl),
      children: [
        SectionLabel(t.vsComputerStats),
        GameCard(
          child: Row(
            children: [
              _WinRateRing(rate: records.winRate, label: t.winRate),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  children: [
                    _Line(label: t.wins, value: records.matchesWon, color: AppColors.success),
                    _Line(label: t.losses, value: records.matchesLost, color: AppColors.danger),
                    _Line(label: t.bestStreak, value: records.bestWinStreak, color: AppColors.primary),
                    _Line(label: t.currentStreak, value: records.currentWinStreak, color: AppColors.secondary),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 2.0,
          children: [
            _Tile(icon: Icons.sports_esports_rounded, label: t.played, value: records.matchesPlayed),
            _Tile(icon: Icons.groups_rounded, label: t.passAndPlayGames, value: records.passAndPlayGames),
            _Tile(icon: Icons.gps_fixed_rounded, label: t.pawnsCaptured, value: records.capturesMade),
            _Tile(icon: Icons.heart_broken_rounded, label: t.pawnsLost, value: records.pawnsLost),
            _Tile(icon: Icons.casino_rounded, label: t.sixesRolled, value: records.sixesRolled),
            _Tile(icon: Icons.shield_rounded, label: 'Flawless wins', value: records.flawlessWins),
          ],
        ),
        SectionLabel(t.winsByDifficulty),
        GameCard(
          shadows: null,
          child: Column(
            children: [
              for (final d in BotDifficulty.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
                  child: Row(
                    children: [
                      SizedBox(width: 72, child: Text(t.difficultyName(d), style: AppTypography.subtitle.copyWith(fontSize: 14))),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: AppRadius.pill,
                          child: LinearProgressIndicator(
                            value: (records.winsByDifficulty[d] ?? 0) / maxDifficulty,
                            minHeight: 10,
                            backgroundColor: AppColors.surfaceSunken,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text('${records.winsByDifficulty[d] ?? 0}', textAlign: TextAlign.end, style: AppTypography.subtitle),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        GameButton(
          label: t.resetRecords.toUpperCase(),
          icon: Icons.delete_outline_rounded,
          variant: GameButtonVariant.ghost,
          onPressed: () => _confirmReset(context),
        ),
      ],
    );
  }
}

class _AchievementsTab extends StatelessWidget {
  final LudoRecords records;
  const _AchievementsTab({required this.records});

  @override
  Widget build(BuildContext context) {
    final t = LudoStrings.of(context);
    final unlocked = ludoAchievements.where((a) => a.unlocked(records)).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
      children: [
        GameCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 30),
                const SizedBox(width: AppSpacing.sm),
                Text(t.unlockedOf(unlocked, ludoAchievements.length), style: AppTypography.title),
              ]),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: AppRadius.pill,
                child: LinearProgressIndicator(
                  value: unlocked / ludoAchievements.length,
                  minHeight: 10,
                  backgroundColor: AppColors.surfaceSunken,
                  color: AppColors.gold,
                ),
              ),
              if (records.vsComputerGames == 0) ...[
                const SizedBox(height: AppSpacing.md),
                Text(t.achievementsHint, style: AppTypography.caption),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final a in ludoAchievements)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _AchievementTile(achievement: a, records: records),
          ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final LudoAchievement achievement;
  final LudoRecords records;
  const _AchievementTile({required this.achievement, required this.records});

  @override
  Widget build(BuildContext context) {
    final done = achievement.unlocked(records);
    final progress = achievement.progress(records);
    return GameCard(
      shadows: null,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: done ? AppColors.gold : AppColors.outline,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.gold : AppColors.surfaceSunken,
              boxShadow: done ? AppShadows.glow(AppColors.gold, strength: 0.5) : null,
            ),
            child: Icon(done ? achievement.icon : Icons.lock_rounded,
                color: done ? AppColors.onPrimary : AppColors.textMuted, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title,
                    style: AppTypography.subtitle.copyWith(color: done ? AppColors.textPrimary : AppColors.textSecondary)),
                Text(achievement.description, style: AppTypography.caption),
                if (!done && achievement.target > 1) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppRadius.pill,
                        child: LinearProgressIndicator(
                          value: progress / achievement.target,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceSunken,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('$progress/${achievement.target}', style: AppTypography.caption),
                  ]),
                ],
              ],
            ),
          ),
          if (done) const Icon(Icons.check_circle_rounded, color: AppColors.success),
        ],
      ),
    );
  }
}

class _WinRateRing extends StatelessWidget {
  final double rate;
  final String label;
  const _WinRateRing({required this.rate, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: rate,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.surfaceSunken,
              color: AppColors.success,
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${(rate * 100).round()}%', style: AppTypography.number),
            Text(label, style: AppTypography.caption.copyWith(fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Line({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTypography.body.copyWith(fontSize: 14))),
        Text('$value', style: AppTypography.subtitle),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  const _Tile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GameCard(
      shadows: null,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: AppTypography.number.copyWith(fontSize: 20)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption.copyWith(fontSize: 11.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
