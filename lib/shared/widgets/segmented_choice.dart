import 'package:flutter/material.dart';

import '../../core/audio/sound_effects.dart';
import '../../core/theme/app_theme.dart';

class ChoiceOption<T> {
  final T value;
  final String label;
  final IconData? icon;
  const ChoiceOption(this.value, this.label, {this.icon});
}

///Pill-shaped segmented control with a sliding highlight
class SegmentedChoice<T> extends StatelessWidget {
  final List<ChoiceOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;

  const SegmentedChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final index = options.indexWhere((o) => o.value == selected);
    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.outline, width: 1.5),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth / options.length;
        return Stack(
          children: [
            AnimatedPositioned(
              duration: AppMotion.normal,
              curve: Curves.easeOutBack,
              left: width * (index < 0 ? 0 : index),
              top: 0,
              bottom: 0,
              width: width,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.pill,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.lighten(AppColors.primary, 0.2), AppColors.primary],
                  ),
                  boxShadow: AppShadows.soft,
                ),
              ),
            ),
            Row(
              children: [
                for (final option in options)
                  Expanded(
                    child: Semantics(
                      selected: option.value == selected,
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (option.value == selected) return;
                          SoundEffects.play(Sfx.tap);
                          onChanged(option.value);
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: AppMotion.fast,
                            style: DefaultTextStyle.of(context).style.merge(AppTypography.subtitle).copyWith(
                              fontWeight: FontWeight.w900,
                              color: option.value == selected ? AppColors.onPrimary : AppColors.textSecondary,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (option.icon != null) ...[
                                  Icon(
                                    option.icon,
                                    size: 18,
                                    color: option.value == selected ? AppColors.onPrimary : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                ],
                                Flexible(child: Text(option.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
