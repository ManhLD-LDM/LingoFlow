import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/dictionary_service.dart';
import '../../core/services/tts_service.dart';
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
    return showDialog(
      context: context,
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
    TtsService.speak(word, language: widget.sourceLang);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.cyanAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Đang phát âm: "$word"'),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.3)),
      ),
      contentPadding: const EdgeInsets.all(20),
      content: FutureBuilder<WordDefinition>(
        future: _lookupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            );
          }

          final def = snapshot.data ??
              WordDefinition(word: widget.word, reading: '', definition: widget.word);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Word & Pronunciation/Reading & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (def.reading.isNotEmpty)
                          Text(
                            def.reading,
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                def.word,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.volume_up_outlined, color: Colors.cyanAccent, size: 22),
                              tooltip: 'Phát âm giọng đọc AI',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _playPronunciation(def.word),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isSaved ? Icons.star : Icons.star_border,
                      color: _isSaved ? Colors.amberAccent : Colors.white60,
                      size: 26,
                    ),
                    tooltip: 'Lưu vào sổ từ vựng',
                    onPressed: () {
                      setState(() {
                        _isSaved = !_isSaved;
                      });
                      ref.read(historyProvider.notifier).addRecord(
                        originalText: def.word,
                        translatedText: '${def.definition} ${def.reading.isNotEmpty ? "(${def.reading})" : ""}'.trim(),
                        sourceLanguage: widget.sourceLang,
                        targetLanguage: widget.targetLang,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã lưu từ vựng vào Sổ Từ Vựng ⭐'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Color(0xFF0F172A),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24),

              // Definition
              const Text(
                'Ý nghĩa (Definition):',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  def.definition,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),

              // Additional POS details
              if (def.examples.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...def.examples.map(
                  (ex) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      ex,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: widget.word));
            Navigator.pop(context);
          },
          icon: const Icon(Icons.copy, size: 16, color: Colors.cyanAccent),
          label: const Text('Sao chép', style: TextStyle(color: Colors.cyanAccent)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF334155),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
