enum TranslationEngine {
  google(
    id: 'google',
    displayName: 'Google Translate (Miễn phí / Tốc độ cao)',
    requiresApiKey: false,
  ),
  deepl(
    id: 'deepl',
    displayName: 'DeepL API (Chất lượng cao - Chuyên Manga & Game)',
    requiresApiKey: true,
  );

  final String id;
  final String displayName;
  final bool requiresApiKey;

  const TranslationEngine({
    required this.id,
    required this.displayName,
    required this.requiresApiKey,
  });

  static TranslationEngine fromId(String id) {
    return TranslationEngine.values.firstWhere(
      (e) => e.id == id,
      orElse: () => TranslationEngine.google,
    );
  }
}
