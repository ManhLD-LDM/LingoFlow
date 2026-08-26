import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/languages.dart';
import '../../domain/entities/translation_engine.dart';
import '../../domain/entities/subtitle_style.dart';

class SettingsState {
  final String sourceLanguage;
  final String targetLanguage;
  final bool isClickThrough;
  final int scanIntervalMs;
  final double overlayOpacity;
  final double fontSize;
  final TranslationEngine selectedEngine;
  final String deepLApiKey;
  final SubtitleTheme subtitleTheme;
  final SubtitlePlacement subtitlePlacement;

  const SettingsState({
    this.sourceLanguage = AppLanguages.defaultSource,
    this.targetLanguage = AppLanguages.defaultTarget,
    this.isClickThrough = true,
    this.scanIntervalMs = 1500,
    this.overlayOpacity = 0.85,
    this.fontSize = 14.0,
    this.selectedEngine = TranslationEngine.google,
    this.deepLApiKey = '',
    this.subtitleTheme = SubtitleTheme.cyberpunk,
    this.subtitlePlacement = SubtitlePlacement.inPlace,
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
    SubtitleTheme? subtitleTheme,
    SubtitlePlacement? subtitlePlacement,
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
      subtitleTheme: subtitleTheme ?? this.subtitleTheme,
      subtitlePlacement: subtitlePlacement ?? this.subtitlePlacement,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    return const SettingsState();
  }

  void setSourceLanguage(String lang) {
    state = state.copyWith(sourceLanguage: lang);
  }

  void setTargetLanguage(String lang) {
    state = state.copyWith(targetLanguage: lang);
  }

  void toggleClickThrough() {
    state = state.copyWith(isClickThrough: !state.isClickThrough);
  }

  void setClickThrough(bool value) {
    state = state.copyWith(isClickThrough: value);
  }

  void setScanInterval(int intervalMs) {
    state = state.copyWith(scanIntervalMs: intervalMs);
  }

  void setOverlayOpacity(double opacity) {
    state = state.copyWith(overlayOpacity: opacity);
  }

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size);
  }

  void setSelectedEngine(TranslationEngine engine) {
    state = state.copyWith(selectedEngine: engine);
  }

  void setDeepLApiKey(String key) {
    state = state.copyWith(deepLApiKey: key.trim());
  }

  void setSubtitleTheme(SubtitleTheme theme) {
    state = state.copyWith(subtitleTheme: theme);
  }

  void setSubtitlePlacement(SubtitlePlacement placement) {
    state = state.copyWith(subtitlePlacement: placement);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
