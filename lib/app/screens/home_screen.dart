import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/navigation/app_routes.dart';
import '../../core/navigation/route_observer.dart';
import '../../core/theme/app_theme.dart';
import '../../games/game_catalog.dart';
import '../../games/game_definition.dart';
import '../../shared/widgets/game_button.dart';
import '../../shared/widgets/game_card.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/round_icon_button.dart';
import 'about_dialog.dart';

///Game launcher: the featured game front and center, upcoming games below
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, RouteAware {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  ResumableMatch? _resumable;
  bool _opening = false;

  GameDefinition get _featured => GameCatalog.featured;

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

  Widget _staggered(int index, Widget child) {
    final start = (index * 0.12).clamp(0.0, 0.6);
    final animation = CurvedAnimation(parent: _intro, curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic));
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
    return GameScaffold(
      showBack: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.xl),
        children: [
          _staggered(
            0,
            Row(
              children: [
                const _Logo(),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.homeEyebrow, style: AppTypography.label),
                      Text(s.homeGreeting, style: AppTypography.title),
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
                Row(
                  children: [
                    for (final upcoming in GameCatalog.comingSoon) ...[
                      if (upcoming != GameCatalog.comingSoon.first) const SizedBox(width: AppSpacing.md),
                      Expanded(child: _ComingSoonCard(game: upcoming)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _staggered(
            3,
            Center(
              child: TextButton.icon(
                onPressed: () => showAppAboutDialog(context),
                icon: const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textMuted),
                label: Text(s.about, style: AppTypography.caption),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    const colors = [AppColors.playerRed, AppColors.playerGreen, AppColors.playerYellow, AppColors.playerBlue];
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.mdAll,
        boxShadow: AppShadows.soft,
      ),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          for (final c in colors) DecoratedBox(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(5))),
        ],
      ),
    );
  }
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
        colors: [Color(0xFF5B3FE0), AppColors.surface],
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
                        child: Text(game.title.toUpperCase(), style: AppTypography.display.copyWith(fontSize: 44, letterSpacing: 4)),
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
                  ? GameButton(label: s.play, icon: Icons.play_arrow_rounded, onPressed: play, height: 64)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GameButton(label: s.continueMatch, icon: Icons.play_arrow_rounded, onPressed: onContinue, height: 64),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Text(resumable!.summary, textAlign: TextAlign.center, style: AppTypography.caption),
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
                  label: Text(s.howToPlay, style: AppTypography.subtitle.copyWith(fontSize: 14, color: AppColors.textSecondary)),
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
          const SizedBox(height: AppSpacing.sm),
          FittedBox(child: TagPill(s.comingSoon)),
        ],
      ),
    );
  }
}
