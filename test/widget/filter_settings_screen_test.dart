import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_music_app/features/settings/presentation/screens/filter_settings_screen.dart';
import 'package:my_music_app/core/providers/filter_settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FilterSettingsScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget createTestableWidget(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: FilterSettingsScreen(),
        ),
      );
    }

    testWidgets('Renders all filter settings options correctly', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(filterSettingsProvider.notifier).initialization;

      await tester.pumpWidget(createTestableWidget(container));
      await tester.pumpAndSettle();

      // Check header title
      expect(find.text('Content Filtering'), findsOneWidget);
      expect(find.text('Smart Shield'), findsOneWidget);

      // Check default filters
      expect(find.text('Block Devotional Content'), findsOneWidget);
      expect(find.text('Block Karaoke & Covers'), findsOneWidget);
      expect(find.text('Block Shorts & Clips'), findsOneWidget);

      // Check optional filters
      expect(find.text('Block Remixes'), findsOneWidget);
      expect(find.text('Block Instrumentals'), findsOneWidget);
    });

    testWidgets('Toggling a switch updates UI state and provider', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(filterSettingsProvider.notifier).initialization;

      await tester.pumpWidget(createTestableWidget(container));
      await tester.pumpAndSettle();

      // Initial states (blockDevotional is true by default, blockRemixes is false by default)
      expect(container.read(filterSettingsProvider).blockDevotional, isTrue);
      expect(container.read(filterSettingsProvider).blockRemixes, isFalse);

      // Tap on Block Remixes switch
      final remixTile = find.ancestor(
        of: find.text('Block Remixes'),
        matching: find.byType(ListTile),
      );
      expect(remixTile, findsOneWidget);

      final switchFinder = find.descendant(
        of: remixTile,
        matching: find.byType(Switch),
      );
      expect(switchFinder, findsOneWidget);

      // Tap switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verify state has toggled to true
      expect(container.read(filterSettingsProvider).blockRemixes, isTrue);
    });
  });
}
