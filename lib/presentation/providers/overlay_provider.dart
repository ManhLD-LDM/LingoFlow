import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/text_processor.dart';
import '../../domain/entities/translation_item.dart';
import '../../domain/repositories/translation_repository.dart';
import '../../domain/repositories/ocr_repository.dart';
import '../../data/repositories/translation_repository_impl.dart';
import '../../data/repositories/ocr_repository_impl.dart';
import 'settings_provider.dart';
import 'history_provider.dart';
import 'profile_provider.dart';

final translationRepositoryProvider = Provider<TranslationRepository>((ref) {
  return TranslationRepositoryImpl();
});

final ocrRepositoryProvider = Provider<OcrRepository>((ref) {
  return OcrRepositoryImpl();
});

class OverlayState {
  final bool isScanning;
  final Rect? selectedRegion;
  final List<TranslationItem> items;
  final String? lastError;
  final String lastRawText;

  const OverlayState({
    this.isScanning = false,
    this.selectedRegion,
    this.items = const [],
    this.lastError,
    this.lastRawText = '',
  });

  OverlayState copyWith({
    bool? isScanning,
    Rect? selectedRegion,
    List<TranslationItem>? items,
    String? lastError,
    String? lastRawText,
  }) {
    return OverlayState(
      isScanning: isScanning ?? this.isScanning,
      selectedRegion: selectedRegion ?? this.selectedRegion,
      items: items ?? this.items,
      lastError: lastError ?? this.lastError,
      lastRawText: lastRawText ?? this.lastRawText,
    );
  }
}

class OverlayNotifier extends Notifier<OverlayState> {
  Timer? _scanTimer;
  String _previousTextHash = '';
  bool _isProcessingCycle = false;

  @override
  OverlayState build() {
    ref.onDispose(() {
      _scanTimer?.cancel();
    });
    return const OverlayState();
  }

  void setRegion(Rect region) {
    state = state.copyWith(selectedRegion: region);
  }

  void startScanning() {
    state = state.copyWith(isScanning: true);
    final interval = ref.read(settingsProvider).scanIntervalMs;
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      performScanCycle();
    });
  }

  void stopScanning() {
    _scanTimer?.cancel();
    _scanTimer = null;
    state = state.copyWith(isScanning: false);
  }

  /// Executes one full screen capture -> OCR -> translate -> overlay render cycle
  Future<void> performScanCycle() async {
    if (_isProcessingCycle) return;
    _isProcessingCycle = true;

    try {
      final region = state.selectedRegion ?? const Rect.fromLTWH(100, 100, 500, 300);
      final settings = ref.read(settingsProvider);
      final ocrRepo = ref.read(ocrRepositoryProvider);
      final translateRepo = ref.read(translationRepositoryProvider);

      // 1. Run OCR on selected screen region
      final ocrResult = await ocrRepo.recognizeFromRegion(
        region,
        languageHint: settings.sourceLanguage,
        apiKey: settings.ocrApiKey,
        mode: settings.ocrEngineMode,
      );

      final rawText = ocrResult.fullText.trim();
      if (rawText.isEmpty) {
        _isProcessingCycle = false;
        return;
      }

      // 2. Debounce optimization: skip translation if raw text is unchanged
      if (rawText == _previousTextHash) {
        _isProcessingCycle = false;
        return;
      }
      _previousTextHash = rawText;

      // 3. Process & Translate recognized blocks
      final newItems = <TranslationItem>[];
      if (ocrResult.blocks.isNotEmpty) {
        for (var i = 0; i < ocrResult.blocks.length; i++) {
          final block = ocrResult.blocks[i];
          final cleanedText = TextProcessor.cleanOcrText(
            block.text,
            language: settings.sourceLanguage,
          );
          if (cleanedText.isEmpty) continue;

          final activeProfile = ref.read(profileProvider).activeProfile;
          final translated = await translateRepo.translate(
            text: cleanedText,
            sourceLanguage: settings.sourceLanguage,
            targetLanguage: settings.targetLanguage,
            engine: settings.selectedEngine,
            apiKey: settings.deepLApiKey,
            glossary: activeProfile.glossary,
          );

          newItems.add(
            TranslationItem(
              id: 'trans_${DateTime.now().millisecondsSinceEpoch}_$i',
              originalText: cleanedText,
              translatedText: translated,
              boundingBox: block.boundingBox,
              sourceLanguage: settings.sourceLanguage,
              targetLanguage: settings.targetLanguage,
              timestamp: DateTime.now(),
            ),
          );

          // Save to History
          ref.read(historyProvider.notifier).addRecord(
            originalText: cleanedText,
            translatedText: translated,
            sourceLanguage: settings.sourceLanguage,
            targetLanguage: settings.targetLanguage,
          );
        }
      } else {
        // Fallback for single full text
        final cleanedFullText = TextProcessor.cleanOcrText(
          rawText,
          language: settings.sourceLanguage,
        );

        final activeProfile = ref.read(profileProvider).activeProfile;
        final translated = await translateRepo.translate(
          text: cleanedFullText,
          sourceLanguage: settings.sourceLanguage,
          targetLanguage: settings.targetLanguage,
          engine: settings.selectedEngine,
          apiKey: settings.deepLApiKey,
          glossary: activeProfile.glossary,
        );

        newItems.add(
          TranslationItem(
            id: 'trans_${DateTime.now().millisecondsSinceEpoch}',
            originalText: cleanedFullText,
            translatedText: translated,
            boundingBox: region,
            sourceLanguage: settings.sourceLanguage,
            targetLanguage: settings.targetLanguage,
            timestamp: DateTime.now(),
          ),
        );

        // Save to History
        ref.read(historyProvider.notifier).addRecord(
          originalText: cleanedFullText,
          translatedText: translated,
          sourceLanguage: settings.sourceLanguage,
          targetLanguage: settings.targetLanguage,
        );
      }

      // 4. Update overlay state with new translation items
      state = state.copyWith(
        items: newItems,
        lastRawText: rawText,
        lastError: null,
      );
    } catch (e) {
      state = state.copyWith(lastError: e.toString());
    } finally {
      _isProcessingCycle = false;
    }
  }

  void addTranslationItem(TranslationItem item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void clearItems() {
    _previousTextHash = '';
    state = state.copyWith(items: [], lastRawText: '');
  }
}

final overlayProvider = NotifierProvider<OverlayNotifier, OverlayState>(() {
  return OverlayNotifier();
});
