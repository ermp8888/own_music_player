import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_music_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:my_music_app/core/providers/gemini_api_key_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel('plugins.flutter.io/path_provider')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    return '/mock/path';
  });

  group('SettingsScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget createTestableWidget(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SettingsScreen(),
          ),
        ),
      );
    }

    testWidgets('Renders Gemini API Key tile and opens dialog', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(geminiApiKeyProvider.notifier).initialization;

      await tester.pumpWidget(createTestableWidget(container));
      await tester.pumpAndSettle();

      // Scroll ListView to make sure the Gemini tile is in view
      final listFinder = find.byType(ListView);
      await tester.drag(listFinder, const Offset(0, -400));
      await tester.pumpAndSettle();

      // Check if "Gemini API Key" tile is present
      expect(find.text('Gemini API Key'), findsOneWidget);
      expect(find.text('Not configured (Tap to set)'), findsOneWidget);

      // Tap on the tile to open the API Key dialog
      await tester.tap(find.text('Gemini API Key'));
      await tester.pumpAndSettle();

      // Dialog should be open
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Get your key from Google AI Studio. This key is used for classification and mood tagging.'), findsOneWidget);

      // Enter API key
      await tester.enterText(find.byType(TextField), 'test-api-key');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Dialog should close
      expect(find.byType(AlertDialog), findsNothing);

      // Verify the value was updated
      expect(container.read(geminiApiKeyProvider), equals('test-api-key'));
    });
  });
}
