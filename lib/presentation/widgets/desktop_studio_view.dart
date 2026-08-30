import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/languages.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_colors.dart';
import '../providers/history_provider.dart';
import '../providers/overlay_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/overlay_screen.dart';
import 'nested_button.dart';

class DesktopStudioView extends ConsumerStatefulWidget {
  const DesktopStudioView({super.key});

  @override
  ConsumerState<DesktopStudioView> createState() => _DesktopStudioViewState();
}

class _DesktopStudioViewState extends ConsumerState<DesktopStudioView> {
  final TextEditingController _sourceController =
      TextEditingController(text: '君の前前前世から僕は 僕を探し始めたよ');
  String _translatedResult = '';
  bool _isTranslating = false;

  @override
  void dispose() {
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _performTranslation() async {
    final text = _sourceController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isTranslating = true;
    });

    final settings = ref.read(settingsProvider);
    final repo = ref.read(translationRepositoryProvider);
    final profile = ref.read(profileProvider).activeProfile;

    final result = await repo.translate(
      text: text,
      sourceLanguage: settings.sourceLanguage,
      targetLanguage: settings.targetLanguage,
      engine: settings.selectedEngine,
      apiKey: settings.deepLApiKey,
      glossary: profile.glossary,
    );

    // Save to History
    ref.read(historyProvider.notifier).addRecord(
      originalText: text,
      translatedText: result,
      sourceLanguage: settings.sourceLanguage,
      targetLanguage: settings.targetLanguage,
    );

    if (mounted) {
      setState(() {
        _translatedResult = result;
        _isTranslating = false;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    HapticFeedback.lightImpact();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _sourceController.text = data.text!.trim();
      await _performTranslation();
    }
  }

  void _copyToClipboard(String text, String label) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label vào Clipboard!'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.surfaceModal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _speakText(String text, String lang) {
    HapticFeedback.lightImpact();
    TtsService.speak(text, language: lang);
  }

