import 'package:flutter/material.dart';

import 'app_colors.dart';

///Type scale. Heavy, rounded-feeling weights for a playful game voice.
class AppTypography {
  const AppTypography._();

  static const TextStyle display = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w900,
    letterSpacing: 2,
    height: 1.05,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    letterSpacing: 0.5,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textMuted,
  );

  ///Small uppercase section/eyebrow labels
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.6,
    color: AppColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
  );

  static const TextStyle number = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w900,
    height: 1.0,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
