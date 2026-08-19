import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_diary/features/entries/widgets/markdown_toolbar.dart';
import 'package:secret_diary/shared/utils/markdown_editing_controller.dart';

void main() {
  group('MarkdownEditingController & MarkdownToolbar tests', () {
    testWidgets('MarkdownEditingController builds styled spans with invisible delimiters for bold and italic', (tester) async {
      final controller = MarkdownEditingController(text: 'Hello **world** and *italic* and # Heading 1');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
            ),
          ),
        ),
      );

      final span = controller.buildTextSpan(
        context: tester.element(find.byType(TextField)),
        withComposing: false,
      );

      expect(span.children, isNotNull);
      expect(span.children!.isNotEmpty, isTrue);

      // Verify that invisible syntax style is used for delimiters
      final hasInvisibleDelimiter = span.children!.any((s) {
        if (s is TextSpan && s.style != null) {
          return s.style!.color == Colors.transparent;
        }
        return false;
      });
      expect(hasInvisibleDelimiter, isTrue);
    });

    testWidgets('MarkdownToolbar inserts bold markers when cursor is empty (when to start)', (tester) async {
      final controller = MarkdownEditingController(text: 'Hello ');
      controller.selection = const TextSelection.collapsed(offset: 6);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(controller: controller),
                MarkdownToolbar(controller: controller),
              ],
            ),
          ),
        ),
      );

      // Find bold button (PhosphorIcons.textB)
      final boldButton = find.byTooltip('Bold');
      expect(boldButton, findsOneWidget);

      await tester.tap(boldButton);
      await tester.pump();

      expect(controller.text, 'Hello ****');
      expect(controller.selection.baseOffset, 8); // Placed in middle: Hello **|**
    });

    testWidgets('MarkdownToolbar wraps selected text with bold (when selected)', (tester) async {
      final controller = MarkdownEditingController(text: 'Hello world');
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 11); // 'world'

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(controller: controller),
                MarkdownToolbar(controller: controller),
              ],
            ),
          ),
        ),
      );

      final boldButton = find.byTooltip('Bold');
      await tester.tap(boldButton);
      await tester.pump();

      expect(controller.text, 'Hello **world**');

      // Tapping bold button again should unwrap / toggle off
      await tester.tap(boldButton);
      await tester.pump();

      expect(controller.text, 'Hello world');
    });

    testWidgets('MarkdownToolbar toggles line prefix for heading and lists', (tester) async {
      final controller = MarkdownEditingController(text: 'My thoughts today');
      controller.selection = const TextSelection.collapsed(offset: 5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(controller: controller),
                MarkdownToolbar(controller: controller),
              ],
            ),
          ),
        ),
      );

      final h1Button = find.byTooltip('Heading 1');
      await tester.tap(h1Button);
      await tester.pump();

      expect(controller.text, '# My thoughts today');

      // Tapping again toggles off
      await tester.tap(h1Button);
      await tester.pump();

      expect(controller.text, 'My thoughts today');
    });
  });
}
