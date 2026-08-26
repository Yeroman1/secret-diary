import 'package:flutter/material.dart';

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
