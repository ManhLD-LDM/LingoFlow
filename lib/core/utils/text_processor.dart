/// Utility for sanitizing and formatting raw OCR text before sending to translation engines
class TextProcessor {
  /// Cleans OCR text, joins lines appropriately based on language (CJK vs Western)
  static String cleanOcrText(String rawText, {String? language}) {
    if (rawText.trim().isEmpty) return '';

    var text = rawText;

    // Normalize Unicode spaces and line endings
    text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final lang = language?.toLowerCase() ?? 'auto';
    final isCJK = lang == 'ja' || lang == 'zh' || _containsCJK(text);

    if (isCJK) {
      text = _cleanCJKText(text);
    } else {
      text = _cleanWesternText(text);
    }

    return text.trim();
  }

  static bool _containsCJK(String text) {
    return RegExp(r'[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff]').hasMatch(text);
  }

  static String _cleanCJKText(String text) {
    var result = text;

    // Remove spaces between CJK characters
    result = result.replaceAllMapped(
      RegExp(r'([\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff])\s+([\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff])'),
      (match) => '${match[1]}${match[2]}',
    );

    // Merge lines inside Japanese/Chinese speech bubbles without adding spaces
    result = result.replaceAllMapped(
      RegExp(r'([\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff])\n+([\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff])'),
      (match) => '${match[1]}${match[2]}',
    );

    // Clean Japanese quotation marks
    result = result
        .replaceAll(RegExp(r'「\s+'), '「')
        .replaceAll(RegExp(r'\s+」'), '」')
        .replaceAll(RegExp(r'『\s+'), '『')
        .replaceAll(RegExp(r'\s+』'), '』')
        .replaceAll(RegExp(r'（\s+'), '（')
        .replaceAll(RegExp(r'\s+）'), '）');

    // Remove common OCR noise artifacts
    result = result.replaceAll(RegExp(r'[|_~`]+'), ' ');

    return result;
  }

  static String _cleanWesternText(String text) {
    var result = text;

    // Join hyphenated words split across lines (e.g. trans-\nlation -> translation)
    result = result.replaceAllMapped(
      RegExp(r'(\w+)-\n+(\w+)'),
      (match) => '${match[1]}${match[2]}',
    );

    // Replace linebreaks inside paragraphs with space
    result = result.replaceAllMapped(
      RegExp(r'([^\n.])\n+([^\n])'),
      (match) => '${match[1]} ${match[2]}',
    );

    // Collapse multiple spaces
    result = result.replaceAll(RegExp(r'\s{2,}'), ' ');

    return result;
  }
}
