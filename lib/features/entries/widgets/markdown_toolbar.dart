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

  void _toggleWrapFormatting(String openMarker, [String? closeMarker]) {
    final close = closeMarker ?? openMarker;
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

    final openLen = openMarker.length;
    final closeLen = close.length;

    // CASE 1: Text is selected
    if (start != end) {
      final selectedText = text.substring(start, end);

      // Check 1A: Selected text is already wrapped directly with this format (e.g. "**hello**" or "<u>hello</u>")
      final isDirectItalic = openMarker == '*' &&
          selectedText.length >= 2 &&
          selectedText.startsWith('*') &&
          selectedText.endsWith('*') &&
          (!selectedText.startsWith('**') || selectedText.startsWith('***'));

      final isDirectBold = openMarker == '**' &&
          selectedText.length >= 4 &&
          selectedText.startsWith('**') &&
          selectedText.endsWith('**');

      final isDirectOther = (openMarker != '*' && openMarker != '**') &&
          selectedText.length >= openLen + closeLen &&
          selectedText.startsWith(openMarker) &&
          selectedText.endsWith(close);

      if (isDirectItalic || isDirectBold || isDirectOther) {
        // Special case for bold vs bold-italic: if toggling italic on '***text***', leaves '**text**'
        if (openMarker == '*' && selectedText.startsWith('***') && selectedText.endsWith('***') && selectedText.length >= 6) {
          final unwrapped = selectedText.substring(1, selectedText.length - 1);
          final newText = text.replaceRange(start, end, unwrapped);
          controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: start + unwrapped.length),
          );
          _refocus();
          return;
        }
        // Special case for bold on '***text***', leaves '*text*'
        if (openMarker == '**' && selectedText.startsWith('***') && selectedText.endsWith('***') && selectedText.length >= 6) {
          final inner = selectedText.substring(3, selectedText.length - 3);
          final unwrapped = '*$inner*';
          final newText = text.replaceRange(start, end, unwrapped);
          controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: start + unwrapped.length),
          );
          _refocus();
          return;
        }

        final unwrapped = selectedText.substring(openLen, selectedText.length - closeLen);
        final newText = text.replaceRange(start, end, unwrapped);
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: start + unwrapped.length,
          ),
        );
        _refocus();
        return;
      }

      // Check 1B: Surrounding text in parent string has the markers directly outside selection (e.g. "**|hello|**" or "<u>|hello|</u>")
      bool isSurrounded = false;
      if (openMarker == '*') {
        final beforeHasSingleStar = start >= 1 && text.substring(start - 1, start) == '*' &&
            (start < 2 || text.substring(start - 2, start - 1) != '*');
        final afterHasSingleStar = end + 1 <= text.length && text.substring(end, end + 1) == '*' &&
            (end + 2 > text.length || text.substring(end + 1, end + 2) != '*');
        isSurrounded = beforeHasSingleStar && afterHasSingleStar;
      } else if (openMarker == '**') {
        isSurrounded = start >= 2 && end + 2 <= text.length &&
            text.substring(start - 2, start) == '**' &&
            text.substring(end, end + 2) == '**';
      } else {
        isSurrounded = start >= openLen && end + closeLen <= text.length &&
            text.substring(start - openLen, start) == openMarker &&
            text.substring(end, end + closeLen) == close;
      }

      if (isSurrounded) {
        final newText = text.replaceRange(start - openLen, end + closeLen, selectedText);
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: start - openLen + selectedText.length,
          ),
        );
        _refocus();
        return;
      }

      // Check 1C: Nested inside selection (e.g. "**<u>hello</u>**" when toggling Underline, or "<u>**hello**</u>" when toggling Bold)
      if (openMarker == '<u>' && selectedText.toLowerCase().contains('<u>') && selectedText.toLowerCase().contains('</u>')) {
        final openIdx = selectedText.toLowerCase().indexOf('<u>');
        final closeIdx = selectedText.toLowerCase().lastIndexOf('</u>');
        if (openIdx != -1 && closeIdx != -1 && closeIdx > openIdx) {
          final beforeMarker = selectedText.substring(0, openIdx);
          final innerContent = selectedText.substring(openIdx + 3, closeIdx);
          final afterMarker = selectedText.substring(closeIdx + 4);
          final unwrapped = '$beforeMarker$innerContent$afterMarker';
          final newText = text.replaceRange(start, end, unwrapped);
          controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: start + unwrapped.length),
          );
          _refocus();
          return;
        }
      } else if (openMarker == '~~' && selectedText.contains('~~')) {
        final openIdx = selectedText.indexOf('~~');
        final closeIdx = selectedText.lastIndexOf('~~');
        if (openIdx != -1 && closeIdx != -1 && closeIdx > openIdx + 1) {
          final beforeMarker = selectedText.substring(0, openIdx);
          final innerContent = selectedText.substring(openIdx + 2, closeIdx);
          final afterMarker = selectedText.substring(closeIdx + 2);
          final unwrapped = '$beforeMarker$innerContent$afterMarker';
          final newText = text.replaceRange(start, end, unwrapped);
          controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: start + unwrapped.length),
          );
          _refocus();
          return;
        }
      } else if (openMarker == '**') {
        // If selection has '**' inside, e.g. "<u>**hello**</u>"
        final boldMatch = RegExp(r'(?<!\*)\*\*(.*?)\*\*(?!\*)').firstMatch(selectedText);
        if (boldMatch != null && (boldMatch.start > 0 || boldMatch.end < selectedText.length)) {
          final unwrapped = selectedText.substring(0, boldMatch.start) + boldMatch.group(1)! + selectedText.substring(boldMatch.end);
          final newText = text.replaceRange(start, end, unwrapped);
          controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: start + unwrapped.length),
          );
          _refocus();
          return;
        }
      } else if (openMarker == '*') {
        // If selection has isolated single '*' inside, e.g. "<u>*hello*</u>"
        final italicMatch = RegExp(r'(?<!\*)\*([^\*]+)\*(?!\*)').firstMatch(selectedText);
        if (italicMatch != null && (italicMatch.start > 0 || italicMatch.end < selectedText.length)) {
          final unwrapped = selectedText.substring(0, italicMatch.start) + italicMatch.group(1)! + selectedText.substring(italicMatch.end);
          final newText = text.replaceRange(start, end, unwrapped);
          controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: start + unwrapped.length),
          );
          _refocus();
          return;
        }
      }

      // Check 1D: Wrap selected text with combination support
      // If toggling italic and selection is already bold '**text**' -> '***text***'
      if (openMarker == '*' && selectedText.startsWith('**') && selectedText.endsWith('**') && selectedText.length >= 4) {
        final inner = selectedText.substring(2, selectedText.length - 2);
        final wrapped = '***$inner***';
        final newText = text.replaceRange(start, end, wrapped);
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start + wrapped.length),
        );
        _refocus();
        return;
      }

      // If toggling bold and selection is already italic '*text*' -> '***text***'
      if (openMarker == '**' && selectedText.startsWith('*') && selectedText.endsWith('*') && !selectedText.startsWith('**')) {
        final inner = selectedText.substring(1, selectedText.length - 1);
        final wrapped = '***$inner***';
        final newText = text.replaceRange(start, end, wrapped);
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start + wrapped.length),
        );
        _refocus();
        return;
      }

      final wrapped = '$openMarker$selectedText$close';
      final newText = text.replaceRange(start, end, wrapped);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: start + openLen + selectedText.length + closeLen,
        ),
      );
      _refocus();
      return;
    }

    // CASE 2: No selection (cursor is at a single point)
    // Check 2A: Empty marker combos at cursor
    final beforeCursorExact = text.substring(0, start);
    final afterCursorExact = text.substring(start);

    // Empty underline <u>|</u> -> delete
    if (openMarker == '<u>' && beforeCursorExact.endsWith('<u>') && afterCursorExact.startsWith('</u>')) {
      final newText = text.replaceRange(start - 3, start + 4, '');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start - 3),
      );
      _refocus();
      return;
    }

    // Empty bold-italic ***|*** -> toggling italic leaves **|**, toggling bold leaves *|*
    if (beforeCursorExact.endsWith('***') && afterCursorExact.startsWith('***')) {
      if (openMarker == '*') {
        final newText = text.replaceRange(start - 1, start + 1, '');
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start - 1),
        );
        _refocus();
        return;
      } else if (openMarker == '**') {
        final newText = text.replaceRange(start - 2, start + 2, '');
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start - 2),
        );
        _refocus();
        return;
      }
    }

    // Empty bold **|** -> toggling bold deletes ****; clicking italic turns into ***|***; clicking underline turns into **<u>|</u>**
    if (beforeCursorExact.endsWith('**') && afterCursorExact.startsWith('**') &&
        !beforeCursorExact.endsWith('***') && !afterCursorExact.startsWith('***')) {
      if (openMarker == '**') {
        final newText = text.replaceRange(start - 2, start + 2, '');
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start - 2),
        );
        _refocus();
        return;
      } else if (openMarker == '*') {
        final newText = '${text.substring(0, start)}**${text.substring(start)}';
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start + 1),
        );
        _refocus();
        return;
      } else if (openMarker == '<u>') {
        final newText = text.replaceRange(start, start, '<u></u>');
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start + 3),
        );
        _refocus();
        return;
      }
    }

    // Empty italic *|* -> toggling italic deletes **; clicking bold turns into ***|***; clicking underline turns into *<u>|</u>*
    if (beforeCursorExact.endsWith('*') && afterCursorExact.startsWith('*') &&
        !beforeCursorExact.endsWith('**') && !afterCursorExact.startsWith('**')) {
      if (openMarker == '*') {
        final newText = text.replaceRange(start - 1, start + 1, '');
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start - 1),
        );
        _refocus();
        return;
      } else if (openMarker == '**') {
        final newText = '${text.substring(0, start)}****${text.substring(start)}';
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start + 2),
        );
        _refocus();
        return;
      } else if (openMarker == '<u>') {
        final newText = text.replaceRange(start, start, '<u></u>');
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: start + 3),
        );
        _refocus();
        return;
      }
    }

    // Generic direct empty markers (e.g. ~~|~~, `|`)
    if (start >= openLen &&
        start + closeLen <= text.length &&
        text.substring(start - openLen, start) == openMarker &&
        text.substring(start, start + closeLen) == close) {
      final newText = text.replaceRange(start - openLen, start + closeLen, '');
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start - openLen),
      );
      _refocus();
      return;
    }

    // Check 2B: Cursor is inside a formatted word on the line -> step-out or unwrap
    final lineStart = text.lastIndexOf('\n', start > 0 ? start - 1 : 0);
    final lineStartIndex = lineStart == -1 ? 0 : lineStart + 1;
    final lineEnd = text.indexOf('\n', start);
    final lineEndIndex = lineEnd == -1 ? text.length : lineEnd;

    final beforeCursor = text.substring(lineStartIndex, start);
    final afterCursor = text.substring(start, lineEndIndex);

    final lastOpen = beforeCursor.lastIndexOf(openMarker);
    final firstClose = afterCursor.indexOf(close);

    if (lastOpen != -1 && firstClose != -1) {
      final actualOpen = lineStartIndex + lastOpen;
      final actualClose = start + firstClose;

      // If cursor is at the boundary of the closing marker (e.g. "**test|**"), step out so user can continue typing normal text
      if (firstClose == 0) {
        controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: start + closeLen),
        );
        _refocus();
        return;
      }

      final word = text.substring(actualOpen + openLen, actualClose);
      final newText = text.replaceRange(actualOpen, actualClose + closeLen, word);
      final newCursorOffset = (start - openLen).clamp(actualOpen, actualOpen + word.length);

      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursorOffset),
      );
      _refocus();
      return;
    }

    // Check 2C: Insert markers and place cursor between them to start typing in that style!
    final replacement = '$openMarker$close';
    final newText = text.replaceRange(start, start, replacement);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + openLen),
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
      selection: TextSelection.collapsed(offset: newCursor),
    );

    _refocus();
  }

  void _refocus() {
    if (focusNode != null && !focusNode!.hasFocus) {
      focusNode!.requestFocus();
    }
  }

  Widget _buildToolbarButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final activeBg = theme.colorScheme.primary.withValues(alpha: 0.15);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.75);

    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        child: Material(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: isActive
                    ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.35), width: 1)
                    : Border.all(color: Colors.transparent, width: 1),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 20,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToolbarStyleState _computeStyleState(TextEditingValue value) {
    final text = value.text;
    if (text.isEmpty) return const _ToolbarStyleState();

    final selection = value.selection;
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

    // Find line boundaries
    final lineStart = text.lastIndexOf('\n', start > 0 ? start - 1 : 0);
    final lineStartIndex = lineStart == -1 ? 0 : lineStart + 1;
    final lineEnd = text.indexOf('\n', start);
    final lineEndIndex = lineEnd == -1 ? text.length : lineEnd;
    final currentLine = text.substring(lineStartIndex, lineEndIndex);

    // Line-level checks
    final isH1 = currentLine.startsWith('# ');
    final isH2 = currentLine.startsWith('## ');
    final isH3 = currentLine.startsWith('### ');
    final isQuote = currentLine.startsWith('> ') || currentLine == '>';
    final isChecklist = currentLine.startsWith('- [ ] ') || currentLine.startsWith('- [x] ') || currentLine.startsWith('- [X] ');
    final isBulletList = (currentLine.startsWith('- ') || currentLine.startsWith('* ') || currentLine.startsWith('+ ')) && !isChecklist;
    final isNumberedList = RegExp(r'^\d+\.\s').hasMatch(currentLine);

    bool isBold = false;
    bool isItalic = false;
    bool isUnderline = false;
    bool isStrikethrough = false;
    bool isCode = false;

    if (start != end) {
      // Selection mode
      final selectedText = text.substring(start, end);

      if (selectedText.contains('**') || (start >= 2 && end + 2 <= text.length && text.substring(start - 2, start) == '**' && text.substring(end, end + 2) == '**')) {
        isBold = true;
      }
      if (selectedText.toLowerCase().contains('<u>') || (start >= 3 && end + 4 <= text.length && text.substring(start - 3, start).toLowerCase() == '<u>' && text.substring(end, end + 4).toLowerCase() == '</u>')) {
        isUnderline = true;
      }
      if (selectedText.contains('~~') || (start >= 2 && end + 2 <= text.length && text.substring(start - 2, start) == '~~' && text.substring(end, end + 2) == '~~')) {
        isStrikethrough = true;
      }
      if (selectedText.contains('`') || (start >= 1 && end + 1 <= text.length && text.substring(start - 1, start) == '`' && text.substring(end, end + 1) == '`')) {
        isCode = true;
      }
      if (selectedText.startsWith('***') && selectedText.endsWith('***')) {
        isBold = true;
        isItalic = true;
      } else if (RegExp(r'(?<!\*)\*([^\*]+)\*(?!\*)').hasMatch(selectedText) ||
          (start >= 1 && end + 1 <= text.length && text.substring(start - 1, start) == '*' &&
              (start < 2 || text.substring(start - 2, start - 1) != '*') &&
              text.substring(end, end + 1) == '*' &&
              (end + 2 > text.length || text.substring(end + 1, end + 2) != '*'))) {
        isItalic = true;
      }
    } else {
      // Cursor mode on current line
      final cursorInLine = start - lineStartIndex;

      void inspectInline(String segment, int segOffset) {
        if (segment.isEmpty) return;

        final pattern = RegExp(
          r'(\*\*\*(.*?)\*\*\*)|'
          r'(___(.*?)___)|'
          r'(\*\*(.*?)\*\*)|'
          r'(__([^_]*?)__)|'
          r'(<(?:b|strong)\b[^>]*>(.*?)</(?:b|strong)>)|'
          r'(<(?:u|ins)\b[^>]*>(.*?)</(?:u|ins)>)|'
          r'((?<!\*)\*([^\*\n]+?)(?<!\*)\*(?!\*))|'
          r'((?<!_)_([^_\n]+?)(?<!_)_(?!_))|'
          r'(<(?:i|em)\b[^>]*>(.*?)</(?:i|em)>)|'
          r'(~~([^~\n]*?)~~)|'
          r'(<(?:del|s)\b[^>]*>(.*?)</(?:del|s)>)|'
          r'(`([^`\n]*?)`)',
          caseSensitive: false,
        );

        for (final match in pattern.allMatches(segment)) {
          final matchStart = segOffset + match.start;
          final matchEnd = segOffset + match.end;

          if (cursorInLine >= matchStart && cursorInLine <= matchEnd) {
            if (match.group(1) != null || match.group(3) != null) {
              isBold = true;
              isItalic = true;
              final inner = match.group(2) ?? match.group(4) ?? '';
              inspectInline(inner, matchStart + 3);
            } else if (match.group(5) != null || match.group(7) != null) {
              isBold = true;
              final inner = match.group(6) ?? match.group(8) ?? '';
              inspectInline(inner, matchStart + 2);
            } else if (match.group(9) != null) {
              isBold = true;
              final fullMatch = match.group(9)!;
              final inner = match.group(10) ?? '';
              final openEnd = fullMatch.indexOf('>') + 1;
              inspectInline(inner, matchStart + openEnd);
            } else if (match.group(11) != null) {
              isUnderline = true;
              final fullMatch = match.group(11)!;
              final inner = match.group(12) ?? '';
              final openEnd = fullMatch.indexOf('>') + 1;
              inspectInline(inner, matchStart + openEnd);
            } else if (match.group(13) != null || match.group(15) != null) {
              isItalic = true;
              final inner = match.group(14) ?? match.group(16) ?? '';
              inspectInline(inner, matchStart + 1);
            } else if (match.group(17) != null) {
              isItalic = true;
              final fullMatch = match.group(17)!;
              final inner = match.group(18) ?? '';
              final openEnd = fullMatch.indexOf('>') + 1;
              inspectInline(inner, matchStart + openEnd);
            } else if (match.group(19) != null) {
              isStrikethrough = true;
              final inner = match.group(20) ?? '';
              inspectInline(inner, matchStart + 2);
            } else if (match.group(21) != null) {
              isStrikethrough = true;
              final fullMatch = match.group(21)!;
              final inner = match.group(22) ?? '';
              final openEnd = fullMatch.indexOf('>') + 1;
              inspectInline(inner, matchStart + openEnd);
            } else if (match.group(23) != null) {
              isCode = true;
            }
          }
        }
      }

      inspectInline(currentLine, 0);
    }

    return _ToolbarStyleState(
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
      isStrikethrough: isStrikethrough,
      isCode: isCode,
      isH1: isH1,
      isH2: isH2,
      isH3: isH3,
      isBulletList: isBulletList,
      isNumberedList: isNumberedList,
      isChecklist: isChecklist,
      isQuote: isQuote,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final styleState = _computeStyleState(controller.value);

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
              _buildToolbarButton(
                context: context,
                icon: PhosphorIcons.textB(),
                tooltip: 'Bold',
                isActive: styleState.isBold,
                onPressed: () => _toggleWrapFormatting('**'),
              ),
              // Italic
              _buildToolbarButton(
                context: context,
                icon: PhosphorIcons.textItalic(),
                tooltip: 'Italic',
                isActive: styleState.isItalic,
                onPressed: () => _toggleWrapFormatting('*'),
              ),
              // Underline
              _buildToolbarButton(
                context: context,
                icon: PhosphorIcons.textUnderline(),
                tooltip: 'Underline',
                isActive: styleState.isUnderline,
                onPressed: () => _toggleWrapFormatting('<u>', '</u>'),
              ),
              // Strikethrough
              _buildToolbarButton(
                context: context,
                icon: PhosphorIcons.textStrikethrough(),
                tooltip: 'Strikethrough',
                isActive: styleState.isStrikethrough,
                onPressed: () => _toggleWrapFormatting('~~'),
              ),
              // Code inline
              _buildToolbarButton(
                context: context,
                icon: PhosphorIcons.code(),
                tooltip: 'Inline Code',
                isActive: styleState.isCode,
                onPressed: () => _toggleWrapFormatting('`'),
              ),
              const VerticalDivider(indent: 10, endIndent: 10, width: 12),
              // Header 1
              _buildToolbarButton(
                context: context,
                icon: PhosphorIcons.textHOne(),
                tooltip: 'Heading 1',
                isActive: styleState.isH1,
                onPressed: () => _toggleLinePrefix('# '),
              ),
              // Header 2
              _buildToolbarButton(
                context: context,
                icon: PhosphorIcons.textHTwo(),
                tooltip: 'Heading 2',
                isActive: styleState.isH2,
                onPressed: () => _toggleLinePrefix('## '),
              ),
              // Header 3
              _buildToolbarButton(
                context: context,
                icon: PhosphorIcons.textHThree(),
                tooltip: 'Heading 3',
                isActive: styleState.isH3,
                onPressed: () => _toggleLinePrefix('### '),
              ),
              const VerticalDivider(indent: 10, endIndent: 10, width: 12),
              // Bullet List
              _buildToolbarButton(
                context: context,
                icon: PhosphorIcons.listBullets(),
                tooltip: 'Bullet List',
                isActive: styleState.isBulletList,
                onPressed: () => _toggleLinePrefix('- '),
              ),
              // Numbered List
              _buildToolbarButton(
                context: context,
                icon: PhosphorIcons.listNumbers(),
                tooltip: 'Numbered List',
                isActive: styleState.isNumberedList,
                onPressed: () => _toggleLinePrefix('1. '),
              ),
              // Checklist
              _buildToolbarButton(
                context: context,
                icon: PhosphorIcons.checkSquare(),
                tooltip: 'Checklist',
                isActive: styleState.isChecklist,
                onPressed: () => _toggleLinePrefix('- [ ] '),
              ),
              // Quote
              _buildToolbarButton(
                context: context,
                icon: PhosphorIcons.quotes(),
                tooltip: 'Quote',
                isActive: styleState.isQuote,
                onPressed: () => _toggleLinePrefix('> '),
              ),
              // Horizontal Line Divider
              _buildToolbarButton(
                context: context,
                icon: PhosphorIcons.minus(),
                tooltip: 'Divider',
                isActive: false,
                onPressed: () => _toggleLinePrefix('---\n'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ToolbarStyleState {
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrikethrough;
  final bool isCode;
  final bool isH1;
  final bool isH2;
  final bool isH3;
  final bool isBulletList;
  final bool isNumberedList;
  final bool isChecklist;
  final bool isQuote;

  const _ToolbarStyleState({
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.isCode = false,
    this.isH1 = false,
    this.isH2 = false,
    this.isH3 = false,
    this.isBulletList = false,
    this.isNumberedList = false,
    this.isChecklist = false,
    this.isQuote = false,
  });
}
