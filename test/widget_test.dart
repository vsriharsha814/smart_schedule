import 'package:flutter_test/flutter_test.dart';
import 'package:smart_schedule/main.dart';

void main() {
  testWidgets('App shows Phase I setup when Firebase not configured',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SmartScheduleApp(firebaseReady: false));

    expect(find.text('Phase I: Setup'), findsOneWidget);
    expect(find.text('Firebase is not configured.'), findsOneWidget);
  });
}
