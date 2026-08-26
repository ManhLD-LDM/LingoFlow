import '../../domain/entities/history_item.dart';

enum ExportFormat {
  ankiTsv('Anki Flashcards (.tsv)', 'tsv'),
  csv('Bảng tính Excel / CSV (.csv)', 'csv'),
  plainText('Văn bản thuần (.txt)', 'txt');

  final String label;
  final String extension;
  const ExportFormat(this.label, this.extension);
}

class ExportService {
  /// Converts a list of history/vocabulary items into the requested format string
  static String exportItems(List<HistoryItem> items, ExportFormat format) {
    switch (format) {
      case ExportFormat.ankiTsv:
        return _exportAnkiTsv(items);
      case ExportFormat.csv:
        return _exportCsv(items);
      case ExportFormat.plainText:
        return _exportPlainText(items);
    }
  }

  static String _exportAnkiTsv(List<HistoryItem> items) {
    final buffer = StringBuffer();
    // Header for Anki Deck
    buffer.writeln('#separator:tab');
    buffer.writeln('#html:false');
    buffer.writeln('#tags column:4');
    for (var item in items) {
      final front = item.originalText.replaceAll('\t', ' ').replaceAll('\n', ' ');
      final back = item.translatedText.replaceAll('\t', ' ').replaceAll('\n', ' ');
      final source = item.sourceLanguage;
      final tag = 'LingoFlow_${item.sourceLanguage}_${item.targetLanguage}';
      buffer.writeln('$front\t$back\t$source\t$tag');
    }
    return buffer.toString();
  }

  static String _exportCsv(List<HistoryItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('Original,Translation,SourceLanguage,TargetLanguage,Date');
    for (var item in items) {
      final front = '"${item.originalText.replaceAll('"', '""')}"';
      final back = '"${item.translatedText.replaceAll('"', '""')}"';
      final date = item.timestamp.toIso8601String();
      buffer.writeln('$front,$back,${item.sourceLanguage},${item.targetLanguage},$date');
    }
    return buffer.toString();
  }

  static String _exportPlainText(List<HistoryItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('=== LINGOFLOW VOCABULARY EXPORT ===\n');
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      buffer.writeln('${i + 1}. [${item.sourceLanguage.toUpperCase()}] ${item.originalText}');
      buffer.writeln('   → ${item.translatedText}\n');
    }
    return buffer.toString();
  }
}
