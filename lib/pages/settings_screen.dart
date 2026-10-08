import 'package:flutter/material.dart';
import 'package:ludo_flutter/board_theme.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/l10n/app_strings.dart';
import 'package:ludo_flutter/settings_provider.dart';
import 'package:provider/provider.dart';

///Global preferences, persisted between sessions
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final s = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.settings), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SwitchListTile(
              value: settings.sound,
              onChanged: settings.setSound,
              title: Text(s.soundEffects),
              subtitle: Text(s.soundEffectsHint),
            ),
            SwitchListTile(
              value: settings.haptics,
              onChanged: settings.setHaptics,
              title: Text(s.hapticFeedback),
              subtitle: Text(s.hapticFeedbackHint),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                s.animationSpeed,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            RadioGroup<double>(
              groupValue: settings.animationSpeed,
              onChanged: (value) => settings.setAnimationSpeed(value ?? 1.0),
              child: Column(
                children: [
                  RadioListTile<double>(value: 0.6, title: Text(s.speedSlow)),
                  RadioListTile<double>(value: 1.0, title: Text(s.speedNormal)),
                  RadioListTile<double>(value: 1.6, title: Text(s.speedFast)),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                s.boardTheme,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            SegmentedButton<BoardThemeType>(
              segments: [
                for (final type in BoardThemeType.values)
                  ButtonSegment<BoardThemeType>(value: type, label: Text(type.label)),
              ],
              selected: <BoardThemeType>{settings.boardTheme},
              onSelectionChanged: (selection) => settings.setBoardTheme(selection.first),
            ),
            const SizedBox(height: 8),
            const Divider(),
            SwitchListTile(
              value: settings.extraRollOnSix,
              onChanged: settings.setExtraRollOnSix,
              title: Text(s.extraRollOnSix),
              subtitle: Text(s.defaultRuleHint),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => settings.reset(),
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(s.resetToDefaults),
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
