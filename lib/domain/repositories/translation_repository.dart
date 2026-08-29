import '../entities/translation_engine.dart';

abstract class TranslationRepository {
  Future<String> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
    TranslationEngine engine = TranslationEngine.google,
    String? apiKey,
    Map<String, String>? glossary,
  });
}