  void _launchOverlay() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OverlayScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final profileState = ref.watch(profileProvider);
    final activeProfile = profileState.activeProfile;
    final historyState = ref.watch(historyProvider);
    final starredItems = historyState.items.where((it) => it.isFavorite).take(5).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== LEFT MAIN WORKSPACE (66%) ====================
          Expanded(
            flex: 66,
            child: ListView(
              children: [
                // 1. HERO DESKTOP LAUNCH BAR (Doppelrand Container)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceShell.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroCardGradient,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderCyan, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyanPrimary.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cyanPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.desktop_windows_outlined, color: AppColors.cyanPrimary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Desktop Overlay & Screen Capture',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Bật thanh nổi HyperFloat đè lên Game/Manga hoặc quét vùng chọn tức thì',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Quick Capture 1-shot (Alt+S)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.cyanPrimary,
                            side: const BorderSide(color: AppColors.cyanPrimary),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                          label: const Text('CHỤP 1 LẦN (Alt+S)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () {
                            ref.read(overlayProvider.notifier).performScanCycle();
                          },
                        ),
                        const SizedBox(width: 10),

                        // Launch Overlay Button
                        NestedButton(
                          label: 'MỞ OVERLAY',
                          icon: Icons.open_in_new,
                          trailingIcon: Icons.arrow_forward,
                          height: 46,
                          isPrimary: true,
                          onPressed: _launchOverlay,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. SIDE-BY-SIDE DUAL TRANSLATION EDITOR
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceShell,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      // Header: Language Bar & Central Action
                      Row(
                        children: [
                          // Source Language Selector
                          Expanded(
                            child: Row(
                              children: [
                                const Text('NGUỒN:', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCore,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: settings.sourceLanguage,
                                      dropdownColor: AppColors.surfaceModal,
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                      items: AppLanguages.supportedSources.entries.map((e) {
                                        return DropdownMenuItem(value: e.key, child: Text(e.value));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          ref.read(settingsProvider.notifier).setSourceLanguage(val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  style: TextButton.styleFrom(foregroundColor: AppColors.cyanPrimary, padding: const EdgeInsets.symmetric(horizontal: 8)),
                                  icon: const Icon(Icons.content_paste, size: 14),
                                  label: const Text('Dán Clipboard', style: TextStyle(fontSize: 11)),
                                  onPressed: _pasteFromClipboard,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 16),
                                  tooltip: 'Xóa trắng',
                                  onPressed: () {
                                    _sourceController.clear();
                                    setState(() {
                                      _translatedResult = '';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Central Divider with Translate Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.cyanPrimary,
                                foregroundColor: AppColors.textDark,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: _isTranslating
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark))
                                  : const Icon(Icons.translate, size: 16),
                              label: const Text('DỊCH (Ctrl+Enter)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: _isTranslating ? null : _performTranslation,
                            ),
                          ),

                          // Target Language Selector
                          Expanded(
                            child: Row(
                              children: [
                                const Text('ĐÍCH:', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCore,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: settings.targetLanguage,
                                      dropdownColor: AppColors.surfaceModal,
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                      items: AppLanguages.supportedTargets.entries.map((e) {
                                        return DropdownMenuItem(value: e.key, child: Text(e.value));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          ref.read(settingsProvider.notifier).setTargetLanguage(val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                if (_translatedResult.isNotEmpty) ...[
                                  IconButton(
                                    icon: const Icon(Icons.volume_up_outlined, color: AppColors.cyanPrimary, size: 18),
                                    tooltip: 'Phát âm giọng đọc',
                                    onPressed: () => _speakText(_translatedResult, settings.targetLanguage),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: AppColors.textSecondary, size: 16),
                                    tooltip: 'Sao chép bản dịch',
                                    onPressed: () => _copyToClipboard(_translatedResult, 'bản dịch'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.borderLight, height: 1),
                      const SizedBox(height: 12),

                      // Dual Pane Text Areas (Source Editor & Target Output)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Source Text Input Pane
                            Expanded(
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 180),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCore,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: TextField(
                                  controller: _sourceController,
                                  maxLines: null,
                                  expands: true,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                                  decoration: const InputDecoration(
                                    hintText: 'Nhập hoặc dán văn bản tiếng Nhật/Anh/Trung/Hàn...',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    fillColor: Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Target Text Output Pane
                            Expanded(
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 180),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCore,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _translatedResult.isNotEmpty
                                        ? AppColors.borderCyan
                                        : AppColors.borderLight,
                                  ),
                                ),
                                child: _translatedResult.isEmpty
                                    ? Center(
                                        child: Text(
                                          _isTranslating ? 'Đang dịch...' : 'Bản dịch sẽ xuất hiện tại đây...',
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontStyle: FontStyle.italic),
                                        ),
                                      )
                                    : SingleChildScrollView(
                                        child: SelectableText(
                                          _translatedResult,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // ==================== RIGHT SIDE INSPECTOR (34%) ====================
          Expanded(
            flex: 34,
            child: ListView(
              children: [
                // 1. Matched Game Profile & Glossary Inspector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceShell,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: AppColors.cyanPrimary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'GLOSSARY: ${activeProfile.name.toUpperCase()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${activeProfile.glossary.length} thuật ngữ đang kích hoạt cho tựa game này.',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(height: 12),

                      if (activeProfile.glossary.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Chưa có thuật ngữ nào trong Profile. Hãy thêm từ vựng để dịch chuẩn ngữ cảnh!',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: activeProfile.glossary.entries.take(8).map((e) {
                            return InkWell(
                              onTap: () {
                                _sourceController.text = e.key;
                                _performTranslation();
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCore,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Text(
                                  '${e.key} → ${e.value}',
                                  style: const TextStyle(color: AppColors.cyanPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Recent Starred Vocabulary Bento Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceShell,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.star, color: AppColors.amberStar, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'SỔ TỪ VỰNG YÊU THÍCH ⭐',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (starredItems.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Chưa có từ vựng nào được gắn sao. Hãy chạm ⭐ để lưu lại!',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        )
                      else
                        ...starredItems.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCore,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.originalText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        item.translatedText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppColors.cyanPrimary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.volume_up_outlined, color: AppColors.cyanPrimary, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _speakText(item.originalText, item.sourceLanguage),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
