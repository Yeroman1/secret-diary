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

  void _toggleWrapFormatting(String marker) {
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

    final mLen = marker.length;

    // CASE 1: Text is selected
    if (start != end) {
      final selectedText = text.substring(start, end);

      // Check A: Selected text itself starts and ends with marker (e.g. "**hello**")
      if (selectedText.length >= mLen * 2 &&
          selectedText.startsWith(marker) &&
          selectedText.endsWith(marker)) {
        final unwrapped = selectedText.substring(mLen, selectedText.length - mLen);
        final newText = text.replaceRange(start, end, unwrapped);
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection(
            baseOffset: start,
            extentOffset: start + unwrapped.length,
          ),
        );
        _refocus();
        return;
      }

      // Check B: Surrounding text in parent string has the markers (e.g. "**|hello|**")
      if (start >= mLen &&
          end + mLen <= text.length &&
          text.substring(start - mLen, start) == marker &&
          text.substring(end, end + mLen) == marker) {
        final newText = text.replaceRange(start - mLen, end + mLen, selectedText);
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection(
            baseOffset: start - mLen,
            extentOffset: start - mLen + selectedText.length,
          ),
        );
        _refocus();
        return;
      }

      // Check C: Wrap selected text
      final wrapped = '$marker$selectedText$marker';
      final newText = text.replaceRange(start, end, wrapped);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: start + mLen,
          extentOffset: start + mLen + selectedText.length,
        ),
      );
      _refocus();
      return;
    }

    // CASE 2: No selection (cursor is at a single point)
    // Check A: Cursor is between empty markers (e.g. "**|**") -> delete empty markers
    if (start >= mLen &&
        start + mLen <= text.length &&
        text.substring(start - mLen, start) == marker &&
        text.substring(start, start + mLen) == marker) {
      final newText = text.replaceRange(start - mLen, start + mLen, '');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start - mLen),
      );
      _refocus();
      return;
    }

    // Check B: Cursor is inside a formatted word on the line (e.g. "**he|llo**") -> unwrap
    final lineStart = text.lastIndexOf('\n', start > 0 ? start - 1 : 0);
    final lineStartIndex = lineStart == -1 ? 0 : lineStart + 1;
    final lineEnd = text.indexOf('\n', start);
    final lineEndIndex = lineEnd == -1 ? text.length : lineEnd;

    final beforeCursor = text.substring(lineStartIndex, start);
    final afterCursor = text.substring(start, lineEndIndex);

    final lastOpen = beforeCursor.lastIndexOf(marker);
    final firstClose = afterCursor.indexOf(marker);

    if (lastOpen != -1 && firstClose != -1) {
      final actualOpen = lineStartIndex + lastOpen;
      final actualClose = start + firstClose;

      final word = text.substring(actualOpen + mLen, actualClose);
      final newText = text.replaceRange(actualOpen, actualClose + mLen, word);
      final newCursorOffset = (start - mLen).clamp(actualOpen, actualOpen + word.length);

      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorOffset),
      );
      _refocus();
      return;
    }

    // Check C: Insert markers and place cursor between them to start typing in that style!
    final replacement = '$marker$marker';
    final newText = text.replaceRange(start, start, replacement);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + mLen),
    );
    _refocus();
  }

  void _toggleLinePrefix(String linePrefix) {
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

    // Special case for horizontal divider
    if (linePrefix == '---\n') {
      final isStartOfLine = start == 0 || text[start - 1] == '\n';
      final divider = isStartOfLine ? '---\n' : '\n---\n';
      final newText = text.replaceRange(start, end, divider);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + divider.length),
      );
      _refocus();
      return;
    }

    // Find start of the first selected line
    final firstLineStart = start == 0 ? 0 : (text.lastIndexOf('\n', start - 1) == -1 ? 0 : text.lastIndexOf('\n', start - 1) + 1);
    // Find end of the last selected line
    final lastLineEnd = text.indexOf('\n', end) == -1 ? text.length : text.indexOf('\n', end);

    final affectedBlock = text.substring(firstLineStart, lastLineEnd);
    final lines = affectedBlock.split('\n');

    final cleanPrefix = linePrefix.trimRight();
    final isListOrHeading = cleanPrefix.startsWith('#') ||
        cleanPrefix.startsWith('-') ||
        cleanPrefix.startsWith('>') ||
        cleanPrefix.startsWith('1.');

    // Check if all affected lines already have this prefix
    final allHavePrefix = lines.every((l) => l.startsWith(linePrefix) || (l.trim() == cleanPrefix && l.isNotEmpty));

    final newLines = <String>[];
    for (final line in lines) {
      if (allHavePrefix) {
        // Toggle OFF
        if (line.startsWith(linePrefix)) {
          newLines.add(line.substring(linePrefix.length));
        } else if (line.startsWith(cleanPrefix)) {
          newLines.add(line.substring(cleanPrefix.length).trimLeft());
        } else {
          newLines.add(line);
        }
      } else {
        // Toggle ON
        String sanitized = line;
        if (isListOrHeading) {
          sanitized = line.replaceFirst(RegExp(r'^(#{1,6}\s+|- \[\s?[xX]?\]\s+|- |\* |\d+\.\s+|> )'), '');
        }
        newLines.add('$linePrefix$sanitized');
      }
    }

    final newBlock = newLines.join('\n');
    final newText = text.replaceRange(firstLineStart, lastLineEnd, newBlock);

    final newCursor = firstLineStart + newBlock.length;
    controller.value = TextEditingValue(
      text: newText,
      selection: start == end
          ? TextSelection.collapsed(offset: newCursor)
          : TextSelection(baseOffset: firstLineStart, extentOffset: newCursor),
    );

    _refocus();
  }

  void _refocus() {
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
            tooltip: 'Bold',
            onPressed: () => _toggleWrapFormatting('**'),
          ),
          // Italic
          IconButton(
            icon: Icon(PhosphorIcons.textItalic(), size: 20),
            tooltip: 'Italic',
            onPressed: () => _toggleWrapFormatting('*'),
          ),
          // Strikethrough
          IconButton(
            icon: Icon(PhosphorIcons.textStrikethrough(), size: 20),
            tooltip: 'Strikethrough',
            onPressed: () => _toggleWrapFormatting('~~'),
          ),
          // Code inline
          IconButton(
            icon: Icon(PhosphorIcons.code(), size: 20),
            tooltip: 'Inline Code',
            onPressed: () => _toggleWrapFormatting('`'),
          ),
          const VerticalDivider(indent: 10, endIndent: 10, width: 12),
          // Header 1
          IconButton(
            icon: Icon(PhosphorIcons.textHOne(), size: 20),
            tooltip: 'Heading 1',
            onPressed: () => _toggleLinePrefix('# '),
          ),
          // Header 2
          IconButton(
            icon: Icon(PhosphorIcons.textHTwo(), size: 20),
            tooltip: 'Heading 2',
            onPressed: () => _toggleLinePrefix('## '),
          ),
          // Header 3
          IconButton(
            icon: Icon(PhosphorIcons.textHThree(), size: 20),
            tooltip: 'Heading 3',
            onPressed: () => _toggleLinePrefix('### '),
          ),
          const VerticalDivider(indent: 10, endIndent: 10, width: 12),
          // Bullet List
          IconButton(
            icon: Icon(PhosphorIcons.listBullets(), size: 20),
            tooltip: 'Bullet List',
            onPressed: () => _toggleLinePrefix('- '),
          ),
          // Numbered List
          IconButton(
            icon: Icon(PhosphorIcons.listNumbers(), size: 20),
            tooltip: 'Numbered List',
            onPressed: () => _toggleLinePrefix('1. '),
          ),
          // Checklist
          IconButton(
            icon: Icon(PhosphorIcons.checkSquare(), size: 20),
            tooltip: 'Checklist',
            onPressed: () => _toggleLinePrefix('- [ ] '),
          ),
          // Quote
          IconButton(
            icon: Icon(PhosphorIcons.quotes(), size: 20),
            tooltip: 'Quote',
            onPressed: () => _toggleLinePrefix('> '),
          ),
          // Horizontal Line Divider
          IconButton(
            icon: Icon(PhosphorIcons.minus(), size: 20),
            tooltip: 'Divider',
            onPressed: () => _toggleLinePrefix('---\n'),
          ),
        ],
      ),
    );
  }
}
