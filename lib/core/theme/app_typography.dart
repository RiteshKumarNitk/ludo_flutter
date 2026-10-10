import 'package:flutter/painting.dart';

import 'app_colors.dart';

///Type scale. Baloo 2 for titles, names, numbers and buttons; Hind for body
///text, labels and settings. Sentence case everywhere.
///
///Baloo 2 ships as a variable font, so each Baloo style also sets the 'wght'
///axis. Use [weight] to change the weight of an existing Baloo style.
class AppTypography {
  const AppTypography._();

  static const String displayFamily = 'Baloo2';
  static const String textFamily = 'Hind';

  static const _w700 = [FontVariation('wght', 700)];
  static const _w800 = [FontVariation('wght', 800)];

  ///Same style at another weight (keeps Baloo's variable axis in sync)
  static TextStyle weight(TextStyle style, FontWeight weight) => style.copyWith(
        fontWeight: weight,
        fontVariations: style.fontFamily == displayFamily ? [FontVariation('wght', weight.value.toDouble())] : null,
      );

  static const TextStyle display = TextStyle(
    fontFamily: displayFamily,
    fontSize: 44,
    fontWeight: FontWeight.w800,
    fontVariations: _w800,
    height: 1.0,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: displayFamily,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    fontVariations: _w800,
    height: 1.05,
    color: AppColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontFamily: displayFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontVariations: _w700,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: displayFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    fontVariations: _w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: textFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: textFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.textMuted,
  );

  ///Section labels above groups of controls (sentence case, no caps)
  static const TextStyle label = TextStyle(
    fontFamily: textFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: displayFamily,
    fontSize: 19,
    fontWeight: FontWeight.w800,
    fontVariations: _w800,
    height: 1.0,
  );

  static const TextStyle number = TextStyle(
    fontFamily: displayFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    fontVariations: _w800,
    height: 1.0,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
