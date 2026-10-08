import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/game_button.dart';

///Dialog frame matching the design system
class GameDialog extends StatelessWidget {
  final IconData? icon;
  final Color iconColor;
  final String title;
  final String? message;
  final List<Widget> actions;

  const GameDialog({
    super.key,
    this.icon,
    this.iconColor = AppColors.primary,
    required this.title,
    this.message,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.xlAll,
            border: Border.all(color: AppColors.outline, width: 2),
            boxShadow: AppShadows.card,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor.withValues(alpha: 0.16),
                    ),
                    child: Icon(icon, color: iconColor, size: 34),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text(title, style: AppTypography.title, textAlign: TextAlign.center),
                if (message != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(message!, style: AppTypography.body, textAlign: TextAlign.center),
                ],
                const SizedBox(height: AppSpacing.xl),
                for (int i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  actions[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

///Asks the player to confirm an action. Resolves to true only when the
///confirm button is pressed. Destructive confirmations cannot be dismissed
///by tapping outside, so a stray tap never triggers or skips them silently.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  IconData icon = Icons.help_outline_rounded,
  bool destructive = false,
}) async {
  final s = AppStrings.of(context);
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: !destructive,
    barrierColor: AppColors.scrim,
    builder: (context) => GameDialog(
      icon: icon,
      iconColor: destructive ? AppColors.danger : AppColors.primary,
      title: title,
      message: message,
      actions: [
        GameButton(
          label: cancelLabel ?? s.cancel,
          variant: GameButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        GameButton(
          label: confirmLabel,
          variant: destructive ? GameButtonVariant.danger : GameButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

enum PauseAction { resume, restart, settings, quit }

///Pause menu for any running match. Tapping outside simply resumes.
Future<PauseAction> showPauseMenu(BuildContext context) async {
  final s = AppStrings.of(context);
  final result = await showDialog<PauseAction>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (context) => GameDialog(
      icon: Icons.pause_rounded,
      title: s.paused,
      actions: [
        GameButton(
          label: s.resume,
          icon: Icons.play_arrow_rounded,
          onPressed: () => Navigator.of(context).pop(PauseAction.resume),
        ),
        GameButton(
          label: s.restart.toUpperCase(),
          icon: Icons.refresh_rounded,
          variant: GameButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(PauseAction.restart),
        ),
        GameButton(
          label: s.settings.toUpperCase(),
          icon: Icons.tune_rounded,
          variant: GameButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(PauseAction.settings),
        ),
        GameButton(
          label: s.quit.toUpperCase(),
          icon: Icons.logout_rounded,
          variant: GameButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(PauseAction.quit),
        ),
      ],
    ),
  );
  return result ?? PauseAction.resume;
}
