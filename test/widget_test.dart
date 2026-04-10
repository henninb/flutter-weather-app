import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minneapolis_weather/main.dart';
import 'package:minneapolis_weather/services/human_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.humansecurity/sdk'),
      (call) async {
        switch (call.method) {
          case 'humanConfigure':
            return null;
          case 'humanGetHeaders':
            return '{}';
          case 'humanHandleResponse':
            return 'false';
          default:
            return null;
        }
      },
    );
    // Mirrors [main]: native HUMAN must configure before the UI tree runs.
    await HumanService.ensureNativeSdkConfigured();
  });

  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const WeatherApp());
    expect(find.text('Protected weather API'), findsOneWidget);
    // Allow CustomApiSection async work to finish (HTTP may fail in test env).
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });
}
