import 'package:flutter/material.dart';
import 'package:ludo_flutter/constants.dart';
import 'package:ludo_flutter/l10n/app_strings.dart';

enum PauseAction { resume, restart, settings, quit }

///Modal pause menu shown while a match is running
Future<PauseAction?> showPauseMenu(BuildContext context) {
  final s = AppStrings.of(context);
  return showDialog<PauseAction>(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      title: Text(s.paused, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PauseButton(
            label: s.resume,
            icon: Icons.play_arrow_rounded,
            color: LudoColor.green,
            action: PauseAction.resume,
          ),
          _PauseButton(
            label: s.restart,
            icon: Icons.refresh_rounded,
            color: LudoColor.yellow,
            action: PauseAction.restart,
          ),
          _PauseButton(
            label: s.settings,
            icon: Icons.settings_outlined,
            color: LudoColor.blue,
            action: PauseAction.settings,
          ),
          _PauseButton(
            label: s.quitToMenu,
            icon: Icons.logout_rounded,
            color: LudoColor.red,
            action: PauseAction.quit,
          ),
        ],
      ),
    ),
  );
}

class _PauseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final PauseAction action;

  const _PauseButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).pop(action),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
