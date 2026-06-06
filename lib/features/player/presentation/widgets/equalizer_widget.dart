import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/theme_constants.dart';

/// Interactive Equalizer Widget
/// Provides a sleek, modern interface for adjusting audio frequency bands.
class EqualizerWidget extends ConsumerStatefulWidget {
  final bool isEnabled;
  final ValueChanged<bool>? onToggle;

  const EqualizerWidget({
    super.key,
    this.isEnabled = true,
    this.onToggle,
  });

  @override
  ConsumerState<EqualizerWidget> createState() => _EqualizerWidgetState();
}

class _EqualizerWidgetState extends ConsumerState<EqualizerWidget> {
  // Common frequency bands (Hz)
  final List<String> _bands = ['60', '230', '910', '3.6k', '14k'];
  
  // Current values for each band (-15dB to +15dB)
  final List<double> _values = [0.0, 0.0, 0.0, 0.0, 0.0];
  
  // Selected preset
  String _selectedPreset = 'Normal';
  final List<String> _presets = ['Normal', 'Pop', 'Rock', 'Jazz', 'Classical', 'Bass Boost'];

  void _applyPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case 'Pop':
          _values[0] = -1.5; _values[1] = 4.0; _values[2] = 5.0; _values[3] = 2.0; _values[4] = -2.0;
          break;
        case 'Rock':
          _values[0] = 5.0; _values[1] = -3.0; _values[2] = -1.0; _values[3] = 3.0; _values[4] = 6.0;
          break;
        case 'Jazz':
          _values[0] = 4.0; _values[1] = 2.0; _values[2] = -2.0; _values[3] = 2.0; _values[4] = 5.0;
          break;
        case 'Classical':
          _values[0] = 5.0; _values[1] = 3.0; _values[2] = -2.0; _values[3] = 4.0; _values[4] = 4.0;
          break;
        case 'Bass Boost':
          _values[0] = 8.0; _values[1] = 5.0; _values[2] = 0.0; _values[3] = 0.0; _values[4] = 0.0;
          break;
        case 'Normal':
        default:
          for (int i = 0; i < _values.length; i++) _values[i] = 0.0;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                value: widget.isEnabled,
                onChanged: widget.onToggle,
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
                value: _selectedPreset,
                isExpanded: true,
                dropdownColor: ThemeConstants.cardColor,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: ThemeConstants.textSecondary),
                style: const TextStyle(color: ThemeConstants.textPrimary, fontSize: 16),
                onChanged: widget.isEnabled ? (value) {
                  if (value != null) _applyPreset(value);
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
                return _buildSlider(index);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // dB value
        Text(
          '${_values[index] > 0 ? '+' : ''}${_values[index].toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 10,
            color: widget.isEnabled ? ThemeConstants.textSecondary : ThemeConstants.textMuted,
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
                activeTrackColor: widget.isEnabled ? ThemeConstants.primaryColor : ThemeConstants.cardColorLight,
                inactiveTrackColor: ThemeConstants.backgroundColor,
                thumbColor: widget.isEnabled ? ThemeConstants.textPrimary : ThemeConstants.textMuted,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: _values[index],
                min: -15.0,
                max: 15.0,
                onChanged: widget.isEnabled ? (value) {
                  setState(() {
                    _values[index] = value;
                    _selectedPreset = 'Custom';
                  });
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
            color: widget.isEnabled ? ThemeConstants.textPrimary : ThemeConstants.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
      ].animate(delay: Duration(milliseconds: 100 + (50 * index))).slideY(begin: 0.5, end: 0).fadeIn(),
    );
  }
}
