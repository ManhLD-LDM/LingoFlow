/// Supported language codes and names for LingoFlow
class AppLanguages {
  static const Map<String, String> supportedSources = {
    'auto': 'Tự động phát hiện (Auto)',
    'ja': 'Tiếng Nhật (Japanese)',
    'zh': 'Tiếng Trung (Chinese)',
    'en': 'Tiếng Anh (English)',
  };

  static const Map<String, String> supportedTargets = {
    'vi': 'Tiếng Việt (Vietnamese)',
    'en': 'Tiếng Anh (English)',
  };

  static const String defaultSource = 'ja';
  static const String defaultTarget = 'vi';
}
