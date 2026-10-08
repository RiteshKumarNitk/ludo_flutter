import 'package:flutter/material.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/game_config.dart';
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
  final Map<LudoPlayerType, TextEditingController> _names = {};
  final Set<LudoPlayerType> _cpu = {LudoPlayerType.yellow, LudoPlayerType.blue, LudoPlayerType.red};

  @override
  void initState() {
    super.initState();
    _extraRollOnSix = context.read<SettingsProvider>().extraRollOnSix;
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
    );
    context.read<LudoProvider>().startGame(config);
    Navigator.of(context).pushNamed('/game');
  }

  @override
  Widget build(BuildContext context) {
    final colors = GameConfig.colorsFor(_playerCount);
    return Scaffold(
      appBar: AppBar(title: const Text('New Game'), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            const _SectionTitle('Players'),
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
            const _SectionTitle('Rules'),
            SwitchListTile(
              value: _extraRollOnSix,
              onChanged: (value) => setState(() => _extraRollOnSix = value),
              title: const Text('Extra roll on 6'),
              subtitle: const Text('Roll the dice again after throwing a 6'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Game'),
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
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: 'Player name',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (isTurnFirst)
              const Tooltip(
                message: 'Goes first',
                child: Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('CPU', style: TextStyle(fontSize: 11)),
                Switch(value: isCpu, onChanged: onChanged, activeThumbColor: _color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
