import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minneapolis_weather/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
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
  });

  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const WeatherApp());
    expect(find.text('Protected weather API'), findsOneWidget);
    // Allow CustomApiSection async work to finish (HTTP may fail in test env).
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });
}
