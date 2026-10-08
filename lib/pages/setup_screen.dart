import 'package:flutter/material.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/game_config.dart';
import 'package:ludo_flutter/l10n/app_strings.dart';
import 'package:ludo_flutter/ludo_provider.dart';
import 'package:ludo_flutter/settings_provider.dart';
import 'package:provider/provider.dart';

///Match configuration: player count, names, CPU flags and rules
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _playerCount = 4;
  late bool _extraRollOnSix;
  late bool _captureGrantsRoll;
  late bool _threeSixesForfeit;
  late bool _exactFinish;
  late bool _blocking;
  late CpuDifficulty _cpuDifficulty;
  final Map<LudoPlayerType, TextEditingController> _names = {};
  final Set<LudoPlayerType> _cpu = {LudoPlayerType.yellow, LudoPlayerType.blue, LudoPlayerType.red};

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _extraRollOnSix = settings.extraRollOnSix;
    _cpuDifficulty = settings.cpuDifficulty;
    _captureGrantsRoll = true;
    _threeSixesForfeit = false;
    _exactFinish = true;
    _blocking = false;
    for (final color in LudoPlayerType.values) {
      _names[color] = TextEditingController(text: GameConfig.defaultName(color));
    }
  }

  @override
  void dispose() {
    for (final controller in _names.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startGame() {
    final colors = GameConfig.colorsFor(_playerCount);
    final config = GameConfig(
      players: [
        for (final color in colors)
          PlayerSetup(
            color: color,
            name: _names[color]!.text.trim().isEmpty
                ? GameConfig.defaultName(color)
                : _names[color]!.text.trim(),
            isCpu: _cpu.contains(color),
          ),
      ],
      extraRollOnSix: _extraRollOnSix,
      captureGrantsRoll: _captureGrantsRoll,
      threeSixesForfeit: _threeSixesForfeit,
      exactFinish: _exactFinish,
      blocking: _blocking,
      cpuDifficulty: _cpuDifficulty,
    );
    //Remember the difficulty as the default for the next match
    context.read<SettingsProvider>().setCpuDifficulty(_cpuDifficulty);
    context.read<LudoProvider>().startGame(config);
    Navigator.of(context).pushNamed('/game');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = GameConfig.colorsFor(_playerCount);
    return Scaffold(
      appBar: AppBar(title: Text(s.newGame), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _SectionTitle(s.players),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
                ButtonSegment(value: 4, label: Text('4')),
              ],
              selected: {_playerCount},
              onSelectionChanged: (value) => setState(() => _playerCount = value.first),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < colors.length; i++)
              _PlayerTile(
                color: colors[i],
                nameController: _names[colors[i]]!,
                isCpu: _cpu.contains(colors[i]),
                isTurnFirst: i == 0,
                onChanged: (isCpu) {
                  setState(() {
                    if (isCpu) {
                      _cpu.add(colors[i]);
                    } else {
                      _cpu.remove(colors[i]);
                    }
                  });
                },
              ),
            const SizedBox(height: 16),
            _SectionTitle(s.rules),
            SwitchListTile(
              value: _extraRollOnSix,
              onChanged: (value) => setState(() => _extraRollOnSix = value),
              title: Text(s.extraRollOnSix),
              subtitle: Text(s.extraRollOnSixHint),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _captureGrantsRoll,
              onChanged: (value) => setState(() => _captureGrantsRoll = value),
              title: Text(s.extraRollOnCapture),
              subtitle: Text(s.extraRollOnCaptureHint),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _threeSixesForfeit,
              onChanged: (value) => setState(() => _threeSixesForfeit = value),
              title: Text(s.threeSixesForfeit),
              subtitle: Text(s.threeSixesForfeitHint),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _exactFinish,
              onChanged: (value) => setState(() => _exactFinish = value),
              title: Text(s.exactFinish),
              subtitle: Text(s.exactFinishHint),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: _blocking,
              onChanged: (value) => setState(() => _blocking = value),
              title: Text(s.blocking),
              subtitle: Text(s.blockingHint),
              contentPadding: EdgeInsets.zero,
            ),
            if (colors.any((color) => _cpu.contains(color))) ...[
              const SizedBox(height: 8),
              _SectionTitle(s.cpuDifficulty),
              SegmentedButton<CpuDifficulty>(
                segments: [
                  ButtonSegment(
                    value: CpuDifficulty.easy,
                    label: Text(s.difficultyEasy),
                    icon: const Icon(Icons.sentiment_satisfied_alt_rounded),
                  ),
                  ButtonSegment(
                    value: CpuDifficulty.medium,
                    label: Text(s.difficultyMedium),
                    icon: const Icon(Icons.sentiment_neutral_rounded),
                  ),
                  ButtonSegment(
                    value: CpuDifficulty.hard,
                    label: Text(s.difficultyHard),
                    icon: const Icon(Icons.local_fire_department_rounded),
                  ),
                ],
                selected: {_cpuDifficulty},
                onSelectionChanged: (value) =>
                    setState(() => _cpuDifficulty = value.first),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    s.difficultyHint,
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(s.startGame),
              style: FilledButton.styleFrom(
                backgroundColor: LudoColor.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final LudoPlayerType color;
  final TextEditingController nameController;
  final bool isCpu;
  final bool isTurnFirst;
  final ValueChanged<bool> onChanged;

  const _PlayerTile({
    required this.color,
    required this.nameController,
    required this.isCpu,
    required this.isTurnFirst,
    required this.onChanged,
  });

  Color get _color {
    switch (color) {
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
    final s = AppStrings.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: nameController,
                maxLength: 12,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: s.playerName,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (isTurnFirst)
              Tooltip(
                message: s.goesFirst,
                child: const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.cpu, style: const TextStyle(fontSize: 11)),
                Switch(value: isCpu, onChanged: onChanged, activeThumbColor: _color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
