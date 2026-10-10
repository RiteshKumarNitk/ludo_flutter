import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../games/game_catalog.dart';
import '../../shared/dialogs/game_dialogs.dart';
import '../../shared/widgets/game_button.dart';
import '../../shared/widgets/game_card.dart';
import '../../shared/widgets/game_scaffold.dart';
import '../../shared/widgets/segmented_choice.dart';
import 'about_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final s = AppStrings.of(context);
    final ok = await showConfirmDialog(context,
        title: s.resetSettingsTitle,
        message: s.resetSettingsBody,
        confirmLabel: s.reset,
        icon: Icons.restart_alt_rounded,
        destructive: true);
    if (!ok || !context.mounted) return;
    await context.read<AppSettings>().reset();
    for (final game in GameCatalog.available) {
      if (!context.mounted) return;
      await game.resetSettings?.call(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final settings = context.watch<AppSettings>();
    return GameScaffold(
      title: s.settings,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xl),
        children: [
          SectionLabel(s.general),
          GameCard(
            shadows: null,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SwitchRow(
                  icon: Icons.volume_up_rounded,
                  title: s.sound,
                  hint: s.soundHint,
                  value: settings.sound,
                  onChanged: settings.setSound,
                ),
                const Divider(height: 1, color: AppColors.outline),
                _SwitchRow(
                  icon: Icons.vibration_rounded,
                  title: s.vibration,
                  hint: s.vibrationHint,
                  value: settings.haptics,
                  onChanged: settings.setHaptics,
                ),
                const Divider(height: 1, color: AppColors.outline),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.speed_rounded, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.md),
                        Text(s.gameSpeed, style: AppTypography.subtitle),
                      ]),
                      const SizedBox(height: AppSpacing.md),
                      SegmentedChoice<GameSpeed>(
                        height: 46,
                        options: [
                          ChoiceOption(GameSpeed.normal, s.speedNormal),
                          ChoiceOption(GameSpeed.fast, s.speedFast),
                        ],
                        selected: settings.speed,
                        onChanged: settings.setSpeed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final game in GameCatalog.available)
            if (game.settingsSection != null) game.settingsSection!(context),
          const SizedBox(height: AppSpacing.xl),
          GameButton(
            label: s.resetSettings,
            icon: Icons.restart_alt_rounded,
            variant: GameButtonVariant.ghost,
            onPressed: () => _confirmReset(context),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: TextButton.icon(
              onPressed: () => showAppAboutDialog(context),
              icon: const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textMuted),
              label: Text(s.about, style: AppTypography.caption),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({required this.icon, required this.title, required this.hint, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.subtitle),
                    Text(hint, style: AppTypography.caption),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
