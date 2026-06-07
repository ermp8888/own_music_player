import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts_base;
import 'package:my_music_app/core/theme/app_theme.dart';

class MockAssetManifest implements AssetManifest {
  @override
  List<String> listAssets() {
    return [
      'google_fonts/PlusJakartaSans-Regular.ttf',
      'google_fonts/PlusJakartaSans-Bold.ttf',
      'google_fonts/PlusJakartaSans-SemiBold.ttf',
      'google_fonts/PlusJakartaSans-Medium.ttf',
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    google_fonts_base.assetManifest = MockAssetManifest();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        // Return 100 dummy bytes of zero
        return ByteData(100);
      },
    );
  });

  test('Plus Jakarta Sans is registered in theme', () {
    final theme = AppTheme.darkTheme;
    expect(
      theme.textTheme.bodyLarge?.fontFamily,
      contains('PlusJakartaSans'),
    );
  });

  test('Display style is 28sp Bold', () {
    final style = AppTheme.displayLarge;
    expect(style.fontSize, 28.0);
    expect(style.fontWeight, FontWeight.bold);
  });

  test('Caption style is 11sp Regular', () {
    final style = AppTheme.caption;
    expect(style.fontSize, 11.0);
    expect(style.fontWeight, FontWeight.normal);
  });
}
