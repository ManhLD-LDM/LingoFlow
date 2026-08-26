import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../../domain/entities/translation_engine.dart';
import '../../data/datasources/remote/deep_l_api.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _apiKeyController;
  bool _isValidatingKey = false;
  String? _keyValidationMessage;
  bool? _isKeyValid;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: ref.read(settingsProvider).deepLApiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _validateDeepLKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      setState(() {
        _isKeyValid = false;
        _keyValidationMessage = 'Vui lòng nhập DeepL API Key trước khi kiểm tra.';
      });
      return;
    }

    setState(() {
      _isValidatingKey = true;
      _keyValidationMessage = null;
    });

    final deepLApi = DeepLApi();
    final isValid = await deepLApi.validateKey(key);

    ref.read(settingsProvider.notifier).setDeepLApiKey(key);

    setState(() {
      _isValidatingKey = false;
      _isKeyValid = isValid;
      _keyValidationMessage = isValid
          ? '✅ DeepL API Key hợp lệ và sẵn sàng sử dụng!'
          : '❌ DeepL API Key không hợp lệ hoặc đã hết hạn mức.';
    });
  }

  Widget _buildEngineOption({
    required String title,
    required String subtitle,
    required TranslationEngine engine,
    required TranslationEngine current,
    required VoidCallback onTap,
  }) {
    final isSelected = engine == current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.cyanAccent : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.cyanAccent : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Cài đặt LingoFlow', style: TextStyle(color: Colors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section: Translation Engine Selection
          const Text(
            'BỘ MÁY DỊCH THUẬT (TRANSLATION ENGINE)',
            style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildEngineOption(
                  title: 'Google Translate',
                  subtitle: 'Miễn phí, tốc độ cao, không cần cấu hình API Key',
                  engine: TranslationEngine.google,
                  current: settings.selectedEngine,
                  onTap: () => notifier.setSelectedEngine(TranslationEngine.google),
                ),
                const SizedBox(height: 10),
                _buildEngineOption(
                  title: 'DeepL API',
                  subtitle: 'Chất lượng cao nhất cho Manga, Game & Visual Novel (Cần API Key)',
                  engine: TranslationEngine.deepl,
                  current: settings.selectedEngine,
                  onTap: () => notifier.setSelectedEngine(TranslationEngine.deepl),
                ),
                if (settings.selectedEngine == TranslationEngine.deepl) ...[
                  const Divider(color: Colors.white10, height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DeepL Authentication Key (Free hoặc Pro):',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _apiKeyController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Nhập khóa bí mật DeepL API Key...',
                                hintStyle: const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onChanged: (val) => notifier.setDeepLApiKey(val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isValidatingKey ? null : _validateDeepLKey,
                            child: _isValidatingKey
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Text('Kiểm tra', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      if (_keyValidationMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _keyValidationMessage!,
                          style: TextStyle(
                            color: _isKeyValid == true ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Overlay Behavior
          const Text(
            'HÀNH VI OVERLAY (CHẾ ĐỘ XUYÊN THẤU)',
            style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Bật chế độ Click-through', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text(
                    'Cho phép click chuột xuyên qua bản dịch xuống game/ứng dụng bên dưới.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  value: settings.isClickThrough,
                  activeThumbColor: Colors.cyanAccent,
                  onChanged: (val) => notifier.setClickThrough(val),
                ),
                const Divider(color: Colors.white10, height: 1),
                ListTile(
                  title: const Text('Phím tắt Bật/Tắt Xuyên Thấu (Hotkey Toggle)', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Nhấn để chuyển đổi giữa chế độ Xuyên Thấu và Tra Từ Điển', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text('Alt + X', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Performance & Scan Frequency
          const Text(
            'TẦN SUẤT QUÉT & HIỆU NĂNG',
            style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Chu kỳ quét tự động (Scan Interval):', style: TextStyle(color: Colors.white, fontSize: 14)),
                    Text('${(settings.scanIntervalMs / 1000).toStringAsFixed(1)} giây', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: settings.scanIntervalMs.toDouble(),
                  min: 500,
                  max: 5000,
                  divisions: 9,
                  activeColor: Colors.cyanAccent,
                  inactiveColor: Colors.white24,
                  onChanged: (val) => notifier.setScanInterval(val.toInt()),
                ),
                const Text(
                  '💡 Gợi ý: 1.5s là mức lý tưởng để không làm giảm FPS khi chơi game.',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Appearance
          const Text(
            'GIAO DIỆN HIỂN THỊ OVERLAY',
            style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Độ mờ nền bản dịch (Opacity):', style: TextStyle(color: Colors.white, fontSize: 14)),
                    Text('${(settings.overlayOpacity * 100).toInt()}%', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: settings.overlayOpacity,
                  min: 0.2,
                  max: 1.0,
                  divisions: 8,
                  activeColor: Colors.cyanAccent,
                  inactiveColor: Colors.white24,
                  onChanged: (val) => notifier.setOverlayOpacity(val),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cỡ chữ bản dịch (Font Size):', style: TextStyle(color: Colors.white, fontSize: 14)),
                    Text('${settings.fontSize.toInt()} px', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: settings.fontSize,
                  min: 10,
                  max: 24,
                  divisions: 7,
                  activeColor: Colors.cyanAccent,
                  inactiveColor: Colors.white24,
                  onChanged: (val) => notifier.setFontSize(val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
