import 'package:flutter/material.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/settings_provider.dart';
import 'package:provider/provider.dart';

///Global preferences, persisted between sessions
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SwitchListTile(
              value: settings.sound,
              onChanged: settings.setSound,
              title: const Text('Sound effects'),
              subtitle: const Text('Dice, pawn movement and capture sounds'),
            ),
            SwitchListTile(
              value: settings.haptics,
              onChanged: settings.setHaptics,
              title: const Text('Haptic feedback'),
              subtitle: const Text('Vibrate when rolling and capturing'),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Animation speed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            RadioGroup<double>(
              groupValue: settings.animationSpeed,
              onChanged: (value) => settings.setAnimationSpeed(value ?? 1.0),
              child: const Column(
                children: [
                  RadioListTile<double>(value: 0.6, title: Text('Slow')),
                  RadioListTile<double>(value: 1.0, title: Text('Normal')),
                  RadioListTile<double>(value: 1.6, title: Text('Fast')),
                ],
              ),
            ),
            const Divider(),
            SwitchListTile(
              value: settings.extraRollOnSix,
              onChanged: settings.setExtraRollOnSix,
              title: const Text('Extra roll on 6'),
              subtitle: const Text('Default rule for new matches'),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => settings.reset(),
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset to defaults'),
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
