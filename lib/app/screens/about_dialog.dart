import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/dialogs/game_dialogs.dart';
import '../../shared/widgets/game_button.dart';
import '../app.dart';

///App, developer and privacy information, plus the open-source licenses
///of the packages the app ships with
Future<void> showAppAboutDialog(BuildContext context) {
  final s = AppStrings.of(context);
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (dialogContext) => GameDialog(
      icon: Icons.casino_rounded,
      title: '${s.appName} · ${s.version(appVersion)}',
      message: s.aboutBody,
      actions: [
        _InfoCard(
          children: [
            Text(s.developedBy, style: AppTypography.label),
            const SizedBox(height: AppSpacing.xs),
            Text(s.companyName, style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.sm),
            _ContactRow(icon: Icons.language_rounded, text: s.companyWebsite),
            _ContactRow(icon: Icons.mail_outline_rounded, text: s.companyEmail),
            _ContactRow(icon: Icons.call_outlined, text: s.companyPhone),
            _ContactRow(icon: Icons.place_outlined, text: s.companyAddress),
          ],
        ),
        _InfoCard(
          children: [
            Row(children: [
              const Icon(Icons.shield_outlined, size: 18, color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(s.privacyTitle, style: AppTypography.subtitle)),
            ]),
            const SizedBox(height: AppSpacing.xs),
            Text(s.privacyBody, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
        GameButton(
          label: s.openSourceLicenses,
          variant: GameButtonVariant.ghost,
          height: 50,
          onPressed: () => showLicensePage(
            context: dialogContext,
            applicationName: s.appName,
            applicationVersion: appVersion,
            applicationLegalese: s.legalese(DateTime.now().year),
          ),
        ),
        GameButton(label: s.close, onPressed: () => Navigator.of(dialogContext).pop()),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SelectableText(text, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
