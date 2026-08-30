import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';
import '../providers/overlay_provider.dart';
import 'dictionary_popup.dart';

class FloatingSubtitleBubble extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const FloatingSubtitleBubble({super.key, this.onClose});

  @override
  ConsumerState<FloatingSubtitleBubble> createState() => _FloatingSubtitleBubbleState();
}

class _FloatingSubtitleBubbleState extends ConsumerState<FloatingSubtitleBubble> {
  Offset _position = const Offset(20, 480);
  final double _width = 360.0;
  bool _isPinned = false;

  void _speakText(String text, String lang) {
    HapticFeedback.lightImpact();
    TtsService.speak(text, language: lang);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final overlay = ref.watch(overlayProvider);
    final theme = settings.subtitleTheme;

    if (overlay.items.isEmpty && !overlay.isScanning) {
      return const SizedBox.shrink();
    }

    final latestItem = overlay.items.isNotEmpty ? overlay.items.last : null;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: _isPinned
            ? null
            : (details) {
                setState(() {
                  _position += details.delta;
                });
              },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: _width.clamp(280.0, 600.0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.backgroundColor.withValues(
                  alpha: (settings.overlayOpacity * 0.95).clamp(0.2, 1.0),
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: overlay.isScanning
                      ? AppColors.emeraldLive.withValues(alpha: 0.6)
                      : theme.borderColor.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bubble Header Bar (Drag / Actions / Speak / Pin)
                  Row(
                    children: [
                      // Drag indicator / Subtitle badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.cyanPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              overlay.isScanning ? Icons.graphic_eq : Icons.subtitles,
                              color: overlay.isScanning
                                  ? AppColors.emeraldLive
                                  : AppColors.cyanPrimary,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              overlay.isScanning ? 'LIVE PHỤ ĐỀ' : 'BẢN DỊCH',
                              style: TextStyle(
                                color: overlay.isScanning
                                    ? AppColors.emeraldLive
                                    : AppColors.cyanPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // TTS Speak Audio Button
                      if (latestItem != null)
                        IconButton(
                          icon: const Icon(Icons.volume_up_outlined, color: AppColors.cyanPrimary, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Nghe phát âm',
                          onPressed: () => _speakText(
                            latestItem.originalText,
                            latestItem.sourceLanguage,
                          ),
                        ),
                      const SizedBox(width: 10),

                      // Pin / Unpin Position
                      IconButton(
                        icon: Icon(
                          _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          color: _isPinned ? AppColors.amberStar : AppColors.textMuted,
                          size: 16,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: _isPinned ? 'Bỏ ghim vị trí' : 'Ghim vị trí cố định',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _isPinned = !_isPinned;
                          });
                        },
                      ),
                      const SizedBox(width: 10),

                      // Close Bubble
                      if (widget.onClose != null)
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 15),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Ẩn khung phụ đề',
                          onPressed: widget.onClose,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Subtitle Content Stream
                  if (overlay.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Đang chờ nhận diện chữ trên màn hình...',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ...overlay.items.take(3).map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Translated Text (High contrast, custom font size)
                            SelectableText(
                              item.translatedText,
                              style: TextStyle(
                                color: theme.textColor,
                                fontSize: settings.fontSize + 1,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Original text with tap-to-lookup dictionary hint
                            GestureDetector(
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
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.originalText,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: theme.textColor.withValues(alpha: 0.65),
                                        fontSize: (settings.fontSize - 2).clamp(10.0, 24.0),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.menu_book_outlined,
                                    color: AppColors.cyanPrimary,
                                    size: 13,
                                  ),
                                ],
                              ),
                            ),
                            if (overlay.items.indexOf(item) != overlay.items.length - 1)
                              const Divider(color: AppColors.borderSubtle, height: 10),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
