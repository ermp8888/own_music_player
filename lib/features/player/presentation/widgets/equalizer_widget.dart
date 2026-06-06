import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../core/providers/equalizer_provider.dart';

/// Interactive Equalizer Widget
/// Provides a sleek, modern interface for adjusting audio frequency bands.
class EqualizerWidget extends ConsumerStatefulWidget {
  const EqualizerWidget({super.key});

  @override
  ConsumerState<EqualizerWidget> createState() => _EqualizerWidgetState();
}

class _EqualizerWidgetState extends ConsumerState<EqualizerWidget> {
  // Common frequency bands (Hz)
  final List<String> _bands = ['60', '230', '910', '3.6k', '14k'];
  
  final List<String> _presets = ['Normal', 'Pop', 'Rock', 'Jazz', 'Classical', 'Bass Boost', 'Custom'];

  @override
  Widget build(BuildContext context) {
    final eqSettings = ref.watch(equalizerProvider);
    final eqNotifier = ref.read(equalizerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ThemeConstants.cardColor,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.equalizer_rounded, color: ThemeConstants.primaryColor),
                  SizedBox(width: 12),
                  Text(
                    'Equalizer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ThemeConstants.textPrimary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: eqSettings.enabled,
                onChanged: (value) => eqNotifier.setEnabled(value),
                activeColor: ThemeConstants.primaryColor,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Presets Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: ThemeConstants.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: eqSettings.preset,
                isExpanded: true,
                dropdownColor: ThemeConstants.cardColor,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: ThemeConstants.textSecondary),
                style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 16),
                onChanged: eqSettings.enabled ? (value) {
                  if (value != null) eqNotifier.setPreset(value);
                } : null,
                items: _presets.map((preset) {
                  return DropdownMenuItem<String>(
                    value: preset,
                    child: Text(preset),
                  );
                }).toList(),
              ),
            ),
          ).animate().fadeIn(delay: 100.ms),
          
          const SizedBox(height: 32),
          
          // Sliders
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_bands.length, (index) {
                return _buildSlider(index, eqSettings, eqNotifier);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(int index, EqualizerSettings eqSettings, EqualizerNotifier eqNotifier) {
    final value = eqSettings.bands[index];
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // dB value
        Text(
          '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 10,
            color: eqSettings.enabled ? ThemeConstants.textSecondary : ThemeConstants.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Vertical Slider
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: eqSettings.enabled ? ThemeConstants.primaryColor : ThemeConstants.cardColorLight,
                inactiveTrackColor: ThemeConstants.backgroundColor,
                thumbColor: eqSettings.enabled ? ThemeConstants.textPrimary : ThemeConstants.textMuted,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: value,
                min: -15.0,
                max: 15.0,
                onChanged: eqSettings.enabled ? (val) {
                  eqNotifier.setBandGain(index, val);
                } : null,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Band label
        Text(
          _bands[index],
          style: TextStyle(
            fontSize: 12,
            color: eqSettings.enabled ? ThemeConstants.textPrimary : ThemeConstants.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ].animate(delay: Duration(milliseconds: 100 + (50 * index))).slideY(begin: 0.5, end: 0).fadeIn(),
    );
  }
}
