import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../services/filter_pipeline.dart';

/// Provider for the filter settings state.
final filterSettingsProvider =
    StateNotifierProvider<FilterSettingsNotifier, FilterSettings>((ref) {
  return FilterSettingsNotifier();
});

/// Notifier for managing filter settings saved in SharedPreferences.
class FilterSettingsNotifier extends StateNotifier<FilterSettings> {
  late final Future<void> initialization;

  FilterSettingsNotifier() : super(const FilterSettings()) {
    initialization = _loadSettings();
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final blockDevotional = prefs.getBool(AppConstants.filterDevotionalKey) ?? true;
    final blockKaraoke = prefs.getBool(AppConstants.filterKaraokeKey) ?? true;
    final blockRemixes = prefs.getBool(AppConstants.filterRemixesKey) ?? false;
    final blockInstrumentals = prefs.getBool(AppConstants.filterInstrumentalsKey) ?? false;
    final blockShorts = prefs.getBool(AppConstants.filterShortsKey) ?? true;

    if (mounted) {
      state = FilterSettings(
        blockDevotional: blockDevotional,
        blockKaraoke: blockKaraoke,
        blockRemixes: blockRemixes,
        blockInstrumentals: blockInstrumentals,
        blockShorts: blockShorts,
      );
    }
  }

  /// Toggle the devotional content filter
  Future<void> toggleDevotional(bool value) async {
    state = FilterSettings(
      blockDevotional: value,
      blockKaraoke: state.blockKaraoke,
      blockRemixes: state.blockRemixes,
      blockInstrumentals: state.blockInstrumentals,
      blockShorts: state.blockShorts,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.filterDevotionalKey, value);
  }

  /// Toggle the karaoke content filter
  Future<void> toggleKaraoke(bool value) async {
    state = FilterSettings(
      blockDevotional: state.blockDevotional,
      blockKaraoke: value,
      blockRemixes: state.blockRemixes,
      blockInstrumentals: state.blockInstrumentals,
      blockShorts: state.blockShorts,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.filterKaraokeKey, value);
  }

  /// Toggle the remixes content filter
  Future<void> toggleRemixes(bool value) async {
    state = FilterSettings(
      blockDevotional: state.blockDevotional,
      blockKaraoke: state.blockKaraoke,
      blockRemixes: value,
      blockInstrumentals: state.blockInstrumentals,
      blockShorts: state.blockShorts,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.filterRemixesKey, value);
  }

  /// Toggle the instrumentals content filter
  Future<void> toggleInstrumentals(bool value) async {
    state = FilterSettings(
      blockDevotional: state.blockDevotional,
      blockKaraoke: state.blockKaraoke,
      blockRemixes: state.blockRemixes,
      blockInstrumentals: value,
      blockShorts: state.blockShorts,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.filterInstrumentalsKey, value);
  }

  /// Toggle the shorts content filter
  Future<void> toggleShorts(bool value) async {
    state = FilterSettings(
      blockDevotional: state.blockDevotional,
      blockKaraoke: state.blockKaraoke,
      blockRemixes: state.blockRemixes,
      blockInstrumentals: state.blockInstrumentals,
      blockShorts: value,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.filterShortsKey, value);
  }
}
