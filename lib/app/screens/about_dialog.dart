import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/dialogs/game_dialogs.dart';
import '../../shared/widgets/game_button.dart';
import '../app.dart';

Future<void> showAppAboutDialog(BuildContext context) {
  final s = AppStrings.of(context);
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.scrim,
    builder: (context) => GameDialog(
      icon: Icons.casino_rounded,
      title: '${s.appName} · ${s.version(appVersion)}',
      message: '${s.aboutBody}\n\n${s.aboutCredit}',
      actions: [
        GameButton(label: s.close, variant: GameButtonVariant.ghost, onPressed: () => Navigator.of(context).pop()),
      ],
    ),
  );
}
