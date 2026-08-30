import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/dictionary_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_colors.dart';
import '../providers/history_provider.dart';

class DictionaryPopup extends ConsumerStatefulWidget {
  final String word;
  final String sourceLang;
  final String targetLang;

  const DictionaryPopup({
    super.key,
    required this.word,
    required this.sourceLang,
    required this.targetLang,
  });

  static Future<void> show(
    BuildContext context, {
    required String word,
    required String sourceLang,
    required String targetLang,
  }) {
    // Show as a modern Glass Bottom Sheet for thumb-friendly mobile interaction
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DictionaryPopup(
        word: word,
        sourceLang: sourceLang,
        targetLang: targetLang,
      ),
    );
  }

  @override
  ConsumerState<DictionaryPopup> createState() => _DictionaryPopupState();
}

class _DictionaryPopupState extends ConsumerState<DictionaryPopup> {
  late Future<WordDefinition> _lookupFuture;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _lookupFuture = DictionaryService().lookupWord(
      word: widget.word,
      sourceLang: widget.sourceLang,
      targetLang: widget.targetLang,
    );
  }

  void _playPronunciation(String word) {
    HapticFeedback.lightImpact();
    TtsService.speak(word, language: widget.sourceLang);
  }

  void _saveToVocabulary(WordDefinition def) {
    HapticFeedback.mediumImpact();
    ref.read(historyProvider.notifier).addRecord(
      originalText: widget.word,
      translatedText: def.definition,
      sourceLanguage: widget.sourceLang,
      targetLanguage: widget.targetLang,
    );
    setState(() {
      _isSaved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.star, color: AppColors.amberStar, size: 18),
            SizedBox(width: 8),
            Text('Đã lưu vào Sổ từ vựng yêu thích! ⭐'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.surfaceModal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceModal.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.borderLight, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            child: FutureBuilder<WordDefinition>(
              future: _lookupFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 160,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.cyanPrimary),
                    ),
                  );
                }

                final def = snapshot.data ??
                    WordDefinition(word: widget.word, reading: '', definition: widget.word);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Drag Pill Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header row with Term & Actions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                def.word,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (def.reading.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.cyanPrimary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        def.reading,
                                        style: const TextStyle(
                                          color: AppColors.cyanPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '(Phiên âm / Romaji)',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Pronounce button
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: AppColors.cyanPrimary, size: 22),
                          tooltip: 'Phát âm',
                          onPressed: () => _playPronunciation(def.word),
                        ),

                        // Star / Bookmark button
                        IconButton(
                          icon: Icon(
                            _isSaved ? Icons.star : Icons.star_border,
                            color: _isSaved ? AppColors.amberStar : AppColors.textSecondary,
                            size: 22,
                          ),
                          tooltip: 'Lưu vào Sổ từ vựng',
                          onPressed: () => _saveToVocabulary(def),
                        ),

                        // Close button
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.borderLight, height: 1),
                    const SizedBox(height: 16),

                    // Definition Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCore,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_stories_outlined, color: AppColors.cyanPrimary, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Ý NGHĨA & ĐỊNH NGHĨA',
                                style: TextStyle(
                                  color: AppColors.cyanPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
                            def.definition,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bottom Action Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.borderLight),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Sao chép từ'),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: def.word));
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.cyanPrimary,
                              foregroundColor: AppColors.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.translate, size: 16),
                            label: const Text('Dịch chi tiết', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
