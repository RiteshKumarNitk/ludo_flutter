import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/dialogs/game_dialogs.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../shared/widgets/game_scaffold.dart';
import '../../../shared/widgets/round_icon_button.dart';
import '../controller/ludo_controller.dart';
import '../data/ludo_preferences.dart';
import '../ludo_routes.dart';
import '../ludo_strings.dart';
import '../models/ludo_models.dart';
import '../models/ludo_state.dart';
import '../widgets/board_theme.dart';
import '../widgets/ludo_board.dart';
import '../widgets/ludo_dice.dart';
import '../widgets/player_panel.dart';

class LudoGameScreen extends StatefulWidget {
  const LudoGameScreen({super.key});

  @override
  State<LudoGameScreen> createState() => _LudoGameScreenState();
}

class _LudoGameScreenState extends State<LudoGameScreen> with WidgetsBindingObserver {
  bool _menuOpen = false;
  Timer? _resultTimer;

  LudoController get _controller => context.read<LudoController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resultTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //Freeze the match whenever the app leaves the foreground
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden || state == AppLifecycleState.inactive) {
      if (_controller.hasMatch && !_controller.isFinished && !_menuOpen) _openPauseMenu();
    }
  }

  Future<void> _openPauseMenu() async {
    final controller = _controller;
    if (_menuOpen || !controller.hasMatch || controller.isFinished) return;
    final s = AppStrings.of(context);
    _menuOpen = true;
    controller.pause();
    while (true) {
      if (!mounted) return;
      final action = await showPauseMenu(context);
      if (!mounted) return;
      switch (action) {
        case PauseAction.resume:
          _menuOpen = false;
          controller.resume();
          return;
        case PauseAction.settings:
          await Navigator.of(context).pushNamed(AppRoutes.settings);
          continue;
        case PauseAction.restart:
          final ok = await showConfirmDialog(context,
              title: s.restartTitle,
              message: s.restartBody,
              confirmLabel: s.restart,
              icon: Icons.refresh_rounded,
              destructive: true);
          if (!ok || !mounted) continue;
          _menuOpen = false;
          controller.restart();
          return;
        case PauseAction.quit:
          final ok = await showConfirmDialog(context,
              title: s.quitTitle,
              message: s.quitBody,
              confirmLabel: s.quit,
              icon: Icons.logout_rounded,
              destructive: true);
          if (!ok || !mounted) continue;
          _menuOpen = false;
          await controller.quit();
          if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
          return;
      }
    }
  }

  Future<void> _confirmLeave() async {
    final controller = _controller;
    if (_menuOpen || !controller.hasMatch || controller.isFinished) return;
    final t = LudoStrings.of(context);
    _menuOpen = true;
    controller.pause();
    final leave = await showConfirmDialog(context,
        title: t.leaveTitle,
        message: t.leaveBody,
        confirmLabel: t.leaveGame,
        cancelLabel: t.continueGame,
        icon: Icons.exit_to_app_rounded);
    _menuOpen = false;
    if (!mounted) return;
    if (!leave) {
      controller.resume();
      return;
    }
    await controller.leave();
    if (mounted) Navigator.of(context).pop();
  }

  void _maybeShowResult(LudoController c) {
    if (_resultTimer != null || !c.hasMatch || !c.isFinished || c.isAnimating) return;
    _resultTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) Navigator.of(context).pushReplacementNamed(LudoRoutes.result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<LudoController>();
    final prefs = context.watch<LudoPreferences>();
    final t = LudoStrings.of(context);
    final s = AppStrings.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundBottom,
        body: GameBackground(
          child: SafeArea(
            child: !c.hasMatch
                ? const SizedBox.shrink()
                : Builder(builder: (context) {
                    _maybeShowResult(c);
                    return Column(
                      children: [
                        _TopBar(
                          title: t.title,
                          subtitle: t.modeName(c.config.mode),
                          onPause: _openPauseMenu,
                          pauseTooltip: t.pause,
                          backTooltip: s.back,
                          onBack: _confirmLeave,
                        ),
                        Expanded(child: _Table(controller: c, theme: prefs.theme)),
                      ],
                    );
                  }),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onPause;
  final VoidCallback onBack;
  final String pauseTooltip;
  final String backTooltip;

  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.onPause,
    required this.onBack,
    required this.pauseTooltip,
    required this.backTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          RoundIconButton(icon: Icons.arrow_back_rounded, tooltip: backTooltip, onPressed: onBack, size: 44),
          Expanded(
            child: Column(
              children: [
                Text(title, style: AppTypography.title.copyWith(letterSpacing: 3)),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          RoundIconButton(icon: Icons.pause_rounded, tooltip: pauseTooltip, onPressed: onPause, size: 44),
        ],
      ),
    );
  }
}

///Board with the four player corners and the turn status. Panel, dice and
///board sizes adapt to the space so tall phones get a bigger dice instead
///of empty bands, and small phones keep the whole board visible.
class _Table extends StatelessWidget {
  final LudoController controller;
  final BoardTheme theme;
  const _Table({required this.controller, required this.theme});

  static const double _gap = 10;
  static const double _statusHeight = 46;
  static const double _rim = 6;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final state = c.state;
    final t = LudoStrings.of(context);
    final selectable = c.selectablePawns;
    final seated = {for (final s in state.seats) s.color: s};
    final choosing = selectable.isNotEmpty;

    final pawns = [
      for (final seat in state.seats)
        for (int i = 0; i < 4; i++)
          BoardPawn(
            color: seat.color,
            index: i,
            step: c.displayStep(seat.color, i),
            arrival: state.arrivals[seat.color]![i],
            selectable: seat.color == state.currentColor && selectable.contains(i),
            //While choosing, the mover's pawns that cannot move step back visually
            dimmed: choosing && seat.color == state.currentColor && !selectable.contains(i),
          ),
    ];

    final current = state.currentSeat;
    final turnTitle = c.isHumanTurn && c.config.mode == LudoMode.vsComputer && c.config.humanCount == 1
        ? t.yourTurn
        : t.turnOf(current.name);

    return LayoutBuilder(builder: (context, constraints) {
      final maxW = math.min(constraints.maxWidth - AppSpacing.md * 2, 620.0);
      final spare = constraints.maxHeight - maxW - _statusHeight - _gap * 4;
      final panelHeight = (spare / 2).clamp(60.0, 92.0);
      final maxH = constraints.maxHeight - panelHeight * 2 - _gap * 4 - _statusHeight;
      final boardSize = math.max(220.0, math.min(maxW, maxH));

      Widget panel(LudoColor color, {required bool mirrored}) {
        final seat = seated[color];
        if (seat == null) return Expanded(child: SizedBox(height: panelHeight));
        final steps = state.stepsOf(color);
        return Expanded(
          child: PlayerPanel(
            seat: seat,
            displayName: seat.name,
            color: theme.colorOf(color),
            active: !state.isFinished && state.currentColor == color,
            mirrored: mirrored,
            place: state.placeOf(color),
            height: panelHeight,
            progress: PawnProgress(
              home: steps.where((s) => s == 56).length,
              onBoard: steps.where((s) => s >= 0 && s < 56).length,
            ),
            placeLabel: state.placeOf(color) == null ? null : '${t.finishedLabel} ${t.ordinal(state.placeOf(color)!)}',
            dice: LudoDice(
              value: state.dice,
              rolling: c.isRolling,
              canRoll: c.canRoll,
              color: theme.colorOf(color),
              onRoll: c.rollDice,
              size: panelHeight - 14,
            ),
          ),
        );
      }

      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: boardSize,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  panel(LudoColor.green, mirrored: false),
                  const SizedBox(width: _gap),
                  panel(LudoColor.yellow, mirrored: true),
                ]),
                const SizedBox(height: _gap),
                //Raised frame around the painted board
                Container(
                  padding: const EdgeInsets.all(_rim),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(boardSize / 15 * 0.9 + _rim),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.surfaceRaised, AppColors.surfaceSunken],
                    ),
                    border: Border.all(color: AppColors.outline, width: 1.5),
                    boxShadow: AppShadows.board,
                  ),
                  child: LudoBoard(
                    size: boardSize - _rim * 2,
                    theme: theme,
                    activeColors: seated.keys.toSet(),
                    turnColor: state.isFinished ? null : state.currentColor,
                    pawns: pawns,
                    stepDuration: c.pacing.step,
                    returnDuration: c.pacing.captureReturn,
                    onPawnTap: (color, pawn) => c.selectPawn(pawn),
                  ),
                ),
                const SizedBox(height: _gap),
                Row(children: [
                  panel(LudoColor.red, mirrored: false),
                  const SizedBox(width: _gap),
                  panel(LudoColor.blue, mirrored: true),
                ]),
                const SizedBox(height: _gap),
                //Turn status, briefly replaced by event banners (six, capture,
                //extra roll...) so no announcement ever covers the board
                SizedBox(
                  height: _statusHeight,
                  child: AnimatedSwitcher(
                    duration: AppMotion.normal,
                    switchInCurve: Curves.easeOutBack,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: c.banner != null
                        ? _EventBanner(key: ValueKey(c.banner!.id), banner: c.banner!, theme: theme, seated: seated)
                        : state.isFinished
                            ? const SizedBox.shrink()
                            : TurnStatus(
                                key: const ValueKey('status'),
                                color: theme.colorOf(current.color),
                                title: turnTitle,
                                hint: _hint(c, t),
                              ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  static String _hint(LudoController c, LudoStrings t) {
    final state = c.state;
    if (c.isPaused) return t.paused;
    if (c.isRolling) return t.rolling;
    if (c.isAnimating) return t.moving;
    if (state.currentSeat.isBot) return t.thinking(state.currentSeat.name);
    switch (state.phase) {
      case LudoPhase.roll:
        return t.tapDice;
      case LudoPhase.move:
        return c.selectablePawns.length > 1 ? t.pickPawn : t.moving;
      case LudoPhase.turnOver:
      case LudoPhase.finished:
        return t.passing;
    }
  }

}

///Short announcement (six, capture, extra roll, ...) shown in the status slot
class _EventBanner extends StatelessWidget {
  final LudoBanner banner;
  final BoardTheme theme;
  final Map<LudoColor, LudoSeat> seated;
  const _EventBanner({super.key, required this.banner, required this.theme, required this.seated});

  IconData _icon(LudoBannerKind kind) {
    switch (kind) {
      case LudoBannerKind.sixRollAgain:
      case LudoBannerKind.extraRoll:
        return Icons.replay_rounded;
      case LudoBannerKind.captured:
        return Icons.gps_fixed_rounded;
      case LudoBannerKind.threeSixes:
        return Icons.block_rounded;
      case LudoBannerKind.noMove:
        return Icons.do_not_disturb_alt_rounded;
      case LudoBannerKind.playerFinished:
        return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = banner;
    final t = LudoStrings.of(context);
    final color = theme.colorOf(b.color);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.4), AppColors.surface]),
          borderRadius: AppRadius.pill,
          border: Border.all(color: color, width: 2.5),
          boxShadow: AppShadows.glow(color, strength: 0.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon(b.kind), color: AppColors.lighten(color, 0.3), size: 22),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                t.banner(b, seated[b.color]?.name ?? b.color.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
