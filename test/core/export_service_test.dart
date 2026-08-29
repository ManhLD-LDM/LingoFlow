import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_flow/core/services/export_service.dart';
import 'package:lingo_flow/domain/entities/history_item.dart';

void main() {
  group('ExportService Tests', () {
    final sampleItems = [
      HistoryItem(
        id: '1',
        originalText: 'こんにちは',
        translatedText: 'Xin chào',
        sourceLanguage: 'ja',
        targetLanguage: 'vi',
        timestamp: DateTime(2026, 1, 1, 12, 0),
        isFavorite: true,
      ),
      HistoryItem(
        id: '2',
        originalText: 'ありがとう',
        translatedText: 'Cảm ơn',
        sourceLanguage: 'ja',
        targetLanguage: 'vi',
        timestamp: DateTime(2026, 1, 2, 14, 30),
        isFavorite: false,
      ),
    ];

    test('exports correctly to Anki TSV format', () {
      final tsv = ExportService.exportItems(sampleItems, ExportFormat.ankiTsv);

      expect(tsv, contains('#separator:tab'));
      expect(tsv, contains('#html:false'));
      expect(tsv, contains('こんにちは\tXin chào\tja\tLingoFlow_ja_vi'));
      expect(tsv, contains('ありがとう\tCảm ơn\tja\tLingoFlow_ja_vi'));
    });

    test('exports correctly to CSV format', () {
      final csv = ExportService.exportItems(sampleItems, ExportFormat.csv);

      expect(csv, contains('Original,Translation,SourceLanguage,TargetLanguage,Date'));
      expect(csv, contains('"こんにちは","Xin chào",ja,vi,2026-01-01T12:00:00.000'));
      expect(csv, contains('"ありがとう","Cảm ơn",ja,vi,2026-01-02T14:30:00.000'));
    });

    test('exports correctly to plain text format', () {
      final txt = ExportService.exportItems(sampleItems, ExportFormat.plainText);

      expect(txt, contains('=== LINGOFLOW VOCABULARY EXPORT ==='));
      expect(txt, contains('1. [JA] こんにちは'));
      expect(txt, contains('   → Xin chào'));
      expect(txt, contains('2. [JA] ありがとう'));
      expect(txt, contains('   → Cảm ơn'));
    });

    test('handles empty list export gracefully', () {
      final tsv = ExportService.exportItems([], ExportFormat.ankiTsv);
      expect(tsv, contains('#separator:tab'));

      final csv = ExportService.exportItems([], ExportFormat.csv);
      expect(csv, contains('Original,Translation,SourceLanguage,TargetLanguage,Date'));

      final txt = ExportService.exportItems([], ExportFormat.plainText);
      expect(txt, contains('=== LINGOFLOW VOCABULARY EXPORT ==='));
    });
  });
}
