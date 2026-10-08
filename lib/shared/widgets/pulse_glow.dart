import 'package:flutter/material.dart';

///Expanding, fading rings behind [child]. Replaces the old ripple package
///with one lightweight controller.
class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final bool active;

  ///Ring radius as a multiple of the child's shortest side
  final double spread;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  const PulseGlow({
    super.key,
    required this.child,
    required this.color,
    this.active = true,
    this.spread = 0.35,
    this.shape = BoxShape.circle,
    this.borderRadius,
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(PulseGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return LayoutBuilder(builder: (context, constraints) {
      final side = constraints.biggest.shortestSide.isFinite ? constraints.biggest.shortestSide : 48.0;
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (final delay in const [0.0, 0.5])
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = (_controller.value + delay) % 1.0;
                final grow = side * widget.spread * t;
                return Positioned(
                  left: -grow,
                  right: -grow,
                  top: -grow,
                  bottom: -grow,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: widget.shape,
                        borderRadius: widget.shape == BoxShape.rectangle ? widget.borderRadius : null,
                        border: Border.all(color: widget.color.withValues(alpha: (1 - t) * 0.8), width: 3),
                      ),
                    ),
                  ),
                );
              },
            ),
          widget.child,
        ],
      );
    });
  }
}
