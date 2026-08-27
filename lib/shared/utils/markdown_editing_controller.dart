import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A custom TextEditingController that styles Markdown syntax in real time
/// so bold appears bold, italic appears italic, underline appears underlined,
/// headings appear as styled headings, and syntax delimiters (like **, *, <u>, #)
/// are completely hidden/non-visible to provide a true rich-text feel.
class MarkdownEditingController extends TextEditingController {
  final TextStyle? defaultTextStyle;

  MarkdownEditingController({super.text, this.defaultTextStyle});

  static const TextStyle invisibleSyntaxStyle = TextStyle(
    fontSize: 0.001,
    color: Colors.transparent,
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? defaultTextStyle ?? DefaultTextStyle.of(context).style;
    final textVal = text;

    if (textVal.isEmpty) {
      return TextSpan(style: baseStyle, text: '');
    }

    final theme = Theme.of(context);
    final spans = <InlineSpan>[];

    // Split text into lines while preserving linebreaks
    final lines = textVal.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLastLine = i == lines.length - 1;
      final lineSuffix = isLastLine ? '' : '\n';

      if (line.isEmpty) {
        spans.add(TextSpan(text: lineSuffix, style: baseStyle));
        continue;
      }

      // Check line-level formatting
      if (line.startsWith('#')) {
        final headingMatch = RegExp(r'^(#{1,6})\s(.*)$').firstMatch(line);
        final headingEmptyMatch = RegExp(r'^(#{1,6})\s*$').firstMatch(line);
        if (headingMatch != null) {
          final hashes = headingMatch.group(1)!;
          final content = headingMatch.group(2)!;
          final prefixLen = hashes.length + 1; // hashes + space
          final double scale = switch (hashes.length) {
            1 => 1.4,
            2 => 1.25,
            3 => 1.15,
            4 => 1.1,
            5 => 1.05,
            _ => 1.0,
          };
          final headingStyle = baseStyle.copyWith(
            fontSize: (baseStyle.fontSize ?? 16.0) * scale,
            fontWeight: hashes.length <= 2 ? FontWeight.bold : FontWeight.w600,
            color: theme.colorScheme.primary,
          );
          spans.add(TextSpan(text: line.substring(0, prefixLen), style: invisibleSyntaxStyle));
          _parseInlineFormatting(content, headingStyle, spans);
          spans.add(TextSpan(text: lineSuffix, style: baseStyle));
          continue;
        } else if (headingEmptyMatch != null) {
          spans.add(TextSpan(text: line, style: invisibleSyntaxStyle));
          spans.add(TextSpan(text: lineSuffix, style: baseStyle));
          continue;
        }
      }

      if (line.startsWith('> ') || line == '>') {
        final quoteStyle = baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: baseStyle.color?.withValues(alpha: 0.85),
        );
        if (line == '>') {
          spans.add(const TextSpan(text: '>', style: invisibleSyntaxStyle));
        } else {
          // Render a visual quote vertical bar in place of '> '
          spans.add(TextSpan(
            text: '▍ ',
            style: baseStyle.copyWith(
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
            ),
          ));
          _parseInlineFormatting(line.substring(2), quoteStyle, spans);
        }
        spans.add(TextSpan(text: lineSuffix, style: baseStyle));
        continue;
      }

