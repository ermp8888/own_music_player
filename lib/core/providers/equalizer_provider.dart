import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_handler.dart';
import '../../features/player/presentation/providers/player_provider.dart';

class EqualizerSettings {
  final bool enabled;
  final String preset;
  final List<double> bands;

  const EqualizerSettings({
    this.enabled = false,
    this.preset = 'Normal',
    this.bands = const [0.0, 0.0, 0.0, 0.0, 0.0],
  });

  EqualizerSettings copyWith({
    bool? enabled,
    String? preset,
    List<double>? bands,
  }) {
    return EqualizerSettings(
      enabled: enabled ?? this.enabled,
      preset: preset ?? this.preset,
      bands: bands ?? this.bands,
    );
  }
}

class EqualizerNotifier extends StateNotifier<EqualizerSettings> {
  final Ref _ref;

  EqualizerNotifier(this._ref) : super(const EqualizerSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('eq_enabled') ?? false;
    final preset = prefs.getString('eq_preset') ?? 'Normal';
    final bandsString = prefs.getStringList('eq_bands');

    List<double> bands = const [0.0, 0.0, 0.0, 0.0, 0.0];
    if (bandsString != null && bandsString.length == 5) {
      bands = bandsString.map((s) => double.tryParse(s) ?? 0.0).toList();
    } else if (preset != 'Custom') {
      bands = getPresetBands(preset);
    }

    state = EqualizerSettings(
      enabled: enabled,
      preset: preset,
      bands: bands,
    );

    // Apply to audio handler after the next frame to ensure player is initialized
    Future.microtask(() => _applyToAudioHandler());
  }

  static List<double> getPresetBands(String preset) {
    switch (preset) {
      case 'Pop':
        return [-1.5, 4.0, 5.0, 2.0, -2.0];
      case 'Rock':
        return [5.0, -3.0, -1.0, 3.0, 6.0];
      case 'Jazz':
        return [4.0, 2.0, -2.0, 2.0, 5.0];
      case 'Classical':
        return [5.0, 3.0, -2.0, 4.0, 4.0];
      case 'Bass Boost':
        return [8.0, 5.0, 0.0, 0.0, 0.0];
      case 'Normal':
      default:
        return [0.0, 0.0, 0.0, 0.0, 0.0];
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('eq_enabled', enabled);
    _applyToAudioHandler();
  }

  Future<void> setPreset(String preset) async {
    final bands = getPresetBands(preset);
    state = state.copyWith(preset: preset, bands: bands);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('eq_preset', preset);
    await prefs.setStringList('eq_bands', bands.map((d) => d.toString()).toList());
    
    _applyToAudioHandler();
  }

  Future<void> setBandGain(int index, double gain) async {
    if (index < 0 || index >= state.bands.length) return;
    
    final newBands = List<double>.from(state.bands);
    newBands[index] = gain;
    
    state = state.copyWith(preset: 'Custom', bands: newBands);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('eq_preset', 'Custom');
    await prefs.setStringList('eq_bands', newBands.map((d) => d.toString()).toList());
    
    _applyToAudioHandler();
  }

  void _applyToAudioHandler() {
    final handler = _ref.read(audioHandlerProvider);
    if (handler is MyAudioHandler) {
      handler.setEqualizerEnabled(state.enabled);
      for (int i = 0; i < state.bands.length; i++) {
        handler.setEqualizerBandGain(i, state.bands[i]);
      }
    }
  }
}

final equalizerProvider = StateNotifierProvider<EqualizerNotifier, EqualizerSettings>((ref) {
  return EqualizerNotifier(ref);
});
