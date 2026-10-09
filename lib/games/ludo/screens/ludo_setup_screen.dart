import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/dialogs/game_dialogs.dart';
import '../../../shared/widgets/game_button.dart';
import '../../../shared/widgets/game_card.dart';
import '../../../shared/widgets/game_scaffold.dart';
import '../../../shared/widgets/round_icon_button.dart';
import '../../../shared/widgets/segmented_choice.dart';
import '../controller/ludo_controller.dart';
import '../data/ludo_preferences.dart';
import '../ludo_routes.dart';
import '../ludo_strings.dart';
import '../models/ludo_models.dart';

///Who is playing: player count, mode, bot difficulty and the seats.
///The rules are fixed and never shown here.
class LudoSetupScreen extends StatefulWidget {
  const LudoSetupScreen({super.key});

  @override
  State<LudoSetupScreen> createState() => _LudoSetupScreenState();
}

class _LudoSetupScreenState extends State<LudoSetupScreen> {
  late int _players;
  late LudoMode _mode;
  late BotDifficulty _difficulty;

  ///Extra human seats in vs-computer mode (seat index > 0)
  final Set<int> _extraHumans = {};

  ///Custom names by seat index; missing means the default name
  final Map<int, String> _names = {};
  bool _hasSavedMatch = false;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<LudoPreferences>();
    _players = prefs.playerCount;
    _mode = prefs.mode;
    _difficulty = prefs.difficulty;
    context.read<LudoController>().store.load().then((saved) {
      if (mounted) setState(() => _hasSavedMatch = saved != null);
    });
  }

  List<LudoColor> get _colors => LudoMatchConfig.colorsFor(_players);

  bool _isBot(int seat) => _mode == LudoMode.vsComputer && seat > 0 && !_extraHumans.contains(seat);

  int get _botCount => [
        for (int i = 0; i < _players; i++)
          if (_isBot(i)) i
      ].length;

  String _defaultName(int seat, LudoStrings t) {
    if (_isBot(seat)) return t.botName(_colors[seat]);
    if (_mode == LudoMode.vsComputer && seat == 0) return t.you;
    return t.playerN(seat + 1);
  }

  String _nameOf(int seat, LudoStrings t) =>
      _isBot(seat) ? _defaultName(seat, t) : (_names[seat] ?? _defaultName(seat, t));

  LudoMatchConfig _buildConfig(LudoStrings t) => LudoMatchConfig(
        mode: _botCount == 0 ? LudoMode.passAndPlay : _mode,
        difficulty: _difficulty,
        seats: [
          for (int i = 0; i < _players; i++) LudoSeat(color: _colors[i], name: _nameOf(i, t), isBot: _isBot(i)),
        ],
      );

  void _toggleSeat(int seat) {
    setState(() {
      if (_extraHumans.contains(seat)) {
        _extraHumans.remove(seat);
      } else if (_botCount > 1) {
        _extraHumans.add(seat); //keep at least one bot in vs-computer mode
      }
    });
  }

  Future<void> _rename(int seat) async {
    final t = LudoStrings.of(context);
    final s = AppStrings.of(context);
    final controller = TextEditingController(text: _names[seat] ?? '');
    final result = await showDialog<String>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (context) => GameDialog(
        icon: Icons.edit_rounded,
        title: t.renameTitle,
        actions: [
          TextField(
            controller: controller,
            autofocus: true,
            maxLength: 12,
            textCapitalization: TextCapitalization.words,
            style: AppTypography.subtitle,
            decoration: InputDecoration(hintText: _defaultName(seat, t), counterText: ''),
            onSubmitted: (v) => Navigator.of(context).pop(v),
          ),
          GameButton(label: t.save, onPressed: () => Navigator.of(context).pop(controller.text)),
          GameButton(label: s.cancel, variant: GameButtonVariant.ghost, onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    setState(() {
      final name = result.trim();
      if (name.isEmpty) {
        _names.remove(seat);
      } else {
        _names[seat] = name;
      }
    });
  }

  Future<void> _start() async {
    final t = LudoStrings.of(context);
    if (_hasSavedMatch) {
      final ok = await showConfirmDialog(context,
          title: t.replaceSavedTitle,
          message: t.replaceSavedBody,
          confirmLabel: t.startNew,
          icon: Icons.warning_amber_rounded,
          destructive: true);
      if (!ok || !mounted) return;
    }
    context.read<LudoPreferences>().rememberSetup(players: _players, mode: _mode, difficulty: _difficulty);
    context.read<LudoController>().startMatch(_buildConfig(t));
    Navigator.of(context).pushReplacementNamed(LudoRoutes.game);
  }

  @override
  Widget build(BuildContext context) {
    final t = LudoStrings.of(context);
    final s = AppStrings.of(context);
    final theme = context.watch<LudoPreferences>().theme;

    return GameScaffold(
      title: t.setupTitle,
      actions: [
        RoundIconButton(
          icon: Icons.help_outline_rounded,
          tooltip: s.howToPlay,
          onPressed: () => Navigator.of(context).pushNamed(LudoRoutes.howToPlay),
        ),
      ],
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.lg),
        child: GameButton(label: t.startGame, icon: Icons.play_arrow_rounded, onPressed: _start),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.lg),
        children: [
          SectionLabel(t.playersLabel),
          Row(
            children: [
              for (final n in const [2, 3, 4]) ...[
                if (n != 2) const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ChoiceCard(
                    selected: _players == n,
                    onTap: () => setState(() {
                      _players = n;
                      _extraHumans.removeWhere((i) => i >= n);
                    }),
                    child: Column(
                      children: [
                        Text('$n', style: AppTypography.headline.copyWith(fontSize: 34)),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final c in LudoMatchConfig.colorsFor(n))
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(color: theme.colorOf(c), shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          SectionLabel(t.modeLabel),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ModeCard(
                    selected: _mode == LudoMode.vsComputer,
                    icon: Icons.smart_toy_rounded,
                    accent: AppColors.secondary,
                    title: t.vsComputer,
                    hint: t.vsComputerHint,
                    onTap: () => setState(() => _mode = LudoMode.vsComputer),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _ModeCard(
                    selected: _mode == LudoMode.passAndPlay,
                    icon: Icons.groups_rounded,
                    accent: AppColors.playerGreen,
                    title: t.passAndPlay,
                    hint: t.passAndPlayHint,
                    onTap: () => setState(() => _mode = LudoMode.passAndPlay),
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: AppMotion.normal,
            curve: Curves.easeOut,
            child: _mode != LudoMode.vsComputer
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionLabel(t.difficultyLabel),
                      SegmentedChoice<BotDifficulty>(
                        options: [
                          ChoiceOption(BotDifficulty.easy, t.easy),
                          ChoiceOption(BotDifficulty.medium, t.medium),
                          ChoiceOption(BotDifficulty.hard, t.hard),
                        ],
                        selected: _difficulty,
                        onChanged: (d) => setState(() => _difficulty = d),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xs),
                        child: Text(t.difficultyHint(_difficulty), style: AppTypography.caption),
                      ),
                    ],
                  ),
          ),
          SectionLabel(t.seatsLabel),
          GameCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            shadows: null,
            child: Column(
              children: [
                for (int i = 0; i < _players; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.outline),
                  _SeatRow(
                    color: theme.colorOf(_colors[i]),
                    name: _nameOf(i, t),
                    isBot: _isBot(i),
                    goesFirst: i == 0,
                    goesFirstLabel: t.goesFirst,
                    canRename: !_isBot(i),
                    onRename: () => _rename(i),
                    toggle: _mode == LudoMode.vsComputer && i > 0
                        ? _SeatToggle(
                            isBot: _isBot(i),
                            humanLabel: t.human,
                            botLabel: t.bot,
                            enabled: !_isBot(i) || _botCount > 1,
                            onTap: () => _toggleSeat(i),
                          )
                        : null,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.xs),
            child: Text(
              _mode == LudoMode.vsComputer ? '${t.tapToRename} · ${t.tapSeatToggle}' : t.tapToRename,
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  const _ChoiceCard({required this.selected, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: AnimatedScale(
        duration: AppMotion.fast,
        scale: selected ? 1 : 0.97,
        child: GameCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
          color: selected ? AppColors.surfaceRaised : AppColors.surface,
          borderColor: selected ? AppColors.primary : AppColors.outline,
          borderWidth: selected ? 2.5 : 1.5,
          shadows: selected ? AppShadows.glow(AppColors.primary, strength: 0.5) : null,
          child: child,
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final Color accent;
  final String title;
  final String hint;
  final VoidCallback onTap;

  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.accent,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ChoiceCard(
      selected: selected,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: selected ? 0.3 : 0.14),
              border: Border.all(color: accent.withValues(alpha: selected ? 0.9 : 0.35), width: 2),
            ),
            child: Icon(icon, size: 28, color: selected ? AppColors.textPrimary : accent),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title,
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(color: AppColors.textPrimary, fontSize: 13)),
          const SizedBox(height: AppSpacing.xxs),
          Text(hint, textAlign: TextAlign.center, maxLines: 2, style: AppTypography.caption.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _SeatRow extends StatelessWidget {
  final Color color;
  final String name;
  final bool isBot;
  final bool goesFirst;
  final String goesFirstLabel;
  final bool canRename;
  final VoidCallback onRename;
  final Widget? toggle;

  const _SeatRow({
    required this.color,
    required this.name,
    required this.isBot,
    required this.goesFirst,
    required this.goesFirstLabel,
    required this.canRename,
    required this.onRename,
    this.toggle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(isBot ? Icons.smart_toy_rounded : Icons.person_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: InkWell(
              borderRadius: AppRadius.smAll,
              onTap: canRename ? onRename : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.subtitle),
                    ),
                    if (canRename) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(Icons.edit_rounded, size: 15, color: AppColors.textMuted),
                    ],
                    if (goesFirst) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Tooltip(
                        message: goesFirstLabel,
                        child: const Icon(Icons.flag_rounded, size: 16, color: AppColors.primary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (toggle != null) toggle!,
        ],
      ),
    );
  }
}

class _SeatToggle extends StatelessWidget {
  final bool isBot;
  final String humanLabel;
  final String botLabel;
  final bool enabled;
  final VoidCallback onTap;

  const _SeatToggle({
    required this.isBot,
    required this.humanLabel,
    required this.botLabel,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget part(String label, bool on) => AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: on ? AppColors.primary : Colors.transparent,
            borderRadius: AppRadius.pill,
          ),
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              fontSize: 11,
              letterSpacing: 0.6,
              color: on ? AppColors.onPrimary : AppColors.textMuted,
            ),
          ),
        );
    return Semantics(
      button: true,
      toggled: isBot,
      label: isBot ? botLabel : humanLabel,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surfaceSunken,
              borderRadius: AppRadius.pill,
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [part(humanLabel, !isBot), part(botLabel, isBot)]),
          ),
        ),
      ),
    );
  }
}
