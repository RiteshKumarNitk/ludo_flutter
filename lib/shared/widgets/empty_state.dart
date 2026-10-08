import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'game_button.dart';

///Friendly placeholder for screens without content yet
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.outline, width: 2),
                boxShadow: AppShadows.glow(AppColors.secondary, strength: 0.6),
              ),
              child: Icon(icon, size: 52, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(title, style: AppTypography.title, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppTypography.body, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 240,
                child: GameButton(label: actionLabel!, icon: Icons.play_arrow_rounded, onPressed: onAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
