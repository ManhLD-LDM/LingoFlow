class TtsService {
  /// Returns a valid URL to stream TTS audio for the given text and language
  static String getAudioStreamUrl(String text, {String language = 'ja'}) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return '';

    final encoded = Uri.encodeComponent(cleanText);
    var langCode = language.toLowerCase();
    if (langCode == 'auto') langCode = 'ja';

    return 'https://translate.google.com/translate_tts?ie=UTF-8&tl=$langCode&client=tw-ob&q=$encoded';
  }
}
