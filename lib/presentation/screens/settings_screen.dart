import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/translation_engine.dart';
import '../../domain/entities/subtitle_style.dart';
import '../../domain/entities/ocr_engine_mode.dart';
import '../../data/datasources/remote/deep_l_api.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;

  const SettingsScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _deepLKeyController;
  late TextEditingController _ocrKeyController;
  bool _isValidatingKey = false;
  String? _keyValidationMessage;
  bool? _isKeyValid;

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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    Widget content = Column(
      children: [
        // Tab Navigation
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceCore,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: AppColors.textDark,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(icon: Icon(Icons.palette_outlined, size: 16), text: 'Giao Diện Phụ Đề'),
              Tab(icon: Icon(Icons.translate, size: 16), text: 'Bộ Dịch Thuật'),
              Tab(icon: Icon(Icons.document_scanner_outlined, size: 16), text: 'Bộ Nhận Diện OCR'),
              Tab(icon: Icon(Icons.tune, size: 16), text: 'Hệ Thống & Phím Tắt'),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSubtitleTab(settings, notifier),
              _buildTranslationTab(settings, notifier),
              _buildOcrTab(settings, notifier),
              _buildSystemTab(settings, notifier),
            ],
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Cài Đặt Hệ Thống'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: content,
    );
  }

  /// TAB 1: Subtitle Customizer with Live Preview Box
  Widget _buildSubtitleTab(SettingsState settings, SettingsNotifier notifier) {
    final currentTheme = settings.subtitleTheme;
    final isWide = MediaQuery.of(context).size.width >= 800;

    final previewBox = Container(
      height: isWide ? 180 : 130,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF030712),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: currentTheme.backgroundColor.withValues(alpha: settings.overlayOpacity),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: currentTheme.borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '君の名は。 (Tên cậu là gì?)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: currentTheme.textColor,
                  fontSize: settings.fontSize,
                  fontWeight: FontWeight.bold,
                  height: 1.35,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Presets
        const Text('CHỦ ĐỀ MÀU PHỤ ĐỀ (PRESETS)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: SubtitleTheme.values.map((theme) {
            final isSelected = settings.subtitleTheme == theme;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => notifier.setSubtitleTheme(theme),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.cyanPrimary.withValues(alpha: 0.15) : AppColors.surfaceShell,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.cyanPrimary : AppColors.borderLight,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        theme.name.split(' ').first,
                        style: TextStyle(
                          color: isSelected ? AppColors.cyanPrimary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Font Size Slider
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceShell,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cỡ Chữ Phụ Đề', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${settings.fontSize.toInt()} px', style: const TextStyle(color: AppColors.cyanPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: settings.fontSize,
                min: 12,
                max: 32,
                divisions: 10,
                onChanged: (val) => notifier.setFontSize(val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Overlay Opacity Slider
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceShell,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Độ Đậm / Trong Suốt Phụ Đề', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${(settings.overlayOpacity * 100).toInt()}%', style: const TextStyle(color: AppColors.cyanPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: settings.overlayOpacity,
                min: 0.2,
                max: 1.0,
                divisions: 8,
                onChanged: (val) => notifier.setOverlayOpacity(val),
              ),
            ],
          ),
        ),
      ],
    );

    if (isWide) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'XEM TRƯỚC TRỰC TIẾP (LIVE SUBTITLE PREVIEW)',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  previewBox,
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(flex: 55, child: SingleChildScrollView(child: controls)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'XEM TRƯỚC TRỰC TIẾP (LIVE SUBTITLE PREVIEW)',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        previewBox,
        const SizedBox(height: 16),
        controls,
      ],
    );
  }

  /// TAB 2: Translation Engine Selector
  Widget _buildTranslationTab(SettingsState settings, SettingsNotifier notifier) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    final enginesList = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CHỌN BỘ MÁY DỊCH THUẬT',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),

        _buildEngineCard(
          title: 'Google Dịch (Miễn Phí)',
          subtitle: 'Nhanh, không cần API Key, hỗ trợ hơn 100 ngôn ngữ.',
          engine: TranslationEngine.google,
          current: settings.selectedEngine,
          onTap: () => notifier.setSelectedEngine(TranslationEngine.google),
        ),
        const SizedBox(height: 10),

        _buildEngineCard(
          title: 'DeepL API (Chất lượng cao)',
          subtitle: 'Dịch câu văn tự nhiên chuẩn ngữ cảnh nhất cho Game/Manga.',
          engine: TranslationEngine.deepl,
          current: settings.selectedEngine,
          onTap: () => notifier.setSelectedEngine(TranslationEngine.deepl),
        ),
      ],
    );

    final deeplKeyBox = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceShell,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DeepL Authentication Key', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 6),
          const Text('Nhập key từ tài khoản DeepL API Free / Pro của bạn.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _deepLKeyController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Nhập DeepL API Key...'),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyanPrimary,
                  foregroundColor: AppColors.textDark,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isValidatingKey ? null : _validateDeepLKey,
                child: _isValidatingKey
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark))
                    : const Text('Kiểm tra Key', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_keyValidationMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _keyValidationMessage!,
              style: TextStyle(
                color: _isKeyValid == true ? AppColors.emeraldLive : AppColors.redRecord,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    if (isWide) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 50, child: enginesList),
            const SizedBox(width: 16),
            Expanded(flex: 50, child: deeplKeyBox),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        enginesList,
        const SizedBox(height: 16),
        deeplKeyBox,
      ],
    );
  }

  /// TAB 3: OCR Engine Selector
  Widget _buildOcrTab(SettingsState settings, SettingsNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'CHỌN CÔNG NGHỆ NHẬN DIỆN CHỮ (OCR)',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),

        _buildOcrCard(
          title: 'Tự động (Auto Fallback)',
          subtitle: 'Ưu tiên Cloud OCR, tự động chuyển Native khi mất mạng.',
          mode: OcrEngineMode.autoFallback,
          current: settings.ocrEngineMode,
          onTap: () => notifier.setOcrEngineMode(OcrEngineMode.autoFallback),
        ),
        const SizedBox(height: 10),

        _buildOcrCard(
          title: 'Cloud OCR.space Only',
          subtitle: 'Tối ưu cho chữ tượng hình phức tạp (Kanji, Hán tự, Hangul).',
          mode: OcrEngineMode.cloudOnly,
          current: settings.ocrEngineMode,
          onTap: () => notifier.setOcrEngineMode(OcrEngineMode.cloudOnly),
        ),
        const SizedBox(height: 10),

        _buildOcrCard(
          title: 'Native / Offline OCR Only',
          subtitle: 'Nhận diện trực tiếp tốc độ cao (<50ms), không tốn mạng.',
          mode: OcrEngineMode.offlineOnly,
          current: settings.ocrEngineMode,
          onTap: () => notifier.setOcrEngineMode(OcrEngineMode.offlineOnly),
        ),
      ],
    );
  }

  /// TAB 4: System Preferences & Hotkeys
  Widget _buildSystemTab(SettingsState settings, SettingsNotifier notifier) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Scan Interval
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceShell,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tần Suất Quét Live (Độ trễ)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${settings.scanIntervalMs} ms', style: const TextStyle(color: AppColors.cyanPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: settings.scanIntervalMs.toDouble(),
                min: 300,
                max: 3000,
                divisions: 9,
                onChanged: (val) => notifier.setScanInterval(val.toInt()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Click-Through Option
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceShell,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chế Độ Xuyên Thấu Mặc Định', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Cho phép click chuột xuyên qua bản dịch để chơi game', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: settings.isClickThrough,
                activeTrackColor: AppColors.cyanPrimary,
                onChanged: (val) => notifier.setClickThrough(val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEngineCard({
    required String title,
    required String subtitle,
    required TranslationEngine engine,
    required TranslationEngine current,
    required VoidCallback onTap,
  }) {
    final isSelected = engine == current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyanPrimary.withValues(alpha: 0.12) : AppColors.surfaceShell,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.cyanPrimary : AppColors.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.cyanPrimary : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? AppColors.cyanPrimary : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOcrCard({
    required String title,
    required String subtitle,
    required OcrEngineMode mode,
    required OcrEngineMode current,
    required VoidCallback onTap,
  }) {
    final isSelected = mode == current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyanPrimary.withValues(alpha: 0.12) : AppColors.surfaceShell,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.cyanPrimary : AppColors.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.cyanPrimary : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? AppColors.cyanPrimary : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