      if (line.startsWith('- [ ] ') || line.startsWith('- [x] ') || line.startsWith('- [X] ')) {
        final isChecked = line.startsWith('- [x] ') || line.startsWith('- [X] ');
        final itemStyle = isChecked
            ? baseStyle.copyWith(
                decoration: TextDecoration.lineThrough,
                color: baseStyle.color?.withValues(alpha: 0.5),
              )
            : baseStyle;
        final visualIcon = isChecked ? '☑     ' : '☐     ';
        spans.add(TextSpan(
          text: visualIcon,
          style: baseStyle.copyWith(
            color: isChecked ? theme.colorScheme.primary.withValues(alpha: 0.7) : theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ));
        _parseInlineFormatting(line.substring(6), itemStyle, spans);
        spans.add(TextSpan(text: lineSuffix, style: baseStyle));
        continue;
      }

      if (line.startsWith('- ') || line.startsWith('* ') || line.startsWith('+ ')) {
        spans.add(TextSpan(
          text: '• ',
          style: baseStyle.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ));
        _parseInlineFormatting(line.substring(2), baseStyle, spans);
        spans.add(TextSpan(text: lineSuffix, style: baseStyle));
        continue;
      }

      if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final match = RegExp(r'^\d+\.\s').firstMatch(line)!;
        final prefix = match.group(0)!;
        final syntaxStyle = baseStyle.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        );
        spans.add(TextSpan(text: prefix, style: syntaxStyle));
        _parseInlineFormatting(line.substring(prefix.length), baseStyle, spans);
        spans.add(TextSpan(text: lineSuffix, style: baseStyle));
        continue;
      }

      if (line.trim() == '---' || line.trim() == '***' || line.trim() == '___') {
        final dividerStyle = baseStyle.copyWith(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        );
        spans.add(TextSpan(text: line + lineSuffix, style: dividerStyle));
        continue;
      }

      _parseInlineFormatting(line, baseStyle, spans);
      spans.add(TextSpan(text: lineSuffix, style: baseStyle));
    }

    return TextSpan(children: spans, style: baseStyle);
  }

  static TextDecoration _mergeDecorations(TextDecoration? existing, TextDecoration added) {
    if (existing == null || existing == TextDecoration.none) {
      return added;
    }
    if (existing == added) {
      return existing;
    }
    final containsUnderline = existing.contains(TextDecoration.underline) || added == TextDecoration.underline;
    final containsLineThrough = existing.contains(TextDecoration.lineThrough) || added == TextDecoration.lineThrough;
    final containsOverline = existing.contains(TextDecoration.overline) || added == TextDecoration.overline;

    final list = <TextDecoration>[];
    if (containsUnderline) list.add(TextDecoration.underline);
    if (containsLineThrough) list.add(TextDecoration.lineThrough);
    if (containsOverline) list.add(TextDecoration.overline);

    if (list.isEmpty) return TextDecoration.none;
    if (list.length == 1) return list.first;
    return TextDecoration.combine(list);
  }

  void _parseInlineFormatting(
    String text,
    TextStyle lineBaseStyle,
    List<InlineSpan> spans,
  ) {
    if (text.isEmpty) return;

    // Ordered pattern for inline markdown & rich-text tags with support for nesting / combinations
    final pattern = RegExp(
      r'(\*\*\*(.*?)\*\*\*)|'                                      // 1, 2: Bold-Italic ***
      r'(___(.*?)___)|'                                            // 3, 4: Bold-Italic ___
      r'(\*\*(.*?)\*\*)|'                                          // 5, 6: Bold **
      r'(__([^_]*?)__)|'                                           // 7, 8: Bold __
      r'(<(?:b|strong)\b[^>]*>(.*?)</(?:b|strong)>)|'              // 9, 10: Bold HTML
      r'(<(?:u|ins)\b[^>]*>(.*?)</(?:u|ins)>)|'                    // 11, 12: Underline HTML
      r'((?<!\*)\*([^\*\n]+?)(?<!\*)\*(?!\*))|'                    // 13, 14: Italic *
      r'((?<!_)_([^_\n]+?)(?<!_)_(?!_))|'                          // 15, 16: Italic _
      r'(<(?:i|em)\b[^>]*>(.*?)</(?:i|em)>)|'                      // 17, 18: Italic HTML
      r'(~~([^~\n]*?)~~)|'                                         // 19, 20: Strikethrough ~~
      r'(<(?:del|s)\b[^>]*>(.*?)</(?:del|s)>)|'                    // 21, 22: Strikethrough HTML
      r'(`([^`\n]*?)`)|'                                           // 23, 24: Code `
      r'(\[([^\]\n]*?)\]\(([^\)\n]*?)\))',                         // 25, 26, 27: Link []()
      caseSensitive: false,
    );

    int currentIndex = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, match.start),
          style: lineBaseStyle,
        ));
      }

      if (match.group(1) != null) {
        // ***bold-italic***
        spans.add(const TextSpan(text: '***', style: invisibleSyntaxStyle));
        final inner = match.group(2) ?? '';
        final innerStyle = lineBaseStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        );
        _parseInlineFormatting(inner, innerStyle, spans);
        spans.add(const TextSpan(text: '***', style: invisibleSyntaxStyle));
      } else if (match.group(3) != null) {
        // ___bold-italic___
        spans.add(const TextSpan(text: '___', style: invisibleSyntaxStyle));
        final inner = match.group(4) ?? '';
        final innerStyle = lineBaseStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        );
        _parseInlineFormatting(inner, innerStyle, spans);
        spans.add(const TextSpan(text: '___', style: invisibleSyntaxStyle));
      } else if (match.group(5) != null) {
        // **bold**
        spans.add(const TextSpan(text: '**', style: invisibleSyntaxStyle));
        final inner = match.group(6) ?? '';
        final innerStyle = lineBaseStyle.copyWith(
          fontWeight: FontWeight.bold,
        );
        _parseInlineFormatting(inner, innerStyle, spans);
        spans.add(const TextSpan(text: '**', style: invisibleSyntaxStyle));
      } else if (match.group(7) != null) {
        // __bold__
        spans.add(const TextSpan(text: '__', style: invisibleSyntaxStyle));
        final inner = match.group(8) ?? '';
        final innerStyle = lineBaseStyle.copyWith(
          fontWeight: FontWeight.bold,
        );
        _parseInlineFormatting(inner, innerStyle, spans);
        spans.add(const TextSpan(text: '__', style: invisibleSyntaxStyle));
      } else if (match.group(9) != null) {
        // <b>bold</b> or <strong>bold</strong>
        final fullMatch = match.group(9)!;
        final inner = match.group(10) ?? '';
        final openEnd = fullMatch.indexOf('>') + 1;
        final closeStart = fullMatch.lastIndexOf('<');
        spans.add(TextSpan(text: fullMatch.substring(0, openEnd), style: invisibleSyntaxStyle));
        final innerStyle = lineBaseStyle.copyWith(
          fontWeight: FontWeight.bold,
        );
        _parseInlineFormatting(inner, innerStyle, spans);
        spans.add(TextSpan(text: fullMatch.substring(closeStart), style: invisibleSyntaxStyle));
      } else if (match.group(11) != null) {
        // <u>underline</u> or <ins>underline</ins>
        final fullMatch = match.group(11)!;
        final inner = match.group(12) ?? '';
        final openEnd = fullMatch.indexOf('>') + 1;
        final closeStart = fullMatch.lastIndexOf('<');
        spans.add(TextSpan(text: fullMatch.substring(0, openEnd), style: invisibleSyntaxStyle));
        final innerStyle = lineBaseStyle.copyWith(
          decoration: _mergeDecorations(lineBaseStyle.decoration, TextDecoration.underline),
        );
        _parseInlineFormatting(inner, innerStyle, spans);
        spans.add(TextSpan(text: fullMatch.substring(closeStart), style: invisibleSyntaxStyle));
      } else if (match.group(13) != null) {
        // *italic*
        spans.add(const TextSpan(text: '*', style: invisibleSyntaxStyle));
        final inner = match.group(14) ?? '';
        final innerStyle = lineBaseStyle.copyWith(
          fontStyle: FontStyle.italic,
        );
        _parseInlineFormatting(inner, innerStyle, spans);
        spans.add(const TextSpan(text: '*', style: invisibleSyntaxStyle));
      } else if (match.group(15) != null) {
        // _italic_
        spans.add(const TextSpan(text: '_', style: invisibleSyntaxStyle));
        final inner = match.group(16) ?? '';
        final innerStyle = lineBaseStyle.copyWith(
          fontStyle: FontStyle.italic,
        );
        _parseInlineFormatting(inner, innerStyle, spans);
        spans.add(const TextSpan(text: '_', style: invisibleSyntaxStyle));
      } else if (match.group(17) != null) {
        // <i>italic</i> or <em>italic</em>
        final fullMatch = match.group(17)!;
        final inner = match.group(18) ?? '';
        final openEnd = fullMatch.indexOf('>') + 1;
        final closeStart = fullMatch.lastIndexOf('<');
        spans.add(TextSpan(text: fullMatch.substring(0, openEnd), style: invisibleSyntaxStyle));
        final innerStyle = lineBaseStyle.copyWith(
          fontStyle: FontStyle.italic,
        );
        _parseInlineFormatting(inner, innerStyle, spans);
        spans.add(TextSpan(text: fullMatch.substring(closeStart), style: invisibleSyntaxStyle));
      } else if (match.group(19) != null) {
        // ~~strikethrough~~
        spans.add(const TextSpan(text: '~~', style: invisibleSyntaxStyle));
        final inner = match.group(20) ?? '';
        final innerStyle = lineBaseStyle.copyWith(
          decoration: _mergeDecorations(lineBaseStyle.decoration, TextDecoration.lineThrough),
        );
        _parseInlineFormatting(inner, innerStyle, spans);
        spans.add(const TextSpan(text: '~~', style: invisibleSyntaxStyle));
      } else if (match.group(21) != null) {
        // <del>strikethrough</del> or <s>strikethrough</s>
        final fullMatch = match.group(21)!;
        final inner = match.group(22) ?? '';
        final openEnd = fullMatch.indexOf('>') + 1;
        final closeStart = fullMatch.lastIndexOf('<');
        spans.add(TextSpan(text: fullMatch.substring(0, openEnd), style: invisibleSyntaxStyle));
        final innerStyle = lineBaseStyle.copyWith(
          decoration: _mergeDecorations(lineBaseStyle.decoration, TextDecoration.lineThrough),
        );
        _parseInlineFormatting(inner, innerStyle, spans);
        spans.add(TextSpan(text: fullMatch.substring(closeStart), style: invisibleSyntaxStyle));
      } else if (match.group(23) != null) {
        // `code`
        spans.add(const TextSpan(text: '`', style: invisibleSyntaxStyle));
        spans.add(TextSpan(
          text: match.group(24) ?? '',
          style: lineBaseStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: (lineBaseStyle.color ?? Colors.grey).withValues(alpha: 0.1),
          ),
        ));
        spans.add(const TextSpan(text: '`', style: invisibleSyntaxStyle));
      } else if (match.group(25) != null) {
        // [text](url)
        spans.add(const TextSpan(text: '[', style: invisibleSyntaxStyle));
        final inner = match.group(26) ?? '';
        final linkStyle = lineBaseStyle.copyWith(
          color: const Color(0xFF2E6B9E),
          decoration: _mergeDecorations(lineBaseStyle.decoration, TextDecoration.underline),
        );
        _parseInlineFormatting(inner, linkStyle, spans);
        spans.add(TextSpan(text: '](${match.group(27)})', style: invisibleSyntaxStyle));
      }

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentIndex),
        style: lineBaseStyle,
      ));
    }
  }
}

