import 'package:flutter_test/flutter_test.dart';
import 'package:lifeplan/main.dart';

void main() {
  testWidgets('LifePlanApp renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const LifePlanApp());
    await tester.pumpAndSettle();

    // Verify the app title is displayed
    expect(find.text('LifePlan'), findsOneWidget);
  });
}
