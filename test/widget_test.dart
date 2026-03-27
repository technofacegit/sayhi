import 'package:flutter_test/flutter_test.dart';
import 'package:qr_dating_app/app/app.dart';

void main() {
  testWidgets('Say Hi app shows onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Scan into the moment'), findsOneWidget);
  });
}
