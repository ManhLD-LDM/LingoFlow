import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/subtitle_style.dart';
import '../providers/settings_provider.dart';
import '../providers/overlay_provider.dart';
import '../../core/services/native_overlay_service.dart';
import '../widgets/region_selector.dart';
import '../widgets/dictionary_popup.dart';
import '../widgets/mini_control_bar.dart';

class OverlayScreen extends ConsumerStatefulWidget {
  const OverlayScreen({super.key});

  @override
  ConsumerState<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends ConsumerState<OverlayScreen> {
  bool _isSelectingRegion = false;

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
          // Floating, Draggable & Collapsible Mini Control Bar
          MiniControlBar(
            isSelectingRegion: _isSelectingRegion,
            onToggleRegionSelect: () {
              setState(() {
                _isSelectingRegion = !_isSelectingRegion;
              });
            },
            onClose: () {
              ref.read(overlayProvider.notifier).stopScanning();
              NativeOverlayService.setClickThrough(false);
              Navigator.pop(context);
            },
          ),

          // Draggable Region Selector if active
          if (_isSelectingRegion)
            RegionSelector(
              initialRect: overlay.selectedRegion ?? const Rect.fromLTWH(100, 100, 400, 200),
              onRegionChanged: (rect) {
                ref.read(overlayProvider.notifier).setRegion(rect);
              },
            ),

          // Render Subtitles in Bottom Center Cinema Mode
          if (settings.subtitlePlacement == SubtitlePlacement.bottomCenter && overlay.items.isNotEmpty)
            Positioned(
              bottom: 40,
              left: 40,
              right: 40,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.backgroundColor.withValues(alpha: settings.overlayOpacity),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: overlay.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          item.translatedText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: settings.fontSize + 2,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

          // Render Subtitles in In-Place Mode
          if (settings.subtitlePlacement == SubtitlePlacement.inPlace && overlay.items.isNotEmpty)
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
                        if (!settings.isClickThrough) ...[
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.touch_app, color: Colors.orangeAccent, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Chạm để tra từ điển & Romaji',
                                style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
