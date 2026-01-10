import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Fade and slide animation for entry effects
class FadeSlideAnimation extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final int index;

  const FadeSlideAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.offset = const Offset(0, 20),
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay + Duration(milliseconds: index * 100))
        .fadeIn(duration: duration)
        .slideY(
          begin: offset.dy / 100,
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}
