import 'dart:ui';

/// Represents a detected text block with its bounding box and translation
class TranslationItem {
  final String id;
  final String originalText;
  final String translatedText;
  final Rect boundingBox;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime timestamp;

  const TranslationItem({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.boundingBox,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.timestamp,
  });

  TranslationItem copyWith({
    String? id,
    String? originalText,
    String? translatedText,
    Rect? boundingBox,
    String? sourceLanguage,
    String? targetLanguage,
    DateTime? timestamp,
  }) {
    return TranslationItem(
      id: id ?? this.id,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      boundingBox: boundingBox ?? this.boundingBox,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
