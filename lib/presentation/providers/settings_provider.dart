import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/languages.dart';
import '../../domain/entities/translation_engine.dart';
import '../../domain/entities/subtitle_style.dart';
import '../../domain/entities/ocr_engine_mode.dart';

/// Keys used for SharedPreferences persistence
class _PrefKeys {
  static const sourceLanguage = 'lf_source_language';
  static const targetLanguage = 'lf_target_language';
  static const isClickThrough = 'lf_is_click_through';
  static const scanIntervalMs = 'lf_scan_interval_ms';
  static const overlayOpacity = 'lf_overlay_opacity';
  static const fontSize = 'lf_font_size';
  static const selectedEngine = 'lf_selected_engine';
  static const deepLApiKey = 'lf_deepl_api_key';
  static const ocrApiKey = 'lf_ocr_api_key';
  static const ocrEngineMode = 'lf_ocr_engine_mode';
  static const subtitleTheme = 'lf_subtitle_theme';
  static const subtitlePlacement = 'lf_subtitle_placement';
  static const lensX = 'lf_lens_x';
  static const lensY = 'lf_lens_y';
  static const lensWidth = 'lf_lens_width';
  static const lensHeight = 'lf_lens_height';
}

class SettingsState {
  final String sourceLanguage;
  final String targetLanguage;
  final bool isClickThrough;
  final int scanIntervalMs;
  final double overlayOpacity;
  final double fontSize;
  final TranslationEngine selectedEngine;
  final String deepLApiKey;
  final String ocrApiKey;
  final OcrEngineMode ocrEngineMode;
  final SubtitleTheme subtitleTheme;
  final SubtitlePlacement subtitlePlacement;
  // Lens position/size persistence
  final double lensX;
  final double lensY;
  final double lensWidth;
  final double lensHeight;

  const SettingsState({
    this.sourceLanguage = AppLanguages.defaultSource,
    this.targetLanguage = AppLanguages.defaultTarget,
    this.isClickThrough = true,
    this.scanIntervalMs = 1500,
    this.overlayOpacity = 0.85,
    this.fontSize = 14.0,
    this.selectedEngine = TranslationEngine.google,
    this.deepLApiKey = '',
    this.ocrApiKey = '',
    this.ocrEngineMode = OcrEngineMode.autoFallback,
    this.subtitleTheme = SubtitleTheme.cyberpunk,
    this.subtitlePlacement = SubtitlePlacement.inPlace,
    this.lensX = 200,
    this.lensY = 150,
    this.lensWidth = 440,
    this.lensHeight = 220,
  });

