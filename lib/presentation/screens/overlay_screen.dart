import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/overlay_provider.dart';
import '../../core/services/native_overlay_service.dart';
import '../widgets/region_selector.dart';
import '../widgets/dictionary_popup.dart';

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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Floating Top Bar with Status and Quick Controls
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: overlay.isScanning ? Colors.greenAccent : Colors.amberAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      overlay.isScanning ? 'LIVE SCAN' : 'IDLE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        final next = !settings.isClickThrough;
                        ref.read(settingsProvider.notifier).setClickThrough(next);
                        NativeOverlayService.setClickThrough(next);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: settings.isClickThrough
                              ? Colors.blueAccent.withValues(alpha: 0.3)
                              : Colors.orangeAccent.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: settings.isClickThrough ? Colors.cyanAccent : Colors.orangeAccent,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          settings.isClickThrough ? 'Xuyên thấu ON (Alt+X)' : 'Tương tác ON (Alt+X)',
                          style: TextStyle(
                            color: settings.isClickThrough ? Colors.cyanAccent : Colors.orangeAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(
                        _isSelectingRegion ? Icons.check : Icons.crop_free,
                        color: Colors.cyanAccent,
                        size: 18,
                      ),
                      tooltip: _isSelectingRegion ? 'Xong chọn vùng' : 'Chọn vùng quét',
                      onPressed: () {
                        setState(() {
                          _isSelectingRegion = !_isSelectingRegion;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                      tooltip: 'Đóng Overlay',
                      onPressed: () {
                        ref.read(overlayProvider.notifier).stopScanning();
                        NativeOverlayService.setClickThrough(false);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Draggable Region Selector if active
          if (_isSelectingRegion)
            RegionSelector(
              initialRect: overlay.selectedRegion ?? const Rect.fromLTWH(100, 100, 400, 200),
              onRegionChanged: (rect) {
                ref.read(overlayProvider.notifier).setRegion(rect);
              },
            ),

          // Render Live Translation Items over the screen
          if (overlay.items.isNotEmpty)
            ...overlay.items.map((item) {
              return Positioned(
                left: item.boundingBox.left,
                top: item.boundingBox.top,
                width: item.boundingBox.width.clamp(120.0, 600.0),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: settings.overlayOpacity),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: settings.isClickThrough
                            ? Colors.cyanAccent.withValues(alpha: 0.5)
                            : Colors.orangeAccent.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 8,
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
                            color: Colors.white,
                            fontSize: settings.fontSize,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        if (!settings.isClickThrough) ...[
                          const SizedBox(height: 4),
                          const Text(
                            '💡 Chạm để tra từ điển',
                            style: TextStyle(color: Colors.orangeAccent, fontSize: 9),
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