/// A specialized TextInputFormatter for Markdown editing that prevents formatting
/// syntax clashes when the user presses Enter to start a new line.
///
/// Features:
/// 1. Keeps closing formatting delimiters (e.g. `**`, `*`, `</u>`, `~~`, `` ` ``, `***`) on the current line.
/// 2. If splitting in the middle of active formatting, cleanly closes on line 1 and re-opens on line 2.
/// 3. Intelligently continues lists (bullet `- `, numbered `1. `, checklists `- [ ] `, quotes `> `).
/// 4. Exits lists/empty formatting cleanly when Enter is pressed on an empty item.
class MarkdownTextInputFormatter extends TextInputFormatter {
  const MarkdownTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length <= oldValue.text.length) {
      return newValue;
    }

    final oldText = oldValue.text;
    final newText = newValue.text;
    final oldSelection = oldValue.selection;

    final oldStart = oldSelection.isValid ? oldSelection.start : 0;
    final oldEnd = oldSelection.isValid ? oldSelection.end : 0;
    final minSel = oldStart < oldEnd ? oldStart : oldEnd;
    final maxSel = oldStart < oldEnd ? oldEnd : oldStart;

    final insertedLen = newText.length - (oldText.length - (maxSel - minSel));
    if (insertedLen <= 0) return newValue;

    final insertPos = minSel;
    if (insertPos < 0 || insertPos + insertedLen > newText.length) return newValue;

    final insertedStr = newText.substring(insertPos, insertPos + insertedLen);
    if (!insertedStr.contains('\n')) {
      return newValue;
    }

    return handleNewline(oldText, minSel, maxSel, insertedStr);
  }

  static TextEditingValue handleNewline(
    String oldText,
    int selStart,
    int selEnd,
    String insertedStr,
  ) {
    int lineStart = oldText.lastIndexOf('\n', selStart > 0 ? selStart - 1 : 0);
    lineStart = lineStart == -1 ? 0 : lineStart + 1;

    int lineEnd = oldText.indexOf('\n', selEnd);
    lineEnd = lineEnd == -1 ? oldText.length : lineEnd;

    final lineBeforeCursor = oldText.substring(lineStart, selStart);
    final lineAfterCursor = oldText.substring(selEnd, lineEnd);
    final fullLine = oldText.substring(lineStart, lineEnd);

    // 1. Check if the line is an empty list/heading/quote item (e.g. "- ", "1. ", "- [ ] ", "> ", "# ")
    final emptyPrefixMatch = RegExp(r'^(#{1,6}\s*|- \[\s?[xX]?\]\s*|- \s*|\* \s*|\+ \s*|\d+\.\s*|> \s*)$').firstMatch(fullLine);
    if (emptyPrefixMatch != null && lineBeforeCursor.trim() == fullLine.trim()) {
      final beforeLineBlock = oldText.substring(0, lineStart);
      final afterLineBlock = oldText.substring(lineEnd);
      final newContent = '$beforeLineBlock\n$afterLineBlock';
      return TextEditingValue(
        text: newContent,
        selection: TextSelection.collapsed(offset: lineStart + 1),
      );
    }

    // 2. Check if cursor is sitting inside empty inline formatting (e.g. "**|**", "*|*", "<u>|</u>", "**<u>|</u>**", "~~|~~", "`|`")
    final emptyFormatMarkers = [
      ('***', '***'),
      ('___', '___'),
      ('**<u>', '</u>**'),
      ('<u>**', '**</u>'),
      ('**', '**'),
      ('__', '__'),
      ('<u>', '</u>'),
      ('*<u>', '</u>*'),
      ('<u>*', '*</u>'),
      ('*', '*'),
      ('_', '_'),
      ('~~', '~~'),
      ('`', '`'),
    ];

    for (final (openTag, closeTag) in emptyFormatMarkers) {
      if (lineBeforeCursor.endsWith(openTag) && lineAfterCursor.startsWith(closeTag)) {
        if (lineBeforeCursor == openTag && lineAfterCursor == closeTag) {
          final beforeLineBlock = oldText.substring(0, lineStart);
          final afterLineBlock = oldText.substring(lineEnd);
          final newContent = '$beforeLineBlock\n$afterLineBlock';
          return TextEditingValue(
            text: newContent,
            selection: TextSelection.collapsed(offset: lineStart + 1),
          );
        }
      }
    }

    // 3. Inspect line-level continuation prefix (Lists, Checklists, Blockquotes)
    String continuationPrefix = '';
    final checklistMatch = RegExp(r'^- \[\s?[xX]?\]\s+').firstMatch(lineBeforeCursor);
    final numberedMatch = RegExp(r'^(\d+)\.\s+').firstMatch(lineBeforeCursor);
    final bulletMatch = RegExp(r'^(- |\* |\+ )').firstMatch(lineBeforeCursor);
    final quoteMatch = RegExp(r'^> ').firstMatch(lineBeforeCursor);

    if (checklistMatch != null) {
      continuationPrefix = '- [ ] ';
    } else if (numberedMatch != null) {
      final currentNum = int.tryParse(numberedMatch.group(1) ?? '1') ?? 1;
      continuationPrefix = '${currentNum + 1}. ';
    } else if (bulletMatch != null) {
      continuationPrefix = bulletMatch.group(0)!;
    } else if (quoteMatch != null) {
      continuationPrefix = '> ';
    }

    // 4. Inspect active inline tags at cursor on this line
    final activeTags = _computeActiveInlineTags(lineBeforeCursor);
    final isAfterOnlyClosingTags = _isOnlyClosingTags(lineAfterCursor, activeTags);

    if (isAfterOnlyClosingTags && activeTags.isNotEmpty) {
      // Keep closing delimiters on line 1 so line 1 is fully styled and closed,
      // and line 2 starts clean without orphaned closing syntax.
      final beforeLineBlock = oldText.substring(0, lineStart);
      final line1 = '$lineBeforeCursor$lineAfterCursor';
      final afterLineBlock = oldText.substring(lineEnd);

      final newContent = '$beforeLineBlock$line1\n$continuationPrefix$afterLineBlock';
      final newCursorOffset = beforeLineBlock.length + line1.length + 1 + continuationPrefix.length;

      return TextEditingValue(
        text: newContent,
        selection: TextSelection.collapsed(offset: newCursorOffset),
      );
    }

    // 5. If cursor is in the MIDDLE of formatted text with content after cursor (e.g. "**Part 1 | Part 2**")
    if (activeTags.isNotEmpty && lineAfterCursor.isNotEmpty) {
      final closingTags = activeTags.reversed.map(_getClosingTag).join();
      final openingTags = activeTags.join();

      final beforeLineBlock = oldText.substring(0, lineStart);
      final line1 = '$lineBeforeCursor$closingTags';
      final line2 = '$continuationPrefix$openingTags$lineAfterCursor';
      final afterLineBlock = oldText.substring(lineEnd);

      final newContent = '$beforeLineBlock$line1\n$line2$afterLineBlock';
      final newCursorOffset = beforeLineBlock.length + line1.length + 1 + continuationPrefix.length + openingTags.length;

      return TextEditingValue(
        text: newContent,
        selection: TextSelection.collapsed(offset: newCursorOffset),
      );
    }

    // 6. Normal line break with continuation prefix
    final beforeCursorAll = oldText.substring(0, selStart);
    final afterCursorAll = oldText.substring(selEnd);
    final newContent = '$beforeCursorAll\n$continuationPrefix$afterCursorAll';
    final newCursorOffset = beforeCursorAll.length + 1 + continuationPrefix.length;

    return TextEditingValue(
      text: newContent,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }

  static List<String> _computeActiveInlineTags(String text) {
    final active = <String>[];

    final tripleStars = RegExp(r'\*\*\*').allMatches(text).length;
    final doubleStars = RegExp(r'(?<!\*)\*\*(?!\*)').allMatches(text).length;
    final singleStars = RegExp(r'(?<!\*)\*(?!\*)').allMatches(text).length;

    final uOpen = RegExp(r'<(?:u|ins)\b[^>]*>', caseSensitive: false).allMatches(text).length;
    final uClose = RegExp(r'</(?:u|ins)>', caseSensitive: false).allMatches(text).length;

    final bOpen = RegExp(r'<(?:b|strong)\b[^>]*>', caseSensitive: false).allMatches(text).length;
    final bClose = RegExp(r'</(?:b|strong)>', caseSensitive: false).allMatches(text).length;

    final iOpen = RegExp(r'<(?:i|em)\b[^>]*>', caseSensitive: false).allMatches(text).length;
    final iClose = RegExp(r'</(?:i|em)>', caseSensitive: false).allMatches(text).length;

    final strikeCount = RegExp(r'~~').allMatches(text).length;
    final codeCount = RegExp(r'(?<!`)`(?!`)').allMatches(text).length;

    if (tripleStars % 2 == 1) {
      active.add('***');
    } else {
      if (doubleStars % 2 == 1 || bOpen > bClose) {
        active.add('**');
      }
      if (singleStars % 2 == 1 || iOpen > iClose) {
        active.add('*');
      }
    }

    if (uOpen > uClose) {
      active.add('<u>');
    }

    if (strikeCount % 2 == 1) {
      active.add('~~');
    }

    if (codeCount % 2 == 1) {
      active.add('`');
    }

    return active;
  }

  static String _getClosingTag(String openTag) {
    return switch (openTag) {
      '<u>' => '</u>',
      '<b>' => '</b>',
      '<strong>' => '</strong>',
      '<i>' => '</i>',
      '<em>' => '</em>',
      _ => openTag,
    };
  }

  static bool _isOnlyClosingTags(String text, List<String> activeTags) {
    if (text.isEmpty) return false;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    final closingPattern = RegExp(r'^((\*\*|\*|</u>|</ins>|</b>|</strong>|</i>|</em>|\*\*\*|~~|`|\s)+)$', caseSensitive: false);
    return closingPattern.hasMatch(trimmed);
  }
}

