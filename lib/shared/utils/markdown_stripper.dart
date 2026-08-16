class MarkdownStripper {
  /// Strips common Markdown formatting symbols to return plain text snippet.
  static String strip(String markdown) {
    if (markdown.isEmpty) return '';

    String text = markdown;

    // Headers #
    text = text.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    // Bold / Italics * or _
    text = text.replaceAll(RegExp(r'\*{1,3}|_{1,3}'), '');
    // Links [text](url) -> text
    text = text.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1');
    // Inline code `code`
    text = text.replaceAll(RegExp(r'`{1,3}[^`]*`{1,3}'), '');
    // Blockquotes >
    text = text.replaceAll(RegExp(r'^\s*>\s+', multiLine: true), '');
    // Unordered lists - * +
    text = text.replaceAll(RegExp(r'^\s*[\-\*\+]\s+', multiLine: true), '');
    // Ordered lists 1.
    text = text.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
    // Checkbox items [ ] or [x]
    text = text.replaceAll(RegExp(r'\[[ xX]\]\s*'), '');

    return text.replaceAll(RegExp(r'\n+'), ' ').trim();
  }
}
