import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/branding/khelora_mark.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/navigation/route_observer.dart';
import '../../core/theme/app_theme.dart';
import '../../games/game_catalog.dart';
import '../../games/game_definition.dart';
import '../../shared/dialogs/game_dialogs.dart';
import '../../shared/widgets/game_button.dart';
import '../../shared/widgets/game_card.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/round_icon_button.dart';
import 'about_dialog.dart';

///Khelora launcher: brand header, the featured game front and center,
///upcoming games below. Android Back asks before leaving the app.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, RouteAware {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..forward();

  ///Slow ambient loop for the logo breathing and the drifting tiles
  late final AnimationController _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 12))
    ..repeat();
  ResumableMatch? _resumable;
  bool _opening = false;
  bool _exitDialogOpen = false;

  GameDefinition get _featured => GameCatalog.featured;

  ///Closing the app from inside is an Android convention only
  static bool get _canExit => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() => _refresh();

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final find = _featured.findResumable;
    if (find == null) return;
    final found = await find(context);
    if (mounted) setState(() => _resumable = found);
  }

  Future<void> _continue() async {
    if (_opening) return;
    _opening = true;
    final ok = await _featured.resume!(context);
    _opening = false;
    if (!ok) _refresh();
  }

  ///Saved matches are untouched: Continue is still there next launch
  Future<void> _confirmExit() async {
    if (_exitDialogOpen) return;
    _exitDialogOpen = true;
    final s = AppStrings.of(context);
    final exit = await showExitDialog(
      context,
      title: s.exitTitle,
      message: s.exitBody,
      stayLabel: s.stay,
      exitLabel: s.exitButton,
    );
    _exitDialogOpen = false;
    if (exit) await SystemNavigator.pop();
  }

  Widget _staggered(int index, Widget child) {
    final start = (index * 0.12).clamp(0.0, 0.6);
    final animation = CurvedAnimation(
        parent: _intro, curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final game = _featured;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundBottom,
        body: GameBackground(
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _ambient,
                      builder: (context, _) => CustomPaint(painter: _DriftingTilesPainter(_ambient.value)),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: ListView(
                  padding:
                      const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xl),
                  children: [
                    _staggered(
                      0,
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _ambient,
                            builder: (context, child) => Transform.scale(
                              scale: 1 + 0.04 * math.sin(_ambient.value * 2 * math.pi * 3),
                              child: child,
                            ),
                            child: const KheloraMark(size: 52, ringColor: AppColors.backgroundTop),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: KheloraWordmark(fontSize: 28),
                                ),
                                const SizedBox(height: 2),
                                Text(s.tagline, maxLines: 1, style: AppTypography.caption.copyWith(letterSpacing: 0.6)),
                              ],
                            ),
                          ),
                          if (game.recordsRoute != null)
                            RoundIconButton(
                              icon: Icons.emoji_events_rounded,
                              color: AppColors.gold,
                              tooltip: s.records,
                              onPressed: () => Navigator.of(context).pushNamed(game.recordsRoute!),
                            ),
                          const SizedBox(width: AppSpacing.sm),
                          RoundIconButton(
                            icon: Icons.settings_rounded,
                            tooltip: s.settings,
                            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _staggered(1, _FeaturedCard(game: game, resumable: _resumable, onContinue: _continue)),
                    const SizedBox(height: AppSpacing.sm),
                    _staggered(
                      2,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionLabel(s.moreGames),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final upcoming in GameCatalog.comingSoon) ...[
                                  if (upcoming != GameCatalog.comingSoon.first) const SizedBox(width: AppSpacing.md),
                                  Expanded(child: _ComingSoonCard(game: upcoming)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _staggered(
                      3,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _FooterLink(
                            icon: Icons.info_outline_rounded,
                            label: s.about,
                            onTap: () => showAppAboutDialog(context),
                          ),
                          if (_canExit) ...[
                            const SizedBox(width: AppSpacing.md),
                            _FooterLink(icon: Icons.logout_rounded, label: s.exit, onTap: _confirmExit),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

///Small outlined pill for secondary launcher actions (About, Exit)
class _FooterLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FooterLink({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GameCard(
      onTap: onTap,
      shadows: null,
      borderRadius: AppRadius.pill,
      color: AppColors.surface.withValues(alpha: 0.6),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTypography.subtitle.copyWith(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

///Faint brand tiles drifting slowly behind the launcher content
class _DriftingTilesPainter extends CustomPainter {
  final double t;
  _DriftingTilesPainter(this.t);

  static final List<(double, double, double, double, int)> _tiles = () {
    final r = math.Random(5);
    return [
      for (int i = 0; i < 9; i++) (r.nextDouble(), r.nextDouble(), 26 + r.nextDouble() * 34, r.nextDouble(), i % 4),
    ];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    for (final (x, y, side, phase, colorIndex) in _tiles) {
      final a = (t + phase) * 2 * math.pi;
      final center = Offset(
        x * size.width + math.sin(a) * 18,
        ((y + t * 0.15) % 1.0) * (size.height + side * 2) - side,
      );
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(math.pi / 4 + math.sin(a) * 0.3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: side, height: side), Radius.circular(side * 0.22)),
        Paint()..color = KheloraColors.tiles[colorIndex].withValues(alpha: 0.07),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_DriftingTilesPainter old) => old.t != t;
}

class _FeaturedCard extends StatelessWidget {
  final GameDefinition game;
  final ResumableMatch? resumable;
  final VoidCallback onContinue;

  const _FeaturedCard({required this.game, required this.resumable, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    void play() => Navigator.of(context).pushNamed(game.playRoute!);
    return GameCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.xlAll,
      borderColor: AppColors.secondary.withValues(alpha: 0.7),
      borderWidth: 2,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2B4183), AppColors.surface],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final art = (constraints.maxWidth * 0.46).clamp(120.0, 190.0);
            return SizedBox(
              height: art + AppSpacing.xl,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: AppSpacing.lg,
                    top: AppSpacing.xl,
                    right: art + AppSpacing.sm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TagPill('FEATURED', color: AppColors.primary, textColor: AppColors.onPrimary),
                        const SizedBox(height: AppSpacing.sm),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(game.title.toUpperCase(),
                              style: AppTypography.display.copyWith(fontSize: 44, letterSpacing: 4)),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(game.tagline, style: AppTypography.body),
                      ],
                    ),
                  ),
                  if (game.artwork != null)
                    Positioned(right: AppSpacing.sm, top: AppSpacing.lg, child: game.artwork!(context, art)),
                ],
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: AnimatedSize(
              duration: AppMotion.normal,
              child: resumable == null
                  ? GameButton(label: s.play, icon: Icons.play_arrow_rounded, onPressed: play, height: 64, shine: true)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GameButton(
                            label: s.continueMatch, icon: Icons.play_arrow_rounded, onPressed: onContinue, height: 64, shine: true),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(child: _SavedMatchChip(match: resumable!)),
                        ),
                        GameButton(
                          label: s.newMatch.toUpperCase(),
                          icon: Icons.add_rounded,
                          variant: GameButtonVariant.ghost,
                          onPressed: play,
                          height: 52,
                        ),
                      ],
                    ),
            ),
          ),
          if (game.howToPlayRoute != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(game.howToPlayRoute!),
                  icon: const Icon(Icons.menu_book_rounded, size: 18, color: AppColors.textSecondary),
                  label: Text(s.howToPlay,
                      style: AppTypography.subtitle.copyWith(fontSize: 14, color: AppColors.textSecondary)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  final GameDefinition game;
  const _ComingSoonCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return GameCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      color: AppColors.surface.withValues(alpha: 0.6),
      shadows: null,
      onTap: () => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.comingSoonMessage(game.title)))),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(shape: BoxShape.circle, color: game.accent.withValues(alpha: 0.18)),
            child: Icon(game.icon, color: game.accent.withValues(alpha: 0.8), size: 26),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            game.title,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: AppTypography.subtitle.copyWith(fontSize: 13, color: AppColors.textSecondary),
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(child: TagPill(s.comingSoon)),
        ],
      ),
    );
  }
}

///Compact description of the saved match: its seat colors and summary
class _SavedMatchChip extends StatelessWidget {
  final ResumableMatch match;
  const _SavedMatchChip({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken.withValues(alpha: 0.6),
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bookmark_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          for (final c in match.markers)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.2)),
            ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              match.summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
