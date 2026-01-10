import 'package:flutter/material.dart';
import '../../core/constants/theme_constants.dart';

/// Gradient background widget
class GradientBackground extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final List<Widget>? overlays;

  const GradientBackground({
    super.key,
    required this.child,
    this.gradient,
    this.overlays,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? ThemeConstants.backgroundGradient,
      ),
      child: Stack(
        children: [
          // Background decorative elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ThemeConstants.primaryColor.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ThemeConstants.accentColor.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          if (overlays != null) ...overlays!,
          child,
        ],
      ),
    );
  }
}
