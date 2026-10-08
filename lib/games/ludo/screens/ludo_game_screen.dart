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
    while (mounted) {
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
              confirmLabel: s.restart.toUpperCase(),
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
              confirmLabel: s.quit.toUpperCase(),
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
                          title: t.title.toUpperCase(),
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
///Board with the four player corners and the turn status
class _Table extends StatelessWidget {
  final LudoController controller;
  final BoardTheme theme;
  const _Table({required this.controller, required this.theme});

  static const double _panelHeight = 64;
  static const double _gap = 10;
  static const double _statusHeight = 40;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final state = c.state;
    final t = LudoStrings.of(context);
    final selectable = c.selectablePawns;
    final seated = {for (final s in state.seats) s.color: s};

    final pawns = [
      for (final seat in state.seats)
        for (int i = 0; i < 4; i++)
          BoardPawn(
            color: seat.color,
            index: i,
            step: c.displayStep(seat.color, i),
            arrival: state.arrivals[seat.color]![i],
            selectable: seat.color == state.currentColor && selectable.contains(i),
          ),
    ];

    Widget panel(LudoColor color, {required bool mirrored}) {
      final seat = seated[color];
      if (seat == null) return const Expanded(child: SizedBox(height: _panelHeight));
      final active = !state.isFinished && state.currentColor == color;
      return Expanded(
        child: PlayerPanel(
          seat: seat,
          displayName: seat.name,
          color: theme.colorOf(color),
          active: active,
          mirrored: mirrored,
          place: state.placeOf(color),
          height: _panelHeight,
          status: _panelStatus(c, color, t),
          dice: LudoDice(
            value: state.dice,
            rolling: c.isRolling,
            canRoll: c.canRoll,
            color: theme.colorOf(color),
            onRoll: c.rollDice,
            size: _panelHeight - 14,
          ),
        ),
      );
    }

    final current = state.currentSeat;
    final turnTitle = c.isHumanTurn && c.config.mode == LudoMode.vsComputer && c.config.humanCount == 1
        ? t.yourTurn
        : t.turnOf(current.name);

    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth - AppSpacing.md * 2;
      final maxH = constraints.maxHeight - _panelHeight * 2 - _gap * 4 - _statusHeight;
      final boardSize = math.max(220.0, math.min(math.min(maxW, maxH), 620.0));
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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    LudoBoard(
                      size: boardSize,
                      theme: theme,
                      activeColors: seated.keys.toSet(),
                      turnColor: state.isFinished ? null : state.currentColor,
                      pawns: pawns,
                      stepDuration: c.pacing.step,
                      returnDuration: c.pacing.captureReturn,
                      onPawnTap: (color, pawn) => c.selectPawn(pawn),
                    ),
                    _BannerOverlay(banner: c.banner, theme: theme, seated: seated),
                  ],
                ),
                const SizedBox(height: _gap),
                Row(children: [
                  panel(LudoColor.red, mirrored: false),
                  const SizedBox(width: _gap),
                  panel(LudoColor.blue, mirrored: true),
                ]),
                const SizedBox(height: _gap),
                SizedBox(
                  height: _statusHeight,
                  child: state.isFinished
                      ? const SizedBox.shrink()
                      : TurnStatus(
                          color: theme.colorOf(current.color),
                          title: turnTitle,
                          hint: _hint(c, t),
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

  static String _panelStatus(LudoController c, LudoColor color, LudoStrings t) {
    final state = c.state;
    final place = state.placeOf(color);
    if (place != null) return '${t.finishedLabel} ${t.ordinal(place)}';
    if (state.currentColor != color || state.isFinished) return t.pawnsHome(state.pawnsHome(color));
    if (c.isRolling) return t.rolling;
    if (c.isAnimating) return t.moving;
    if (state.currentSeat.isBot) return t.botThinking;
    switch (state.phase) {
      case LudoPhase.roll:
        return t.tapDice;
      case LudoPhase.move:
        return t.pickPawn;
      case LudoPhase.turnOver:
      case LudoPhase.finished:
        return t.pawnsHome(state.pawnsHome(color));
    }
  }
}

class _BannerOverlay extends StatelessWidget {
  final LudoBanner? banner;
  final BoardTheme theme;
  final Map<LudoColor, LudoSeat> seated;
  const _BannerOverlay({required this.banner, required this.theme, required this.seated});

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
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: AppMotion.normal,
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        ),
        child: b == null
            ? const SizedBox.shrink()
            : Container(
                key: ValueKey(b.id),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.94),
                  borderRadius: AppRadius.pill,
                  border: Border.all(color: theme.colorOf(b.color), width: 2.5),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icon(b.kind), color: theme.colorOf(b.color), size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      t.banner(b, seated[b.color]?.name ?? b.color.label),
                      style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
