class GameProfile {
  final String id;
  final String name;
  final String sourceLanguage;
  final String targetLanguage;
  final String translationEngineId;
  final String subtitleThemeId;
  final double lensX;
  final double lensY;
  final double lensWidth;
  final double lensHeight;
  final Map<String, String> glossary;

  const GameProfile({
    required this.id,
    required this.name,
    this.sourceLanguage = 'ja',
    this.targetLanguage = 'vi',
    this.translationEngineId = 'google',
    this.subtitleThemeId = 'cyberpunk',
    this.lensX = 100,
    this.lensY = 100,
    this.lensWidth = 500,
    this.lensHeight = 220,
    this.glossary = const {},
  });

  GameProfile copyWith({
    String? id,
    String? name,
    String? sourceLanguage,
    String? targetLanguage,
    String? translationEngineId,
    String? subtitleThemeId,
    double? lensX,
    double? lensY,
    double? lensWidth,
    double? lensHeight,
    Map<String, String>? glossary,
  }) {
    return GameProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      translationEngineId: translationEngineId ?? this.translationEngineId,
      subtitleThemeId: subtitleThemeId ?? this.subtitleThemeId,
      lensX: lensX ?? this.lensX,
      lensY: lensY ?? this.lensY,
      lensWidth: lensWidth ?? this.lensWidth,
      lensHeight: lensHeight ?? this.lensHeight,
      glossary: glossary ?? this.glossary,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sourceLanguage': sourceLanguage,
    'targetLanguage': targetLanguage,
    'translationEngineId': translationEngineId,
    'subtitleThemeId': subtitleThemeId,
    'lensX': lensX,
    'lensY': lensY,
    'lensWidth': lensWidth,
    'lensHeight': lensHeight,
    'glossary': glossary,
  };

  factory GameProfile.fromJson(Map<String, dynamic> json) => GameProfile(
    id: json['id'] as String? ?? 'default',
    name: json['name'] as String? ?? 'Mặc định',
    sourceLanguage: json['sourceLanguage'] as String? ?? 'ja',
    targetLanguage: json['targetLanguage'] as String? ?? 'vi',
    translationEngineId: json['translationEngineId'] as String? ?? 'google',
    subtitleThemeId: json['subtitleThemeId'] as String? ?? 'cyberpunk',
    lensX: (json['lensX'] as num?)?.toDouble() ?? 100,
    lensY: (json['lensY'] as num?)?.toDouble() ?? 100,
    lensWidth: (json['lensWidth'] as num?)?.toDouble() ?? 500,
    lensHeight: (json['lensHeight'] as num?)?.toDouble() ?? 220,
    glossary: (json['glossary'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, v.toString()),
    ) ?? const {},
  );

  static const defaultProfile = GameProfile(
    id: 'default',
    name: 'Game / Manga Mặc định',
    sourceLanguage: 'ja',
    targetLanguage: 'vi',
    translationEngineId: 'google',
    subtitleThemeId: 'cyberpunk',
    lensX: 100,
    lensY: 100,
    lensWidth: 500,
    lensHeight: 220,
    glossary: {},
  );
}