  SettingsState copyWith({
    String? sourceLanguage,
    String? targetLanguage,
    bool? isClickThrough,
    int? scanIntervalMs,
    double? overlayOpacity,
    double? fontSize,
    TranslationEngine? selectedEngine,
    String? deepLApiKey,
    String? ocrApiKey,
    OcrEngineMode? ocrEngineMode,
    SubtitleTheme? subtitleTheme,
    SubtitlePlacement? subtitlePlacement,
    double? lensX,
    double? lensY,
    double? lensWidth,
    double? lensHeight,
  }) {
    return SettingsState(
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      isClickThrough: isClickThrough ?? this.isClickThrough,
      scanIntervalMs: scanIntervalMs ?? this.scanIntervalMs,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      fontSize: fontSize ?? this.fontSize,
      selectedEngine: selectedEngine ?? this.selectedEngine,
      deepLApiKey: deepLApiKey ?? this.deepLApiKey,
      ocrApiKey: ocrApiKey ?? this.ocrApiKey,
      ocrEngineMode: ocrEngineMode ?? this.ocrEngineMode,
      subtitleTheme: subtitleTheme ?? this.subtitleTheme,
      subtitlePlacement: subtitlePlacement ?? this.subtitlePlacement,
      lensX: lensX ?? this.lensX,
      lensY: lensY ?? this.lensY,
      lensWidth: lensWidth ?? this.lensWidth,
      lensHeight: lensHeight ?? this.lensHeight,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    // Load persisted settings asynchronously on first build
    _loadPersistedSettings();
    String defaultOcrKey = '';
    String defaultDeepLKey = '';
    try {
      if (dotenv.isInitialized) {
        defaultOcrKey = dotenv.env['OCR_API_KEY'] ?? '';
        defaultDeepLKey = dotenv.env['DEEPL_API_KEY'] ?? '';
      }
    } catch (_) {}

    return SettingsState(
      ocrApiKey: defaultOcrKey,
      deepLApiKey: defaultDeepLKey,
    );
  }

  /// Load all persisted settings from SharedPreferences
  Future<void> _loadPersistedSettings() async {
    final prefs = await SharedPreferences.getInstance();

    state = state.copyWith(
      sourceLanguage: prefs.getString(_PrefKeys.sourceLanguage) ?? state.sourceLanguage,
      targetLanguage: prefs.getString(_PrefKeys.targetLanguage) ?? state.targetLanguage,
      isClickThrough: prefs.getBool(_PrefKeys.isClickThrough) ?? state.isClickThrough,
      scanIntervalMs: prefs.getInt(_PrefKeys.scanIntervalMs) ?? state.scanIntervalMs,
      overlayOpacity: prefs.getDouble(_PrefKeys.overlayOpacity) ?? state.overlayOpacity,
      fontSize: prefs.getDouble(_PrefKeys.fontSize) ?? state.fontSize,
      selectedEngine: TranslationEngine.fromId(
        prefs.getString(_PrefKeys.selectedEngine) ?? state.selectedEngine.id,
      ),
      deepLApiKey: prefs.getString(_PrefKeys.deepLApiKey) ?? state.deepLApiKey,
      ocrApiKey: prefs.getString(_PrefKeys.ocrApiKey) ?? state.ocrApiKey,
      ocrEngineMode: OcrEngineMode.fromId(
        prefs.getString(_PrefKeys.ocrEngineMode) ?? state.ocrEngineMode.id,
      ),
      subtitleTheme: SubtitleTheme.fromId(
        prefs.getString(_PrefKeys.subtitleTheme) ?? state.subtitleTheme.id,
      ),
      subtitlePlacement: prefs.getString(_PrefKeys.subtitlePlacement) == 'bottomCenter'
          ? SubtitlePlacement.bottomCenter
          : state.subtitlePlacement,
      lensX: prefs.getDouble(_PrefKeys.lensX) ?? state.lensX,
      lensY: prefs.getDouble(_PrefKeys.lensY) ?? state.lensY,
      lensWidth: prefs.getDouble(_PrefKeys.lensWidth) ?? state.lensWidth,
      lensHeight: prefs.getDouble(_PrefKeys.lensHeight) ?? state.lensHeight,
    );
  }

  /// Persist a single key-value pair to SharedPreferences
  Future<void> _persist(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  void setSourceLanguage(String lang) {
    state = state.copyWith(sourceLanguage: lang);
    _persist(_PrefKeys.sourceLanguage, lang);
  }

  void setTargetLanguage(String lang) {
    state = state.copyWith(targetLanguage: lang);
    _persist(_PrefKeys.targetLanguage, lang);
  }

  void toggleClickThrough() {
    final next = !state.isClickThrough;
    state = state.copyWith(isClickThrough: next);
    _persist(_PrefKeys.isClickThrough, next);
  }

  void setClickThrough(bool value) {
    state = state.copyWith(isClickThrough: value);
    _persist(_PrefKeys.isClickThrough, value);
  }

  void setScanInterval(int intervalMs) {
    state = state.copyWith(scanIntervalMs: intervalMs);
    _persist(_PrefKeys.scanIntervalMs, intervalMs);
  }

  void setOverlayOpacity(double opacity) {
    state = state.copyWith(overlayOpacity: opacity);
    _persist(_PrefKeys.overlayOpacity, opacity);
  }

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size);
    _persist(_PrefKeys.fontSize, size);
  }

  void setSelectedEngine(TranslationEngine engine) {
    state = state.copyWith(selectedEngine: engine);
    _persist(_PrefKeys.selectedEngine, engine.id);
  }

  void setDeepLApiKey(String key) {
    final trimmed = key.trim();
    state = state.copyWith(deepLApiKey: trimmed);
    _persist(_PrefKeys.deepLApiKey, trimmed);
  }

  void setOcrApiKey(String key) {
    final trimmed = key.trim();
    state = state.copyWith(ocrApiKey: trimmed);
    _persist(_PrefKeys.ocrApiKey, trimmed);
  }

  void setOcrEngineMode(OcrEngineMode mode) {
    state = state.copyWith(ocrEngineMode: mode);
    _persist(_PrefKeys.ocrEngineMode, mode.id);
  }

  void setSubtitleTheme(SubtitleTheme theme) {
    state = state.copyWith(subtitleTheme: theme);
    _persist(_PrefKeys.subtitleTheme, theme.id);
  }

  void setSubtitlePlacement(SubtitlePlacement placement) {
    state = state.copyWith(subtitlePlacement: placement);
    _persist(_PrefKeys.subtitlePlacement, placement == SubtitlePlacement.bottomCenter ? 'bottomCenter' : 'inPlace');
  }

  void setLensPosition(double x, double y) {
    state = state.copyWith(lensX: x, lensY: y);
    _persist(_PrefKeys.lensX, x);
    _persist(_PrefKeys.lensY, y);
  }

  void setLensSize(double width, double height) {
    state = state.copyWith(lensWidth: width, lensHeight: height);
    _persist(_PrefKeys.lensWidth, width);
    _persist(_PrefKeys.lensHeight, height);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
