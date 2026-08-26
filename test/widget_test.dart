import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lingo_flow/main.dart';

void main() {
  testWidgets('App renders Home Screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LingoFlowApp(),
      ),
    );

    expect(find.text('LingoFlow'), findsOneWidget);
  });
}
