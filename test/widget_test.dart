import 'package:flutter_test/flutter_test.dart';
import 'package:minneapolis_weather/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MinneapolisWeatherApp());
    expect(find.text('Minneapolis, MN'), findsOneWidget);
  });
}
