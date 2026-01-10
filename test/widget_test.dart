// Basic smoke test for MyMusicApp

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_music_app/main.dart';

void main() {
  testWidgets('App should render home screen', (WidgetTester tester) async {
    // Build the app with ProviderScope (required for Riverpod)
    await tester.pumpWidget(
      const ProviderScope(
        child: MyMusicApp(),
      ),
    );

    // Verify app title is displayed
    expect(find.text('MyMusicApp'), findsOneWidget);
  });
}
