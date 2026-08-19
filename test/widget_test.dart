import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_diary/features/onboarding/pin_setup_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('SecDiary app test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PinSetupScreen(),
        ),
      ),
    );

    expect(find.byType(PinSetupScreen), findsOneWidget);
  });
}
