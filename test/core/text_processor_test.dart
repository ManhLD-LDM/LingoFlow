import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_flow/core/utils/text_processor.dart';

void main() {
  group('TextProcessor Tests', () {
    test('cleans and merges CJK characters across spaces and newlines', () {
      const input = 'こん にちは\n世界';
      final result = TextProcessor.cleanOcrText(input, language: 'ja');
      expect(result, equals('こんにちは世界'));
    });

    test('cleans Japanese dialogue quotation marks properly', () {
      const input = '「  俺は海賊王になる男だ！  」';
      final result = TextProcessor.cleanOcrText(input, language: 'ja');
      expect(result, equals('「俺は海賊王になる男だ！」'));
    });

    test('removes OCR noise artifacts like pipes, underscores, and tildes', () {
      const input = '| これは_テスト~です `';
      final result = TextProcessor.cleanOcrText(input, language: 'ja');
      expect(result, equals('これは テスト です'));
    });

    test('dehyphenates broken English words across lines', () {
      const input = 'This is a trans-\nlation test for multi-\nline text.';
      final result = TextProcessor.cleanOcrText(input, language: 'en');
      expect(result, equals('This is a translation test for multiline text.'));
    });

    test('replaces soft linebreaks in Western text with spaces', () {
      const input = 'First line\nsecond line\nthird line.';
      final result = TextProcessor.cleanOcrText(input, language: 'en');
      expect(result, equals('First line second line third line.'));
    });

    test('handles empty or whitespace-only inputs gracefully', () {
      expect(TextProcessor.cleanOcrText(''), equals(''));
      expect(TextProcessor.cleanOcrText('   \n\t  '), equals(''));
    });

    test('applyGlossary replaces matched terms respecting longer match precedence', () {
      final glossary = {
        'HP': 'Máu (HP)',
        'Max HP': 'Máu Tối Đa',
        '宝具': 'Noble Phantasm (Bảo Khí)',
      };
      const text = 'Nhân vật có Max HP là 5000, HP hiện tại 2000. Dùng 宝具 ngay!';
      final result = TextProcessor.applyGlossary(text, glossary);

      expect(result, equals('Nhân vật có Máu Tối Đa là 5000, Máu (HP) hiện tại 2000. Dùng Noble Phantasm (Bảo Khí) ngay!'));
    });

    test('applyGlossary returns original text if glossary is empty', () {
      const text = 'Hello world';
      expect(TextProcessor.applyGlossary(text, {}), equals(text));
    });
  });
}
