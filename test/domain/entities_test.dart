import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_flow/domain/entities/history_item.dart';
import 'package:lingo_flow/domain/entities/subtitle_style.dart';
import 'package:lingo_flow/domain/entities/translation_engine.dart';
import 'package:lingo_flow/domain/entities/ocr_result.dart';
import 'package:lingo_flow/domain/entities/ocr_engine_mode.dart';

void main() {
  group('Domain Entities Tests', () {
    test('HistoryItem toJson and fromJson roundtrip correctly', () {
      final now = DateTime(2026, 8, 30, 1, 0);
      final item = HistoryItem(
        id: 'test_123',
        originalText: '魔法少女',
        translatedText: 'Cô bé phép thuật',
        sourceLanguage: 'ja',
        targetLanguage: 'vi',
        timestamp: now,
        isFavorite: true,
      );

      final json = item.toJson();
      final restored = HistoryItem.fromJson(json);

      expect(restored.id, equals('test_123'));
      expect(restored.originalText, equals('魔法少女'));
      expect(restored.translatedText, equals('Cô bé phép thuật'));
      expect(restored.sourceLanguage, equals('ja'));
      expect(restored.targetLanguage, equals('vi'));
      expect(restored.timestamp, equals(now));
      expect(restored.isFavorite, isTrue);
    });

    test('SubtitleTheme.fromId maps correctly with fallback', () {
      expect(SubtitleTheme.fromId('cyberpunk'), equals(SubtitleTheme.cyberpunk));
      expect(SubtitleTheme.fromId('classic_yellow'), equals(SubtitleTheme.classicYellow));
      expect(SubtitleTheme.fromId('manga_white'), equals(SubtitleTheme.mangaWhite));
      expect(SubtitleTheme.fromId('minimal_dark'), equals(SubtitleTheme.minimalDark));
      // Fallback
      expect(SubtitleTheme.fromId('non_existent'), equals(SubtitleTheme.cyberpunk));
    });

    test('TranslationEngine.fromId maps correctly with fallback', () {
      expect(TranslationEngine.fromId('google'), equals(TranslationEngine.google));
      expect(TranslationEngine.fromId('deepl'), equals(TranslationEngine.deepl));
      // Fallback
      expect(TranslationEngine.fromId('unknown'), equals(TranslationEngine.google));
    });

    test('OcrEngineMode.fromId maps correctly with fallback', () {
      expect(OcrEngineMode.fromId('auto_fallback'), equals(OcrEngineMode.autoFallback));
      expect(OcrEngineMode.fromId('cloud_only'), equals(OcrEngineMode.cloudOnly));
      expect(OcrEngineMode.fromId('offline_only'), equals(OcrEngineMode.offlineOnly));
      // Fallback
      expect(OcrEngineMode.fromId('invalid_mode'), equals(OcrEngineMode.autoFallback));
    });

    test('OcrResult empty constant is properly structured', () {
      expect(OcrResult.empty.fullText, isEmpty);
      expect(OcrResult.empty.blocks, isEmpty);
      expect(OcrResult.empty.imageWidth, equals(0));
      expect(OcrResult.empty.imageHeight, equals(0));
    });
  });
}
