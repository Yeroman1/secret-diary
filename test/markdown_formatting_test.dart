import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret_diary/features/entries/widgets/markdown_toolbar.dart';
import 'package:secret_diary/shared/utils/markdown_editing_controller.dart';
import 'package:secret_diary/shared/utils/markdown_stripper.dart';

void main() {
  group('MarkdownEditingController & MarkdownToolbar tests', () {
    testWidgets('MarkdownEditingController displays plain text content correctly without hiding characters', (tester) async {
      final controller = MarkdownEditingController(
        text: 'This is my secret note content.\nIt has multiple lines and normal punctuation: like, this!',
      );

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
      // Verify visible text spans exist and have valid non-zero letterSpacing/fontSize
      final textPieces = span.children!
          .map((s) => s is TextSpan ? s.text : '')
          .join();
      expect(textPieces, 'This is my secret note content.\nIt has multiple lines and normal punctuation: like, this!');
    });

    testWidgets('MarkdownEditingController builds styled spans with invisible delimiters for bold, italic, underline, and headings', (tester) async {
      final controller = MarkdownEditingController(
        text: 'Hello **world** and *italic* and <u>underlined</u> and ~~strike~~ and # Heading 1',
      );

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
      final invisibleSpans = span.children!.where((s) {
        if (s is TextSpan && s.style != null) {
          return s.style!.color == Colors.transparent;
        }
        return false;
      }).toList();
      expect(invisibleSpans.length, greaterThanOrEqualTo(5));

      // Verify bold text span exists
      final hasBoldSpan = span.children!.any((s) {
        if (s is TextSpan && s.style != null) {
          return s.text == 'world' && s.style!.fontWeight == FontWeight.bold;
        }
        return false;
      });
      expect(hasBoldSpan, isTrue);

      // Verify italic text span exists
      final hasItalicSpan = span.children!.any((s) {
        if (s is TextSpan && s.style != null) {
          return s.text == 'italic' && s.style!.fontStyle == FontStyle.italic;
        }
        return false;
      });
      expect(hasItalicSpan, isTrue);

      // Verify underline text span exists
      final hasUnderlineSpan = span.children!.any((s) {
        if (s is TextSpan && s.style != null) {
          return s.text == 'underlined' && s.style!.decoration == TextDecoration.underline;
        }
        return false;
      });
      expect(hasUnderlineSpan, isTrue);

      // Verify strikethrough text span exists
      final hasStrikeSpan = span.children!.any((s) {
        if (s is TextSpan && s.style != null) {
          return s.text == 'strike' && s.style!.decoration == TextDecoration.lineThrough;
        }
        return false;
      });
      expect(hasStrikeSpan, isTrue);
    });

    testWidgets('MarkdownEditingController hides empty delimiters when toolbar button is pressed without selection', (tester) async {
      final controller = MarkdownEditingController(text: '****');

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

      // All spans for empty bold should be transparent/invisible
      final hasVisibleNonTransparent = span.children!.any((s) {
        if (s is TextSpan && s.text != null && s.text!.isNotEmpty) {
          return s.style?.color != Colors.transparent;
        }
        return false;
      });
      expect(hasVisibleNonTransparent, isFalse);
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

      final boldButton = find.byTooltip('Bold');
      expect(boldButton, findsOneWidget);

      await tester.tap(boldButton);
      await tester.pump();

      expect(controller.text, 'Hello ****');
      expect(controller.selection.baseOffset, 8); // Placed in middle: Hello **|**
    });

    testWidgets('MarkdownToolbar wraps selected text with bold and typing afterwards does not delete the text', (tester) async {
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
      // Verify selection is collapsed at the end (not highlighting 'world' which would cause deletion on keystroke)
      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.selection.baseOffset, 15); // End of 'Hello **world**'

      // Enter text now - it should append, NOT delete 'world'
      await tester.enterText(find.byType(TextField), 'Hello **world** again');
      await tester.pump();

      expect(controller.text, 'Hello **world** again');
    });

    testWidgets('MarkdownToolbar wraps selected text with underline and toggles off', (tester) async {
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

      final underlineButton = find.byTooltip('Underline');
      expect(underlineButton, findsOneWidget);

      await tester.tap(underlineButton);
      await tester.pump();

      expect(controller.text, 'Hello <u>world</u>');

      // Tapping underline button when selecting formatted text or inside it should unwrap / toggle off
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 18); // '<u>world</u>'
      await tester.tap(underlineButton);
      await tester.pump();

      expect(controller.text, 'Hello world');
    });

    testWidgets('MarkdownToolbar wraps selected text with italic and toggles off', (tester) async {
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

      final italicButton = find.byTooltip('Italic');
      expect(italicButton, findsOneWidget);

      await tester.tap(italicButton);
      await tester.pump();

      expect(controller.text, 'Hello *world*');

      // Tapping italic button when selecting formatted text should unwrap / toggle off
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 13); // '*world*'
      await tester.tap(italicButton);
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

    testWidgets('MarkdownEditingController correctly builds nested combined styles (bold + italic + underline)', (tester) async {
      final controller = MarkdownEditingController(
        text: 'This is **<u>*all three*</u>** and <u>**bold-underline**</u> and *<u>italic-underline</u>*',
      );

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

      // Verify all-three span has bold, italic, and underline
      final allThreeSpan = span.children!.firstWhere((s) => s is TextSpan && s.text == 'all three') as TextSpan;
      expect(allThreeSpan.style!.fontWeight, FontWeight.bold);
      expect(allThreeSpan.style!.fontStyle, FontStyle.italic);
      expect(allThreeSpan.style!.decoration, TextDecoration.underline);

      // Verify bold-underline span
      final boldUnderlineSpan = span.children!.firstWhere((s) => s is TextSpan && s.text == 'bold-underline') as TextSpan;
      expect(boldUnderlineSpan.style!.fontWeight, FontWeight.bold);
      expect(boldUnderlineSpan.style!.decoration, TextDecoration.underline);

      // Verify italic-underline span
      final italicUnderlineSpan = span.children!.firstWhere((s) => s is TextSpan && s.text == 'italic-underline') as TextSpan;
      expect(italicUnderlineSpan.style!.fontStyle, FontStyle.italic);
      expect(italicUnderlineSpan.style!.decoration, TextDecoration.underline);
    });

    testWidgets('MarkdownToolbar supports applying and toggling combined Bold, Underline, and Italic', (tester) async {
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
      final underlineButton = find.byTooltip('Underline');
      final italicButton = find.byTooltip('Italic');

      // 1. Apply Bold -> Hello **world**
      await tester.tap(boldButton);
      await tester.pump();
      expect(controller.text, 'Hello **world**');

      // 2. Select '**world**' and apply Underline -> Hello <u>**world**</u>
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 15);
      await tester.tap(underlineButton);
      await tester.pump();
      expect(controller.text, 'Hello <u>**world**</u>');

      // 3. Toggle Underline OFF -> Hello **world**
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 22);
      await tester.tap(underlineButton);
      await tester.pump();
      expect(controller.text, 'Hello **world**');

      // 4. Apply Italic to '**world**' -> Hello ***world***
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 15);
      await tester.tap(italicButton);
      await tester.pump();
      expect(controller.text, 'Hello ***world***');

      // 5. Toggle Bold OFF from '***world***' -> Hello *world*
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 17);
      await tester.tap(boldButton);
      await tester.pump();
      expect(controller.text, 'Hello *world*');

      // 6. Toggle Italic OFF -> Hello world
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 13);
      await tester.tap(italicButton);
      await tester.pump();
      expect(controller.text, 'Hello world');
    });

    testWidgets('MarkdownToolbar supports empty cursor combinations (e.g. Bold then Underline)', (tester) async {
      final controller = MarkdownEditingController(text: '');
      controller.selection = const TextSelection.collapsed(offset: 0);

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
      final underlineButton = find.byTooltip('Underline');

      // Tap Bold -> '****' with cursor at 2 (**|**)
      await tester.tap(boldButton);
      await tester.pump();
      expect(controller.text, '****');
      expect(controller.selection.baseOffset, 2);

      // Tap Underline -> '**<u></u>**' with cursor at 5 (**<u>|</u>**)
      await tester.tap(underlineButton);
      await tester.pump();
      expect(controller.text, '**<u></u>**');
      expect(controller.selection.baseOffset, 5);
    });

    testWidgets('MarkdownToolbar buttons indicate active state when cursor is within formatted text or heading', (tester) async {
      final controller = MarkdownEditingController(text: '# Heading\n**<u>bold underline</u>**');
      // Cursor inside 'bold underline' at offset 15
      controller.selection = const TextSelection.collapsed(offset: 15);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
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

      final boldFinder = find.byTooltip('Bold');
      final underlineFinder = find.byTooltip('Underline');
      final italicFinder = find.byTooltip('Italic');
      final h1Finder = find.byTooltip('Heading 1');

      // Verify Bold icon has primary color (active)
      final boldIcon = tester.widget<Icon>(find.descendant(of: boldFinder, matching: find.byType(Icon)));
      final underlineIcon = tester.widget<Icon>(find.descendant(of: underlineFinder, matching: find.byType(Icon)));
      final italicIcon = tester.widget<Icon>(find.descendant(of: italicFinder, matching: find.byType(Icon)));
      final h1Icon = tester.widget<Icon>(find.descendant(of: h1Finder, matching: find.byType(Icon)));

      final primaryColor = Theme.of(tester.element(find.byType(MarkdownToolbar))).colorScheme.primary;

      // Bold and Underline should be active
      expect(boldIcon.color, equals(primaryColor));
      expect(underlineIcon.color, equals(primaryColor));
      // Italic and H1 should be inactive
      expect(italicIcon.color, isNot(equals(primaryColor)));
      expect(h1Icon.color, isNot(equals(primaryColor)));

      // Move cursor to line 1: '# Head|ing'
      controller.selection = const TextSelection.collapsed(offset: 5);
      await tester.pump();

      final updatedH1Icon = tester.widget<Icon>(find.descendant(of: h1Finder, matching: find.byType(Icon)));
      final updatedBoldIcon = tester.widget<Icon>(find.descendant(of: boldFinder, matching: find.byType(Icon)));

      // H1 is now active, Bold is inactive
      expect(updatedH1Icon.color, equals(primaryColor));
      expect(updatedBoldIcon.color, isNot(equals(primaryColor)));
    });

    test('MarkdownStripper cleanly strips bold, italic, underline, lists, and headings', () {
      const input = '# Heading\n**Bold** and *Italic* and <u>Underlined</u> and ~~Strike~~\n- Bullet item\n1. Numbered item';
      final stripped = MarkdownStripper.strip(input);
      expect(stripped, 'Heading Bold and Italic and Underlined and Strike Bullet item Numbered item');
    });

    test('MarkdownStripper cleanly strips combined nested formatting', () {
      const input = '**<u>*Bold Italic Underlined*</u>** and <u>**Bold Underlined**</u>';
      final stripped = MarkdownStripper.strip(input);
      expect(stripped, 'Bold Italic Underlined and Bold Underlined');
    });
  });
}
