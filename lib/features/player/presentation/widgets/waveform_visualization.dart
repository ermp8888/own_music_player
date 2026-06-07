import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Animated waveform visualization widget that syncs with music playback
class WaveformVisualization extends StatefulWidget {
  final bool isPlaying;
  final double progress; // 0.0 to 1.0
  final Color? activeColor;
  final Color? inactiveColor;
  final int barCount;
  final double height;

  const WaveformVisualization({
    super.key,
    required this.isPlaying,
    required this.progress,
    this.activeColor,
    this.inactiveColor,
    this.barCount = 50,
    this.height = 60,
  });

  @override
  State<WaveformVisualization> createState() => _WaveformVisualizationState();
}

class _WaveformVisualizationState extends State<WaveformVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<double> _barHeights;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateBarHeights();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        if (widget.isPlaying && mounted) {
          setState(() {
            _updateBarHeights();
          });
        }
      });

    if (widget.isPlaying) {
      _animationController.repeat();
    }
  }

  void _generateBarHeights() {
    // Generate random heights that look like a waveform
    // Using abs() and clamping to ensure always positive
    _barHeights = List.generate(widget.barCount, (index) {
      // Create wave-like pattern using absolute value to avoid negatives
      final waveValue = sin(index * 0.3).abs(); // 0 to 1
      final baseHeight = 0.2 + 0.3 * waveValue;  // 0.2 to 0.5
      final variation = _random.nextDouble() * 0.3; // 0 to 0.3
      return (baseHeight + variation).clamp(0.15, 1.0); // Ensure minimum 0.15
    });
  }

  void _updateBarHeights() {
    // Animate bars near the current progress marker
    for (int i = 0; i < _barHeights.length; i++) {
      final barProgress = i / _barHeights.length;
      final distanceFromProgress = (barProgress - widget.progress).abs();
      
      if (distanceFromProgress < 0.1) {
        // Bars near playback position animate more
        _barHeights[i] = (0.4 + _random.nextDouble() * 0.6).clamp(0.15, 1.0);
      } else {
        // Slowly return to base height
        final waveValue = sin(i * 0.3).abs();
        final baseHeight = 0.2 + 0.3 * waveValue;
        _barHeights[i] = ((_barHeights[i] + baseHeight) / 2).clamp(0.15, 1.0);
      }
    }
  }

  @override
  void didUpdateWidget(WaveformVisualization oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _animationController.repeat();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppTheme.primaryAccent;
    final inactiveColor = widget.inactiveColor ?? AppTheme.divider;

    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (index) {
          final barProgress = index / widget.barCount;
          final isActive = barProgress <= widget.progress;
          // Ensure height is always positive with minimum of 4 pixels
          final height = (_barHeights[index] * widget.height).clamp(4.0, widget.height);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 3,
            height: height,
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

/// Simple static waveform for mini player
class MiniWaveform extends StatelessWidget {
  final double progress;
  final Color? activeColor;
  final Color? inactiveColor;

  const MiniWaveform({
    super.key,
    required this.progress,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 80,
      child: CustomPaint(
        painter: _WaveformPainter(
          progress: progress,
          activeColor: activeColor ?? AppTheme.primaryAccent,
          inactiveColor: inactiveColor ?? AppTheme.divider,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 20;
    final barWidth = size.width / barCount - 1;
    final random = Random(42); // Fixed seed for consistent pattern

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + 1);
      final barProgress = i / barCount;
      final isActive = barProgress <= progress;
      
      // Generate wave-like pattern
      final baseHeight = 0.3 + 0.5 * sin(i * 0.4);
      final variation = random.nextDouble() * 0.2;
      final height = (baseHeight + variation) * size.height;
      final y = (size.height - height) / 2;

      final paint = Paint()
        ..color = isActive ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, height),
          const Radius.circular(1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
