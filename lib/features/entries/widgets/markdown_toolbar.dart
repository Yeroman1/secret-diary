import 'package:flutter/material.dart';
import '../../../shared/utils/phosphor_icons.dart';

class MarkdownToolbar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;

  const MarkdownToolbar({
    super.key,
    required this.controller,
    this.focusNode,
  });

  void _insertFormatting(String prefix, [String suffix = '']) {
    final text = controller.text;
    final selection = controller.selection;

    int start = selection.isValid ? selection.start : text.length;
    int end = selection.isValid ? selection.end : text.length;

    if (start < 0) start = text.length;
    if (end < 0) end = text.length;
    if (start > text.length) start = text.length;
    if (end > text.length) end = text.length;

    if (start > end) {
      final temp = start;
      start = end;
      end = temp;
    }

    final selectedText = text.substring(start, end);
    final replacement = '$prefix$selectedText$suffix';
    final newText = text.replaceRange(start, end, replacement);

    int newCursorStart;
    int newCursorEnd;

    if (selectedText.isEmpty) {
      newCursorStart = start + prefix.length;
      newCursorEnd = newCursorStart;
    } else {
      newCursorStart = start;
      newCursorEnd = start + replacement.length;
    }

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: newCursorStart,
        extentOffset: newCursorEnd,
      ),
    );

    if (focusNode != null && !focusNode!.hasFocus) {
      focusNode!.requestFocus();
    }
  }

  void _insertLinePrefix(String linePrefix) {
    final text = controller.text;
    final selection = controller.selection;

    int start = selection.isValid ? selection.start : text.length;
    if (start < 0 || start > text.length) start = text.length;

    // Check if cursor is at the beginning of a line or after a newline
    final bool isStartOfLine = start == 0 || text[start - 1] == '\n';
    final String actualPrefix = isStartOfLine ? linePrefix : '\n$linePrefix';

    final selectedText = selection.isValid ? text.substring(start, selection.end) : '';
    final replacement = '$actualPrefix$selectedText';
    final newText = text.replaceRange(start, selection.isValid ? selection.end : text.length, replacement);

    final newCursorPosition = start + actualPrefix.length + selectedText.length;

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );

    if (focusNode != null && !focusNode!.hasFocus) {
      focusNode!.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          // Bold
          IconButton(
            icon: Icon(PhosphorIcons.textB(), size: 20),
            tooltip: 'Bold (**text**)',
            onPressed: () => _insertFormatting('**', '**'),
          ),
          // Italic
          IconButton(
            icon: Icon(PhosphorIcons.textItalic(), size: 20),
            tooltip: 'Italic (*text*)',
            onPressed: () => _insertFormatting('*', '*'),
          ),
          // Strikethrough
          IconButton(
            icon: Icon(PhosphorIcons.textStrikethrough(), size: 20),
            tooltip: 'Strikethrough (~~text~~)',
            onPressed: () => _insertFormatting('~~', '~~'),
          ),
          const VerticalDivider(indent: 10, endIndent: 10, width: 12),
          // Header 1
          IconButton(
            icon: Icon(PhosphorIcons.textHOne(), size: 20),
            tooltip: 'Heading 1 (# Title)',
            onPressed: () => _insertLinePrefix('# '),
          ),
          // Bullet List
          IconButton(
            icon: Icon(PhosphorIcons.listBullets(), size: 20),
            tooltip: 'Bullet List (- Item)',
            onPressed: () => _insertLinePrefix('- '),
          ),
          // Numbered List
          IconButton(
            icon: Icon(PhosphorIcons.listNumbers(), size: 20),
            tooltip: 'Numbered List (1. Item)',
            onPressed: () => _insertLinePrefix('1. '),
          ),
          // Quote
          IconButton(
            icon: Icon(PhosphorIcons.quotes(), size: 20),
            tooltip: 'Quote (> Quote)',
            onPressed: () => _insertLinePrefix('> '),
          ),
          // Checklist
          IconButton(
            icon: Icon(PhosphorIcons.checkSquare(), size: 20),
            tooltip: 'Checklist (- [ ] Task)',
            onPressed: () => _insertLinePrefix('- [ ] '),
          ),
          const VerticalDivider(indent: 10, endIndent: 10, width: 12),
          // Code Block
          IconButton(
            icon: Icon(PhosphorIcons.code(), size: 20),
            tooltip: 'Code (`code`)',
            onPressed: () => _insertFormatting('`', '`'),
          ),
          // Horizontal Line Divider
          IconButton(
            icon: Icon(PhosphorIcons.minus(), size: 20),
            tooltip: 'Divider (---)',
            onPressed: () => _insertLinePrefix('---\n'),
          ),
        ],
      ),
    );
  }
}
