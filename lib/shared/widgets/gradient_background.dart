import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
        gradient: gradient ?? const LinearGradient(
          colors: [AppTheme.backgroundPrimary, AppTheme.backgroundSurface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x336C63FF), // primaryAccent with 20% opacity (0x33)
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x2600D4AA), // secondaryAccent with 15% opacity (0x26)
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
