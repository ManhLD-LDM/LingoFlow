import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/languages.dart';
import '../../core/services/native_overlay_service.dart';
import '../../core/services/hotkey_service.dart';
import '../providers/settings_provider.dart';
import '../providers/overlay_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/floating_lens.dart';
import '../widgets/onboarding_wizard.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'profiles_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _testController =
      TextEditingController(text: 'こんにちは世界 (Xin chào thế giới)');
  String _testTranslationResult = '';
  bool _isTranslating = false;
  bool _isLensModeActive = false;

  @override
  void initState() {
    super.initState();
    _setupHotkeys();
  }

  Future<void> _setupHotkeys() async {
    await HotkeyService.initialize(
      onToggleClickThrough: () {
        final current = ref.read(settingsProvider).isClickThrough;
        final next = !current;
        ref.read(settingsProvider.notifier).setClickThrough(next);
        NativeOverlayService.setClickThrough(next);
      },
      onSingleCapture: () async {
        await ref.read(overlayProvider.notifier).performScanCycle();
      },
      onToggleScan: () {
        setState(() {
          _isLensModeActive = !_isLensModeActive;
        });
      },
    );
  }

  Future<void> _performTestTranslation() async {
    final text = _testController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isTranslating = true;
    });

    final settings = ref.read(settingsProvider);
    final repo = ref.read(translationRepositoryProvider);

    final result = await repo.translate(
      text: text,
      sourceLanguage: settings.sourceLanguage,
      targetLanguage: settings.targetLanguage,
      engine: settings.selectedEngine,
      apiKey: settings.deepLApiKey,
    );

    // Save to History
    ref.read(historyProvider.notifier).addRecord(
      originalText: text,
      translatedText: result,
      sourceLanguage: settings.sourceLanguage,
      targetLanguage: settings.targetLanguage,
    );

    setState(() {
      _testTranslationResult = result;
      _isTranslating = false;
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _testController.text = data.text!.trim();
      await _performTestTranslation();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard trống hoặc không chứa văn bản!'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF0F172A),
          ),
        );
      }
    }
  }

  void _showHotkeyGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.3)),
        ),
        title: const Row(
          children: [
            Icon(Icons.keyboard, color: Colors.cyanAccent),
            SizedBox(width: 10),
            Text('Phím Tắt Hệ Thống', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHotkeyRow('Alt + Q', 'Bật / Tắt Khung Dịch Nổi (Floating Lens)'),
            const Divider(color: Colors.white10),
            _buildDialogHotkeyRow('Alt + S', 'Chụp & Dịch vùng chọn tức thì 1 lần'),
            const Divider(color: Colors.white10),
            _buildDialogHotkeyRow('Alt + X', 'Bật / Tắt chế độ Xuyên Thấu (Click-Through)'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogHotkeyRow(String shortcut, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(description, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
            ),
            child: Text(shortcut, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _testController.dispose();
    HotkeyService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    // If Lens Mode is active, show the interactive Snipping Lens on screen
    if (_isLensModeActive) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            FloatingLens(
              onClose: () {
                setState(() {
                  _isLensModeActive = false;
                });
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.translate, color: Colors.cyanAccent, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'LingoFlow',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'v1.0-live',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.cyanAccent),
            tooltip: 'Hướng dẫn thiết lập 3 bước',
            onPressed: () => OnboardingWizardDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white70),
            tooltip: 'Hướng dẫn phím tắt (F1)',
            onPressed: _showHotkeyGuide,
          ),
          IconButton(
            icon: const Icon(Icons.history_edu_outlined, color: Colors.cyanAccent),
            tooltip: 'Lịch sử & Sổ từ vựng ⭐',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sports_esports_outlined, color: Colors.cyanAccent),
            tooltip: 'Hồ sơ Game & Từ điển thuật ngữ (Glossary)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            tooltip: 'Cài đặt',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Primary Action: Launch Floating Lens Box
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.crop_free, color: Colors.cyanAccent, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Khung Dịch Nổi (Floating Lens Box)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Di chuyển khung đè lên game/truyện để dịch tức thì vùng đó.',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text(
                    'BẬT KHUNG DỊCH',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () {
                    setState(() {
                      _isLensModeActive = true;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Language Selector Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Từ ngôn ngữ (Nguồn):',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1E293B),
                            value: settings.sourceLanguage,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            items: AppLanguages.supportedSources.entries.map((e) {
                              return DropdownMenuItem(
                                value: e.key,
                                child: Text('${e.value} (${e.key.toUpperCase()})'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(settingsProvider.notifier).setSourceLanguage(val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.arrow_forward, color: Colors.cyanAccent),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sang ngôn ngữ (Đích):',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1E293B),
                            value: settings.targetLanguage,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            items: AppLanguages.supportedTargets.entries.map((e) {
                              return DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(settingsProvider.notifier).setTargetLanguage(val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Quick Hotkeys Cheat-sheet
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.keyboard_outlined, color: Colors.cyanAccent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Phím tắt toàn hệ thống (Global Hotkeys)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _showHotkeyGuide,
                      child: const Text('Chi tiết', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHotkeyBadge('Alt + Q', 'Bật/Tắt Khung Dịch'),
                    _buildHotkeyBadge('Alt + S', 'Dịch ngay vùng chọn'),
                    _buildHotkeyBadge('Alt + X', 'Xuyên thấu / Tương tác'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Live Translation Tester Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kiểm tra Dịch thuật (Live Translation Test)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pasteFromClipboard,
                      icon: const Icon(Icons.paste, size: 14, color: Colors.cyanAccent),
                      label: const Text('Dán Clipboard', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _testController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Nhập câu tiếng Nhật/Trung/Anh bất kỳ để test thử...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Engine: ${settings.selectedEngine.displayName}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isTranslating ? null : _performTestTranslation,
                      icon: _isTranslating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.translate, size: 16),
                      label: const Text('Dịch thử', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (_testTranslationResult.isNotEmpty) ...[
                  const Divider(color: Colors.white10, height: 20),
                  const Text('Kết quả dịch:', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _testTranslationResult,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotkeyBadge(String hotkey, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
          ),
          child: Text(
            hotkey,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}
