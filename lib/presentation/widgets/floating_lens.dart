import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/text_processor.dart';
import '../../core/services/native_overlay_service.dart';
import '../providers/settings_provider.dart';
import '../providers/overlay_provider.dart';
import '../providers/history_provider.dart';
import 'dictionary_popup.dart';

class FloatingLens extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const FloatingLens({super.key, required this.onClose});

  @override
  ConsumerState<FloatingLens> createState() => _FloatingLensState();
}

class _FloatingLensState extends ConsumerState<FloatingLens> {
  // Lens position and dimensions on the global desktop screen
  Offset _position = const Offset(200, 200);
  Size _size = const Size(500, 280);

  bool _isLiveScanning = false;
  bool _isProcessing = false;
  Timer? _liveTimer;

  String _detectedOriginal = '';
  String _translatedResult = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Ensure native overlay mode is active
    NativeOverlayService.enterOverlayMode();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  void _closeLens() {
    _liveTimer?.cancel();
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
        _captureAndTranslate();
      });
      _captureAndTranslate();
    } else {
      _liveTimer?.cancel();
      _liveTimer = null;
    }
  }

  Future<void> _captureAndTranslate() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final region = Rect.fromLTWH(_position.dx, _position.dy + 40, _size.width, _size.height - 40);
      final settings = ref.read(settingsProvider);
      final ocrRepo = ref.read(ocrRepositoryProvider);
      final translateRepo = ref.read(translationRepositoryProvider);

      final ocrResult = await ocrRepo.recognizeFromRegion(
        region,
        languageHint: settings.sourceLanguage,
      );

      final rawText = ocrResult.fullText.trim();
      if (rawText.isEmpty) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
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

      final translated = await translateRepo.translate(
        text: cleanedText,
        sourceLanguage: settings.sourceLanguage,
        targetLanguage: settings.targetLanguage,
        engine: settings.selectedEngine,
        apiKey: settings.deepLApiKey,
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
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
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
        // 1. Resizable & Draggable Floating Frame (Hollow / See-through viewport)
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: SizedBox(
            width: _size.width,
            height: _size.height,
            child: Stack(
              children: [
                // The Hollow Viewfinder Frame (Hoàn toàn trong suốt 100%, không màu nền)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isLiveScanning ? Colors.greenAccent : Colors.cyanAccent,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isLiveScanning ? Colors.greenAccent : Colors.cyanAccent)
                              .withValues(alpha: 0.35),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),

                // Crosshairs to indicate active capture zone
                Positioned(
                  top: 42,
                  left: 6,
                  child: Icon(Icons.crop_free, size: 16, color: Colors.cyanAccent.withValues(alpha: 0.7)),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Icon(Icons.crop_free, size: 16, color: Colors.cyanAccent.withValues(alpha: 0.7)),
                ),

                // 2. Attached Floating Header Bar (Kéo thả để di chuyển khung trên toàn màn hình)
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
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        border: Border(
                          bottom: BorderSide(
                            color: _isLiveScanning ? Colors.greenAccent : Colors.cyanAccent,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.drag_indicator, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _isLiveScanning ? '🔴 LIVE DỊCH' : '🔍 KHUNG DỊCH',
                            style: TextStyle(
                              color: _isLiveScanning ? Colors.greenAccent : Colors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),

                          // Single Translate Button
                          IconButton(
                            icon: _isProcessing
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                                  )
                                : const Icon(Icons.translate, color: Colors.cyanAccent, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Dịch vùng này (Alt+S)',
                            onPressed: _isProcessing ? null : _captureAndTranslate,
                          ),
                          const SizedBox(width: 10),

                          // Live Scanning Toggle
                          IconButton(
                            icon: Icon(
                              _isLiveScanning ? Icons.pause_circle_filled : Icons.play_circle_fill,
                              color: _isLiveScanning ? Colors.greenAccent : Colors.white70,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: _isLiveScanning ? 'Tạm dừng quét liên tục' : 'Bật quét liên tục theo thời gian thực',
                            onPressed: _toggleLiveScanning,
                          ),
                          const SizedBox(width: 10),

                          // Close Lens Button
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
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
                        final newW = (_size.width + details.delta.dx).clamp(200.0, 1400.0);
                        final newH = (_size.height + details.delta.dy).clamp(120.0, 900.0);
                        _size = Size(newW, newH);
                      });
                    },
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: const Icon(Icons.south_east, color: Colors.cyanAccent, size: 13),
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
                  color: theme.backgroundColor.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 16,
                      spreadRadius: 2,
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

        if (_errorMessage != null)
          Positioned(
            left: _position.dx,
            top: _position.dy + _size.height + 6,
            width: _size.width,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Lỗi: $_errorMessage',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
