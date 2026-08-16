import 'package:flutter_test/flutter_test.dart';
import 'package:secret_diary/app.dart';

void main() {
  testWidgets('SecDiary app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SecDiaryApp());
  });
}
