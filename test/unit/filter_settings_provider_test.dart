import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_music_app/core/providers/filter_settings_provider.dart';
import 'package:my_music_app/core/constants/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FilterSettingsNotifier Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes with default values when no preferences exist', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for initialization to complete
      await container.read(filterSettingsProvider.notifier).initialization;

      final settings = container.read(filterSettingsProvider);

      expect(settings.blockDevotional, isTrue);
      expect(settings.blockKaraoke, isTrue);
      expect(settings.blockRemixes, isFalse);
      expect(settings.blockInstrumentals, isFalse);
      expect(settings.blockShorts, isTrue);
    });

    test('Initializes with stored values when preferences exist', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.filterDevotionalKey: false,
        AppConstants.filterKaraokeKey: false,
        AppConstants.filterRemixesKey: true,
        AppConstants.filterInstrumentalsKey: true,
        AppConstants.filterShortsKey: false,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for initialization to complete
      await container.read(filterSettingsProvider.notifier).initialization;

      final settings = container.read(filterSettingsProvider);

      expect(settings.blockDevotional, isFalse);
      expect(settings.blockKaraoke, isFalse);
      expect(settings.blockRemixes, isTrue);
      expect(settings.blockInstrumentals, isTrue);
      expect(settings.blockShorts, isFalse);
    });

    test('Toggling updates state and persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(filterSettingsProvider.notifier);
      await notifier.initialization;

      // Toggle devotional to false
      await notifier.toggleDevotional(false);
      expect(container.read(filterSettingsProvider).blockDevotional, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppConstants.filterDevotionalKey), isFalse);

      // Toggle remixes to true
      await notifier.toggleRemixes(true);
      expect(container.read(filterSettingsProvider).blockRemixes, isTrue);
      expect(prefs.getBool(AppConstants.filterRemixesKey), isTrue);
    });
  });
}
