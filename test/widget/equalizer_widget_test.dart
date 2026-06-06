import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_music_app/features/player/presentation/widgets/equalizer_widget.dart';
import 'package:my_music_app/core/providers/equalizer_provider.dart';
import 'package:my_music_app/features/player/presentation/providers/player_provider.dart';
import 'package:my_music_app/core/services/audio_handler.dart';

class FakeAudioHandler extends Fake implements MyAudioHandler {
  bool equalizerEnabled = false;
  final Map<int, double> bandGains = {};

  @override
  Future<void> setEqualizerEnabled(bool enabled) async {
    equalizerEnabled = enabled;
  }

  @override
  Future<void> setEqualizerBandGain(int index, double gain) async {
    bandGains[index] = gain;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EqualizerWidget Widget Tests', () {
    late FakeAudioHandler fakeAudioHandler;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeAudioHandler = FakeAudioHandler();
    });

    Widget createTestableWidget(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EqualizerWidget(),
            ),
          ),
        ),
      );
    }

    testWidgets('Renders EqualizerWidget components correctly', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          audioHandlerProvider.overrideWithValue(fakeAudioHandler),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestableWidget(container));
      await tester.pumpAndSettle();

      // Check header title and icon
      expect(find.text('Equalizer'), findsOneWidget);
      expect(find.byIcon(Icons.equalizer_rounded), findsOneWidget);

      // Check presets dropdown default text (Normal)
      expect(find.text('Normal'), findsOneWidget);

      // Verify that switch is off by default
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isFalse);
    });

    testWidgets('Toggling switch updates provider state', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          audioHandlerProvider.overrideWithValue(fakeAudioHandler),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestableWidget(container));
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      
      // Tap switch to enable equalizer
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verify provider state updated
      expect(container.read(equalizerProvider).enabled, isTrue);
      expect(fakeAudioHandler.equalizerEnabled, isTrue);

      // Tap switch to disable equalizer again
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(container.read(equalizerProvider).enabled, isFalse);
      expect(fakeAudioHandler.equalizerEnabled, isFalse);
    });
  });
}
