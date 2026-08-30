import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/native_overlay_service.dart';
import '../../domain/entities/subtitle_style.dart';
import '../providers/settings_provider.dart';
import '../providers/overlay_provider.dart';
import '../widgets/hyper_float_bar.dart';
import '../widgets/floating_subtitle_bubble.dart';
import '../widgets/floating_lens.dart';
import '../widgets/region_selector.dart';
import '../widgets/dictionary_popup.dart';

class OverlayScreen extends ConsumerStatefulWidget {
  const OverlayScreen({super.key});

  @override
  ConsumerState<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends ConsumerState<OverlayScreen> {
  bool _isSelectingRegion = false;
  bool _isLensActive = false;
  bool _isSubtitleBubbleVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      NativeOverlayService.setClickThrough(settings.isClickThrough);
      NativeOverlayService.setAlwaysOnTop(true);
      NativeOverlayService.setWindowOpacity(settings.overlayOpacity);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final overlay = ref.watch(overlayProvider);
    final theme = settings.subtitleTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Draggable Floating Lens Reticle if active
          if (_isLensActive)
            FloatingLens(
              onClose: () {
                setState(() {
                  _isLensActive = false;
                });
              },
            ),

          // 2. Draggable Region Selector if active
          if (_isSelectingRegion)
            RegionSelector(
              initialRect: overlay.selectedRegion ?? const Rect.fromLTWH(100, 100, 400, 200),
              onRegionChanged: (rect) {
                ref.read(overlayProvider.notifier).setRegion(rect);
              },
            ),

          // 3. Floating Subtitle Stream Bubble (Draggable Xiaomi-style Bubble)
          if (_isSubtitleBubbleVisible && !_isLensActive)
            FloatingSubtitleBubble(
              onClose: () {
                setState(() {
                  _isSubtitleBubbleVisible = false;
                });
              },
            ),

          // 4. In-Place Subtitles (Directly over words on screen)
          if (settings.subtitlePlacement == SubtitlePlacement.inPlace && overlay.items.isNotEmpty && !_isLensActive)
            ...overlay.items.map((item) {
              return Positioned(
                left: item.boundingBox.left,
                top: item.boundingBox.top,
                width: item.boundingBox.width.clamp(140.0, 650.0),
                child: GestureDetector(
                  onTap: () {
                    if (!settings.isClickThrough) {
                      DictionaryPopup.show(
                        context,
                        word: item.originalText,
                        sourceLang: item.sourceLanguage,
                        targetLang: item.targetLanguage,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.backgroundColor.withValues(alpha: settings.overlayOpacity),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: settings.isClickThrough
                            ? theme.borderColor.withValues(alpha: 0.6)
                            : Colors.orangeAccent.withValues(alpha: 0.9),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.translatedText,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: settings.fontSize,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

          // 5. Xiaomi-Style HyperFloat Bar (The Master Floating Controller)
          HyperFloatBar(
            isLensActive: _isLensActive,
            isSelectingRegion: _isSelectingRegion,
            isSubtitleBubbleVisible: _isSubtitleBubbleVisible,
            onToggleLens: () {
              setState(() {
                _isLensActive = !_isLensActive;
              });
            },
            onToggleRegionSelect: () {
              setState(() {
                _isSelectingRegion = !_isSelectingRegion;
              });
            },
            onToggleSubtitleBubble: () {
              setState(() {
                _isSubtitleBubbleVisible = !_isSubtitleBubbleVisible;
              });
            },
            onClose: () {
              ref.read(overlayProvider.notifier).stopScanning();
              NativeOverlayService.setClickThrough(false);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
