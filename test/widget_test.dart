import 'package:flutter_test/flutter_test.dart';
import 'package:pinspot/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PinspotApp());
    expect(find.text('PINSPOT'), findsWidgets);
  });
}
