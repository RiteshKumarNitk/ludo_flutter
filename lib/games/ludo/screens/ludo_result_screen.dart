import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/game_scaffold.dart';
import '../controller/ludo_controller.dart';
import '../data/ludo_preferences.dart';
import '../ludo_routes.dart';
import '../ludo_strings.dart';
import '../models/ludo_models.dart';
import '../models/ludo_state.dart';
import '../widgets/board_theme.dart';

class LudoResultScreen extends StatefulWidget {
  const LudoResultScreen({super.key});

  @override
  State<LudoResultScreen> createState() => _LudoResultScreenState();
}

class _LudoResultScreenState extends State<LudoResultScreen> with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  void _playAgain() {
    context.read<LudoController>().restart();
    Navigator.of(context).pushReplacementNamed(LudoRoutes.game);
  }

  void _newGame() => Navigator.of(context).pushReplacementNamed(LudoRoutes.setup);

  void _home() => Navigator.of(context).popUntil((route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LudoController>();
    final theme = context.watch<LudoPreferences>().theme;
    final t = LudoStrings.of(context);
    if (!controller.hasMatch || !controller.isFinished) {
      //Nothing to show (e.g. restored after the match was cleared)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _home();
      });
      return const Scaffold(backgroundColor: AppColors.backgroundBottom);
    }

    final state = controller.state;
    final config = controller.config;
    final winner = state.seatOf(state.winner!);
    final humans = [for (final s in state.seats) if (!s.isBot) s.color];
    final singleHuman = config.mode == LudoMode.vsComputer && humans.length == 1;
    final humanWon = humans.contains(winner.color);

    final String headline;
    final String subtitle;
    final bool celebrate;
    if (config.mode == LudoMode.vsComputer) {
      if (humanWon) {
        headline = singleHuman ? t.youWin : t.winsTitle(winner.name);
        subtitle = t.greatGame;
        celebrate = true;
      } else {
        headline = t.youLost;
        final place = singleHuman ? state.placeOf(humans.first) : null;
        subtitle = place != null && place > 1 && state.seats.length > 2
            ? '${t.finishedPlace(t.ordinal(place))} · ${t.betterLuck}'
            : t.betterLuck;
        celebrate = false;
      }
    } else {
      headline = t.gameOver;
      subtitle = t.winsTitle(winner.name);
      celebrate = true;
    }

    final totalTurns = state.stats.values.fold<int>(0, (sum, s) => sum + s.turns);
    final winnerColor = theme.colorOf(winner.color);

    return PopScope(
      canPop: true,
      child: GameScaffold(
        showBack: false,
        //Actions stay visible on every screen size
        bottom: Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.backgroundBottom.withValues(alpha: 0.92),
            border: const Border(top: BorderSide(color: AppColors.outline)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GameButton(label: t.playAgain, icon: Icons.replay_rounded, onPressed: _playAgain),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(
                  child: GameButton(
                    label: t.newGame,
                    variant: GameButtonVariant.secondary,
                    onPressed: _newGame,
                    height: 52,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GameButton(label: t.homeButton, variant: GameButtonVariant.ghost, onPressed: _home, height: 52),
                ),
              ]),
            ],
          ),
        ),
        body: Stack(
          children: [
            if (celebrate)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _loop,
                    builder: (context, _) => CustomPaint(painter: _ConfettiPainter(_loop.value, theme)),
                  ),
                ),
              ),
            ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
              children: [
                _Trophy(intro: _intro, loop: _loop, color: celebrate ? AppColors.gold : AppColors.textMuted, won: celebrate),
                const SizedBox(height: AppSpacing.md),
                FadeTransition(
                  opacity: CurvedAnimation(parent: _intro, curve: const Interval(0.3, 0.8)),
                  child: Column(
                    children: [
                      Text(headline, textAlign: TextAlign.center, style: AppTypography.display),
                      const SizedBox(height: AppSpacing.xs),
                      Text(subtitle, textAlign: TextAlign.center, style: AppTypography.body),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _WinnerCard(seat: winner, color: winnerColor, label: t.winner),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: _SummaryTile(icon: Icons.timer_rounded, label: t.duration, value: _formatDuration(controller.elapsed))),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _SummaryTile(icon: Icons.loop_rounded, label: t.turns, value: '$totalTurns')),
                  ],
                ),
                SectionLabel(t.standings),
                GameCard(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  shadows: null,
                  child: Column(
                    children: [
                      for (int i = 0; i < state.ranking.length; i++) ...[
                        if (i > 0) const Divider(height: 1, color: AppColors.outline),
                        _StandingRow(
                          place: i + 1,
                          seat: state.seatOf(state.ranking[i]),
                          stats: state.stats[state.ranking[i]]!,
                          home: state.pawnsHome(state.ranking[i]),
                          theme: theme,
                          strings: t,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _Trophy extends StatelessWidget {
  final AnimationController intro;
  final AnimationController loop;
  final Color color;
  final bool won;
  const _Trophy({required this.intro, required this.loop, required this.color, required this.won});

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: intro, curve: const Interval(0, 0.7, curve: Curves.elasticOut));
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (won)
            AnimatedBuilder(
              animation: loop,
              builder: (context, _) => Transform.rotate(
                angle: loop.value * math.pi * 2,
                child: CustomPaint(size: const Size.square(150), painter: _RaysPainter(color)),
              ),
            ),
          ScaleTransition(
            scale: scale,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: color, width: 4),
                boxShadow: won ? AppShadows.glow(color) : AppShadows.soft,
              ),
              child: Icon(won ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded, size: 58, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  final Color color;
  const _RaysPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..shader = RadialGradient(colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: c, radius: size.width / 2));
    for (int i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - 0.12) * size.width / 2, c.dy + math.sin(a - 0.12) * size.height / 2)
        ..lineTo(c.dx + math.cos(a + 0.12) * size.width / 2, c.dy + math.sin(a + 0.12) * size.height / 2)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.color != color;
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final BoardTheme theme;
  _ConfettiPainter(this.t, this.theme);

  static final List<(double, double, double, int)> _pieces = () {
    final r = math.Random(42);
    return [for (int i = 0; i < 46; i++) (r.nextDouble(), r.nextDouble(), 0.6 + r.nextDouble() * 0.8, r.nextInt(5))];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [theme.red, theme.green, theme.yellow, theme.blue, AppColors.gold];
    for (final (x, offset, speed, colorIndex) in _pieces) {
      final y = ((t * speed + offset) % 1.0) * (size.height + 40) - 20;
      final dx = x * size.width + math.sin((t * 6 + offset * 10) * math.pi) * 14;
      canvas.save();
      canvas.translate(dx, y);
      canvas.rotate((t * 8 + offset * 6) * math.pi);
      canvas.drawRect(
        const Rect.fromLTWH(-4, -2.5, 8, 5),
        Paint()..color = colors[colorIndex].withValues(alpha: 0.85),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

class _WinnerCard extends StatelessWidget {
  final LudoSeat seat;
  final Color color;
  final String label;
  const _WinnerCard({required this.seat, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return GameCard(
      gradient: LinearGradient(colors: [color.withValues(alpha: 0.55), AppColors.surface]),
      borderColor: color,
      borderWidth: 2.5,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
            child: Icon(seat.isBot ? Icons.smart_toy_rounded : Icons.person_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(seat.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.title),
                Text(seat.color.label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          TagPill(label, color: AppColors.gold, textColor: AppColors.onPrimary),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GameCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      shadows: null,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTypography.number.copyWith(fontSize: 20)),
                Text(label, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final int place;
  final LudoSeat seat;
  final SeatStats stats;
  final int home;
  final BoardTheme theme;
  final LudoStrings strings;

  const _StandingRow({
    required this.place,
    required this.seat,
    required this.stats,
    required this.home,
    required this.theme,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final medal = switch (place) {
      1 => AppColors.gold,
      2 => AppColors.silver,
      3 => AppColors.bronze,
      _ => AppColors.surfaceRaised,
    };
    Widget stat(IconData icon, String value, String tooltip) => Tooltip(
          message: tooltip,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 2),
            Text(value, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: medal, shape: BoxShape.circle),
            child: Text(
              '$place',
              style: AppTypography.label.copyWith(
                letterSpacing: 0,
                fontSize: 14,
                color: place <= 3 ? AppColors.textOnLight : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: theme.colorOf(seat.color),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(seat.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.subtitle)),
                  if (seat.isBot) ...[const SizedBox(width: AppSpacing.xs), TagPill(strings.bot)],
                ]),
                const SizedBox(height: 2),
                Wrap(spacing: AppSpacing.md, children: [
                  stat(Icons.home_rounded, '$home/4', strings.home),
                  stat(Icons.gps_fixed_rounded, '${stats.captures}', strings.captures),
                  stat(Icons.casino_rounded, '${stats.sixes}', strings.sixes),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
