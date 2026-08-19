import 'package:flutter/material.dart';

/// A custom TextEditingController that styles Markdown syntax in real time
/// so bold appears bold, italic appears italic, headings appear as headings,
/// and syntax delimiters (like ** or *) are completely hidden/non-visible.
class MarkdownEditingController extends TextEditingController {
  final TextStyle? defaultTextStyle;

  MarkdownEditingController({super.text, this.defaultTextStyle});

  static const TextStyle invisibleSyntaxStyle = TextStyle(
    fontSize: 0.001,
    color: Colors.transparent,
    letterSpacing: -1.0,
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
      if (line.startsWith('# ')) {
        final headingStyle = baseStyle.copyWith(
          fontSize: (baseStyle.fontSize ?? 16.0) * 1.4,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        );
        spans.add(const TextSpan(text: '# ', style: invisibleSyntaxStyle));
        _parseInlineFormatting(line.substring(2), headingStyle, spans);
        spans.add(TextSpan(text: lineSuffix, style: baseStyle));
      } else if (line.startsWith('## ')) {
        final headingStyle = baseStyle.copyWith(
          fontSize: (baseStyle.fontSize ?? 16.0) * 1.25,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        );
        spans.add(const TextSpan(text: '## ', style: invisibleSyntaxStyle));
        _parseInlineFormatting(line.substring(3), headingStyle, spans);
        spans.add(TextSpan(text: lineSuffix, style: baseStyle));
      } else if (line.startsWith('### ')) {
        final headingStyle = baseStyle.copyWith(
          fontSize: (baseStyle.fontSize ?? 16.0) * 1.15,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        );
        spans.add(const TextSpan(text: '### ', style: invisibleSyntaxStyle));
        _parseInlineFormatting(line.substring(4), headingStyle, spans);
        spans.add(TextSpan(text: lineSuffix, style: baseStyle));
      } else if (line.startsWith('> ')) {
        final quoteStyle = baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: baseStyle.color?.withValues(alpha: 0.85),
        );
        spans.add(const TextSpan(text: '> ', style: invisibleSyntaxStyle));
        _parseInlineFormatting(line.substring(2), quoteStyle, spans);
        spans.add(TextSpan(text: lineSuffix, style: baseStyle));
      } else if (line.startsWith('- [ ] ') || line.startsWith('- [x] ') || line.startsWith('- [X] ')) {
        final prefix = line.substring(0, 6);
        final isChecked = prefix.contains('x') || prefix.contains('X');
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
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ));
        _parseInlineFormatting(line.substring(6), itemStyle, spans);
        spans.add(TextSpan(text: lineSuffix, style: baseStyle));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        spans.add(TextSpan(
          text: '• ',
          style: baseStyle.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ));
        _parseInlineFormatting(line.substring(2), baseStyle, spans);
        spans.add(TextSpan(text: lineSuffix, style: baseStyle));
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final match = RegExp(r'^\d+\.\s').firstMatch(line)!;
        final prefix = match.group(0)!;
        final syntaxStyle = baseStyle.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        );
        spans.add(TextSpan(text: prefix, style: syntaxStyle));
        _parseInlineFormatting(line.substring(prefix.length), baseStyle, spans);
        spans.add(TextSpan(text: lineSuffix, style: baseStyle));
      } else if (line.trim() == '---') {
        final dividerStyle = baseStyle.copyWith(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        );
        spans.add(TextSpan(text: line + lineSuffix, style: dividerStyle));
      } else {
        _parseInlineFormatting(line, baseStyle, spans);
        spans.add(TextSpan(text: lineSuffix, style: baseStyle));
      }
    }

    return TextSpan(children: spans, style: baseStyle);
  }

  void _parseInlineFormatting(
    String text,
    TextStyle lineBaseStyle,
    List<InlineSpan> spans,
  ) {
    if (text.isEmpty) return;

    // Pattern for inline markdown:
    // 1: Bold Italic: ***text***
    // 3: Bold: **text**
    // 5: Italic: *text* (excluding **)
    // 7: Strikethrough: ~~text~~
    // 9: Inline Code: `text`
    // 11: Link: [text](url)
    final pattern = RegExp(
      r'(\*\*\*(.+?)\*\*\*)|'
      r'(\*\*(.+?)\*\*)|'
      r'((?<!\*)\*([^\*\n]+?)\*(?!\*))|'
      r'(~~([^~\n]+?)~~)|'
      r'(`([^`\n]+?)`)|'
      r'(\[([^\]\n]+?)\]\(([^\)\n]+?)\))',
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
        spans.add(TextSpan(
          text: match.group(2),
          style: lineBaseStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ));
        spans.add(const TextSpan(text: '***', style: invisibleSyntaxStyle));
      } else if (match.group(3) != null) {
        // **bold**
        spans.add(const TextSpan(text: '**', style: invisibleSyntaxStyle));
        spans.add(TextSpan(
          text: match.group(4),
          style: lineBaseStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ));
        spans.add(const TextSpan(text: '**', style: invisibleSyntaxStyle));
      } else if (match.group(5) != null) {
        // *italic*
        spans.add(const TextSpan(text: '*', style: invisibleSyntaxStyle));
        spans.add(TextSpan(
          text: match.group(6),
          style: lineBaseStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ));
        spans.add(const TextSpan(text: '*', style: invisibleSyntaxStyle));
      } else if (match.group(7) != null) {
        // ~~strikethrough~~
        spans.add(const TextSpan(text: '~~', style: invisibleSyntaxStyle));
        spans.add(TextSpan(
          text: match.group(8),
          style: lineBaseStyle.copyWith(
            decoration: TextDecoration.lineThrough,
          ),
        ));
        spans.add(const TextSpan(text: '~~', style: invisibleSyntaxStyle));
      } else if (match.group(9) != null) {
        // `code`
        spans.add(const TextSpan(text: '`', style: invisibleSyntaxStyle));
        spans.add(TextSpan(
          text: match.group(10),
          style: lineBaseStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: (lineBaseStyle.color ?? Colors.grey).withValues(alpha: 0.1),
          ),
        ));
        spans.add(const TextSpan(text: '`', style: invisibleSyntaxStyle));
      } else if (match.group(11) != null) {
        // [text](url)
        spans.add(const TextSpan(text: '[', style: invisibleSyntaxStyle));
        spans.add(TextSpan(
          text: match.group(12),
          style: lineBaseStyle.copyWith(
            color: const Color(0xFF2E6B9E),
            decoration: TextDecoration.underline,
          ),
        ));
        spans.add(TextSpan(text: '](${match.group(13)})', style: invisibleSyntaxStyle));
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
