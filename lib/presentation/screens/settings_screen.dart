import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../../domain/entities/translation_engine.dart';
import '../../domain/entities/subtitle_style.dart';
import '../../domain/entities/ocr_engine_mode.dart';
import '../../data/datasources/remote/deep_l_api.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _deepLKeyController;
  late TextEditingController _ocrKeyController;
  bool _isValidatingKey = false;
  String? _keyValidationMessage;
  bool? _isKeyValid;
  bool _isOcrKeySaved = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final settings = ref.read(settingsProvider);
    _deepLKeyController = TextEditingController(text: settings.deepLApiKey);
    _ocrKeyController = TextEditingController(text: settings.ocrApiKey);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _deepLKeyController.dispose();
    _ocrKeyController.dispose();
    super.dispose();
  }

  Future<void> _validateDeepLKey() async {
    final key = _deepLKeyController.text.trim();
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

  void _saveOcrKey() {
    final key = _ocrKeyController.text.trim();
    ref.read(settingsProvider.notifier).setOcrApiKey(key);
    setState(() {
      _isOcrKeySaved = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isOcrKeySaved = false;
        });
      }
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
        title: const Text('Cài đặt LingoFlow', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.translate, size: 20), text: 'Bộ Máy Dịch'),
            Tab(icon: Icon(Icons.document_scanner, size: 20), text: 'Nhận Diện OCR'),
            Tab(icon: Icon(Icons.palette, size: 20), text: 'Giao Diện Phụ Đề'),
            Tab(icon: Icon(Icons.speed, size: 20), text: 'Hiệu Năng & Phím Tắt'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: BỘ MÁY DỊCH THUẬT
          _buildTranslationTab(settings, notifier),

          // TAB 2: NHẬN DIỆN OCR
          _buildOcrTab(settings, notifier),

          // TAB 3: GIAO DIỆN PHỤ ĐỀ
          _buildAppearanceTab(settings, notifier),

          // TAB 4: HIỆU NĂNG & PHÍM TẮT
          _buildPerformanceAndHotkeysTab(settings, notifier),
        ],
      ),
    );
  }

  Widget _buildTranslationTab(SettingsState settings, SettingsNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
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
                            controller: _deepLKeyController,
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
      ],
    );
  }

  Widget _buildOcrTab(SettingsState settings, SettingsNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'BỘ NHẬN DIỆN CHỮ VIẾT (OCR ENGINE)',
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
              const Row(
                children: [
                  Icon(Icons.visibility, color: Colors.cyanAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'OCR.space Asian Cloud Engine 2',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Tối ưu hóa chuyên sâu cho nhận diện chữ tượng hình Nhật/Trung/Hàn và chữ Latinh.',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text('OCR API Key tùy chỉnh (Mặc định đọc từ file .env):', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ocrKeyController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Nhập OCR.space API Key (hoặc để trống để dùng .env)...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isOcrKeySaved ? Colors.greenAccent : Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _saveOcrKey,
                    icon: Icon(_isOcrKeySaved ? Icons.check : Icons.save, size: 16),
                    label: Text(
                      _isOcrKeySaved ? 'Đã lưu' : 'Lưu',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Chiến lược nhận diện (Recognition Strategy):', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Column(
                children: OcrEngineMode.values.map((mode) {
                  final isSelected = mode == settings.ocrEngineMode;
                  return InkWell(
                    onTap: () => notifier.setOcrEngineMode(mode),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.1) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.cyanAccent : Colors.white12,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? Colors.cyanAccent : Colors.white38,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mode.displayName,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  mode.description,
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              const Text(
                '💡 Bạn có thể đăng ký API key miễn phí (25,000 requests/tháng) tại ocr.space/ocrapi/freekey',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceTab(SettingsState settings, SettingsNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'PHONG CÁCH & VỊ TRÍ PHỤ ĐỀ (SUBTITLE STYLING)',
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
              const Text('Giao diện mẫu (Theme Preset):', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SubtitleTheme.values.map((theme) {
                  final isSelected = theme == settings.subtitleTheme;
                  return InkWell(
                    onTap: () => notifier.setSubtitleTheme(theme),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.cyanAccent : theme.borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            theme.name,
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle, size: 14, color: Colors.cyanAccent),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Divider(color: Colors.white10, height: 24),
              const Text('Vị trí hiển thị:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => notifier.setSubtitlePlacement(SubtitlePlacement.inPlace),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: settings.subtitlePlacement == SubtitlePlacement.inPlace
                              ? Colors.cyanAccent.withValues(alpha: 0.1)
                              : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: settings.subtitlePlacement == SubtitlePlacement.inPlace
                                ? Colors.cyanAccent
                                : Colors.white12,
                          ),
                        ),
                        child: const Text('Đè lên vị trí gốc (In-place)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => notifier.setSubtitlePlacement(SubtitlePlacement.bottomCenter),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: settings.subtitlePlacement == SubtitlePlacement.bottomCenter
                              ? Colors.cyanAccent.withValues(alpha: 0.1)
                              : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: settings.subtitlePlacement == SubtitlePlacement.bottomCenter
                                ? Colors.cyanAccent
                                : Colors.white12,
                          ),
                        ),
                        child: const Text('Phía dưới (Movie Subtitle)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'ĐỘ MỜ & CỠ CHỮ',
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
        const SizedBox(height: 20),

        const Text(
          'XEM TRƯỚC PHỤ ĐỀ TRÊN MÀN HÌNH (LIVE PREVIEW)',
          style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1.5),
            gradient: const RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [Color(0xFF312E81), Color(0xFF0F172A)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 12,
                child: Row(
                  children: [
                    const Icon(Icons.videogame_asset, size: 14, color: Colors.cyanAccent),
                    const SizedBox(width: 6),
                    Text(
                      'Mô phỏng hiển thị trên Game / Manga (${settings.subtitleTheme.name}):',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: settings.subtitlePlacement == SubtitlePlacement.inPlace
                    ? const Alignment(0, 0.1)
                    : const Alignment(0, 0.7),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: settings.subtitleTheme.backgroundColor.withValues(alpha: settings.overlayOpacity),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: settings.subtitleTheme.borderColor, width: 1.5),
                  ),
                  child: Text(
                    '「俺は海賊王になる男だ！」 ➜ Tôi là người đàn ông sẽ trở thành Vua Hải Tặc!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: settings.subtitleTheme.textColor,
                      fontSize: settings.fontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceAndHotkeysTab(SettingsState settings, SettingsNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
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
            ],
          ),
        ),
        const SizedBox(height: 20),

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
        const SizedBox(height: 20),

        const Text(
          'BẢNG PHÍM TẮT TOÀN CỤC (GLOBAL HOTKEYS)',
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
              _buildHotkeyRow('Alt + Q', 'Bật / Tắt chế độ quét tự động liên tục (Live Auto-Scan)'),
              const Divider(color: Colors.white10, height: 1),
              _buildHotkeyRow('Alt + S', 'Chụp & dịch tức thì 1 lần (Single-shot Capture)'),
              const Divider(color: Colors.white10, height: 1),
              _buildHotkeyRow('Alt + X', 'Bật / Tắt chế độ Xuyên Thấu (Click-Through)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHotkeyRow(String shortcut, String description) {
    return ListTile(
      title: Text(description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
        ),
        child: Text(shortcut, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}
