abstract class TranslationRepository {
  Future<String> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  });
}
