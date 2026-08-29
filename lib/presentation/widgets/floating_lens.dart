import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/text_processor.dart';
import '../../core/services/native_overlay_service.dart';
import '../providers/settings_provider.dart';
import '../providers/overlay_provider.dart';
import '../providers/history_provider.dart';
import '../providers/profile_provider.dart';
import 'dictionary_popup.dart';

class FloatingLens extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const FloatingLens({super.key, required this.onClose});

  @override
  ConsumerState<FloatingLens> createState() => _FloatingLensState();
}

class _FloatingLensState extends ConsumerState<FloatingLens> {
  // Lens position and dimensions (loaded from persisted settings)
  late Offset _position;
  late Size _size;

  bool _isLiveScanning = false;
  bool _isProcessing = false;
  Timer? _liveTimer;

  String _detectedOriginal = '';
  String _translatedResult = '';
  String? _statusInfo;

  @override
  void initState() {
    super.initState();
    // Load persisted lens position/size from settings
    final settings = ref.read(settingsProvider);
    _position = Offset(settings.lensX, settings.lensY);
    _size = Size(settings.lensWidth, settings.lensHeight);
    // Enable full-screen borderless transparent overlay
    NativeOverlayService.enterOverlayMode();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  void _closeLens() {
    _liveTimer?.cancel();
    // Persist lens position/size before closing
    ref.read(settingsProvider.notifier).setLensPosition(_position.dx, _position.dy);
    ref.read(settingsProvider.notifier).setLensSize(_size.width, _size.height);
    NativeOverlayService.exitOverlayMode();
    widget.onClose();
  }

  void _toggleLiveScanning() {
    setState(() {
      _isLiveScanning = !_isLiveScanning;
    });

    if (_isLiveScanning) {
      final interval = ref.read(settingsProvider).scanIntervalMs;
      _liveTimer?.cancel();
      _liveTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
        _captureAndTranslate(isFromLive: true);
      });
      _captureAndTranslate(isFromLive: true);
    } else {
      _liveTimer?.cancel();
      _liveTimer = null;
    }
  }

  Future<void> _captureAndTranslate({bool isFromLive = false}) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      if (!isFromLive) _statusInfo = 'Đang nhận diện & dịch...';
    });

    try {
      final region = Rect.fromLTWH(_position.dx, _position.dy + 34, _size.width, _size.height - 34);
      final settings = ref.read(settingsProvider);
      final ocrRepo = ref.read(ocrRepositoryProvider);
      final translateRepo = ref.read(translationRepositoryProvider);

      final ocrResult = await ocrRepo.recognizeFromRegion(
        region,
        languageHint: settings.sourceLanguage,
        apiKey: settings.ocrApiKey,
        mode: settings.ocrEngineMode,
      );

      final rawText = ocrResult.fullText.trim();
      if (rawText.isEmpty) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            if (!isFromLive && _translatedResult.isEmpty) {
              _statusInfo = 'Không tìm thấy chữ trong khung.';
            }
          });
        }
        return;
      }

      final cleanedText = TextProcessor.cleanOcrText(rawText, language: settings.sourceLanguage);
      if (cleanedText.isEmpty) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
        return;
      }

      final activeProfile = ref.read(profileProvider).activeProfile;
      final translated = await translateRepo.translate(
        text: cleanedText,
        sourceLanguage: settings.sourceLanguage,
        targetLanguage: settings.targetLanguage,
        engine: settings.selectedEngine,
        apiKey: settings.deepLApiKey,
        glossary: activeProfile.glossary,
      );

      // Save to History
      ref.read(historyProvider.notifier).addRecord(
        originalText: cleanedText,
        translatedText: translated,
        sourceLanguage: settings.sourceLanguage,
        targetLanguage: settings.targetLanguage,
      );

      if (mounted) {
        setState(() {
          _detectedOriginal = cleanedText;
          _translatedResult = translated;
          _statusInfo = null;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusInfo = 'Lỗi: $e';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = settings.subtitleTheme;

    return Stack(
      children: [
        // 1. Resizable & Draggable Floating Frame (100% Crystal Clear Hollow Viewport)
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: SizedBox(
            width: _size.width,
            height: _size.height,
            child: Stack(
              children: [
                // Clean border with NO shadow, NO tint, NO blur
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _isLiveScanning ? Colors.greenAccent : Colors.cyanAccent,
                        width: 1.8,
                      ),
                    ),
                  ),
                ),

                // Corner crosshairs to indicate active capture zone
                Positioned(
                  top: 38,
                  left: 4,
                  child: Icon(Icons.crop_free, size: 14, color: Colors.cyanAccent.withValues(alpha: 0.8)),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Icon(Icons.crop_free, size: 14, color: Colors.cyanAccent.withValues(alpha: 0.8)),
                ),

                // 2. Attached Floating Header Bar (Di chuyển khung trên toàn màn hình)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _position += details.delta;
                      });
                    },
                    onPanEnd: (_) {
                      ref.read(settingsProvider.notifier).setLensPosition(_position.dx, _position.dy);
                    },
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        border: Border(
                          bottom: BorderSide(
                            color: _isLiveScanning ? Colors.greenAccent : Colors.cyanAccent,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.drag_indicator, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _isLiveScanning ? '🔴 LIVE' : '🔍 KHUNG DỊCH',
                            style: TextStyle(
                              color: _isLiveScanning ? Colors.greenAccent : Colors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${settings.sourceLanguage.toUpperCase()} → ${settings.targetLanguage.toUpperCase()}',
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                          const Spacer(),

                          // Single Translate Button
                          IconButton(
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                                  )
                                : const Icon(Icons.translate, color: Colors.cyanAccent, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Dịch vùng này ngay (Alt+S)',
                            onPressed: _isProcessing ? null : () => _captureAndTranslate(isFromLive: false),
                          ),
                          const SizedBox(width: 8),

                          // Live Scanning Toggle
                          IconButton(
                            icon: Icon(
                              _isLiveScanning ? Icons.pause_circle_filled : Icons.play_circle_fill,
                              color: _isLiveScanning ? Colors.greenAccent : Colors.white70,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: _isLiveScanning ? 'Tạm dừng quét' : 'Bật quét tự động',
                            onPressed: _toggleLiveScanning,
                          ),
                          const SizedBox(width: 8),

                          // Close Lens Button
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Đóng khung dịch',
                            onPressed: _closeLens,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Resize Handle in bottom-right corner
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        final newW = (_size.width + details.delta.dx).clamp(160.0, 1600.0);
                        final newH = (_size.height + details.delta.dy).clamp(100.0, 1000.0);
                        _size = Size(newW, newH);
                      });
                    },
                    onPanEnd: (_) {
                      ref.read(settingsProvider.notifier).setLensSize(_size.width, _size.height);
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomRight: Radius.circular(5),
                        ),
                      ),
                      child: const Icon(Icons.south_east, color: Colors.cyanAccent, size: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. Live Floating Result Card (Hiển thị bản dịch đè lên ngay cạnh khung)
        if (_translatedResult.isNotEmpty)
          Positioned(
            left: _position.dx,
            top: (_position.dy + _size.height + 6).clamp(10.0, MediaQuery.of(context).size.height - 180),
            width: _size.width.clamp(280.0, 800.0),
            child: GestureDetector(
              onTap: () {
                DictionaryPopup.show(
                  context,
                  word: _detectedOriginal,
                  sourceLang: settings.sourceLanguage,
                  targetLang: settings.targetLanguage,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${settings.sourceLanguage.toUpperCase()} → ${settings.targetLanguage.toUpperCase()}',
                          style: TextStyle(
                            color: theme.borderColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.white70, size: 14),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Sao chép',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _translatedResult));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã sao chép bản dịch!'),
                                    duration: Duration(seconds: 1),
                                    backgroundColor: Color(0xFF0F172A),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '💡 Chạm để tra từ điển',
                              style: TextStyle(color: Colors.orangeAccent, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _translatedResult,
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: settings.fontSize + 1,
                        fontWeight: FontWeight.bold,
                        height: 1.35,
                      ),
                    ),
                    if (_detectedOriginal.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _detectedOriginal,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

        if (_statusInfo != null && _translatedResult.isEmpty)
          Positioned(
            left: _position.dx,
            top: _position.dy + _size.height + 6,
            width: _size.width,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
              ),
              child: Text(
                _statusInfo!,
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
