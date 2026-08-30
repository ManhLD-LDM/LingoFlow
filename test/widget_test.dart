import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingo_flow/presentation/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('hotkey_manager'), (MethodCall methodCall) async {
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.lingoflow/native'), (MethodCall methodCall) async {
      return true;
    });
  });

  testWidgets('HomeScreen renders Desktop Studio layout on widescreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('LingoFlow Studio'), findsOneWidget);
    expect(find.text('Studio Dịch Thuật'), findsOneWidget);
    expect(find.text('MỞ OVERLAY'), findsOneWidget);
    expect(find.text('CHỤP 1 LẦN (Alt+S)'), findsOneWidget);
  });

  testWidgets('HomeScreen renders Mobile layout on small screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('LingoFlow'), findsOneWidget);
    expect(find.text('KÍCH HOẠT FLOATING WIDGET'), findsOneWidget);
    expect(find.text('HỘP TEST DỊCH NHANH'), findsOneWidget);
  });
}
