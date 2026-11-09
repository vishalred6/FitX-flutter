import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:web/web.dart' as web;

void registerBrowserStorage() => SharedPreferencesPlugin.registerWith(null);

Future<ByteData> loadTestFont() async {
  // Respect the bundled font rather than the browser runner's forced Ahem font.
  ui_web.TestEnvironment.setUp(
    const ui_web.TestEnvironment(
      ignorePlatformMessages: true,
      disableFontFallbacks: true,
      keepSemanticsDisabledOnUpdate: true,
      defaultToTestUrlStrategy: true,
    ),
  );
  final response = await web.window
      .fetch('/assets/fonts/Manrope.ttf'.toJS)
      .toDart;
  if (!response.ok) {
    throw StateError('Test font could not be loaded');
  }
  final buffer = await response.arrayBuffer().toDart;
  return ByteData.sublistView(buffer.toDart.asUint8List());
}
