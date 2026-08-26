import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/translation_item.dart';
import '../../domain/repositories/translation_repository.dart';
import '../../data/repositories/translation_repository_impl.dart';
import 'settings_provider.dart';

final translationRepositoryProvider = Provider<TranslationRepository>((ref) {
  return TranslationRepositoryImpl();
});

class OverlayState {
  final bool isScanning;
  final Rect? selectedRegion;
  final List<TranslationItem> items;
  final String? lastError;

  const OverlayState({
    this.isScanning = false,
    this.selectedRegion,
    this.items = const [],
    this.lastError,
  });

  OverlayState copyWith({
    bool? isScanning,
    Rect? selectedRegion,
    List<TranslationItem>? items,
    String? lastError,
  }) {
    return OverlayState(
      isScanning: isScanning ?? this.isScanning,
      selectedRegion: selectedRegion ?? this.selectedRegion,
      items: items ?? this.items,
      lastError: lastError ?? this.lastError,
    );
  }
}

class OverlayNotifier extends Notifier<OverlayState> {
  Timer? _scanTimer;

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
      _performScanCycle();
    });
  }

  void stopScanning() {
    _scanTimer?.cancel();
    _scanTimer = null;
    state = state.copyWith(isScanning: false);
  }

  Future<void> _performScanCycle() async {
    // In Sprint 1, we provide the pipeline structure.
    // Screen capture & native OCR hook into this method.
  }

  void addTranslationItem(TranslationItem item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void clearItems() {
    state = state.copyWith(items: []);
  }
}

final overlayProvider = NotifierProvider<OverlayNotifier, OverlayState>(() {
  return OverlayNotifier();
});
