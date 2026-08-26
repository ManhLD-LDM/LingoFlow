import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/languages.dart';
import '../../domain/entities/translation_engine.dart';

class SettingsState {
  final String sourceLanguage;
  final String targetLanguage;
  final bool isClickThrough;
  final int scanIntervalMs;
  final double overlayOpacity;
  final double fontSize;
  final TranslationEngine selectedEngine;
  final String deepLApiKey;

  const SettingsState({
    this.sourceLanguage = AppLanguages.defaultSource,
    this.targetLanguage = AppLanguages.defaultTarget,
    this.isClickThrough = true,
    this.scanIntervalMs = 1500,
    this.overlayOpacity = 0.85,
    this.fontSize = 14.0,
    this.selectedEngine = TranslationEngine.google,
    this.deepLApiKey = '',
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
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
