import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/languages.dart';
import '../../core/services/hotkey_service.dart';
import '../../core/services/native_overlay_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_colors.dart';
import '../providers/history_provider.dart';
import '../providers/overlay_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/desktop_sidebar.dart';
import '../widgets/desktop_studio_view.dart';
import '../widgets/desktop_titlebar.dart';
import '../widgets/floating_lens.dart';
import '../widgets/nested_button.dart';
import '../widgets/onboarding_wizard.dart';
import '../widgets/status_badge.dart';
import 'history_screen.dart';
import 'overlay_screen.dart';
import 'profiles_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTabIndex = 0;

  final TextEditingController _sandboxInputController =
      TextEditingController(text: '君の前前前世から僕は 僕を探し始めたよ');
  String _sandboxResultText = '';
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

  Future<void> _performSandboxTranslation() async {
    final text = _sandboxInputController.text.trim();
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
        _sandboxResultText = result;
        _isTranslating = false;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    HapticFeedback.lightImpact();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      _sandboxInputController.text = data.text!.trim();
      await _performSandboxTranslation();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard trống hoặc không có văn bản!'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.surfaceModal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _speakText(String text, String lang) {
    HapticFeedback.lightImpact();
    TtsService.speak(text, language: lang);
  }

  void _launchXiaomiOverlay() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OverlayScreen()),
    );
  }

  void _showHotkeyGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceModal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        title: const Row(
          children: [
            Icon(Icons.keyboard, color: AppColors.cyanPrimary),
            SizedBox(width: 10),
            Text('Phím Tắt Toàn Năng (Desktop & Studio)', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogHotkeyRow('Alt + Q', 'Bật / Tắt Khung Dịch Nổi (Floating Lens)'),
            const Divider(color: AppColors.borderLight),
            _buildDialogHotkeyRow('Alt + S', 'Chụp & Dịch vùng chọn tức thì 1 lần'),
            const Divider(color: AppColors.borderLight),
            _buildDialogHotkeyRow('Alt + X', 'Bật / Tắt chế độ Xuyên Thấu (Click-Through)'),
            const Divider(color: AppColors.borderLight),
            _buildDialogHotkeyRow('Ctrl + Enter', 'Dịch văn bản ngay trong Studio Editor'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyanPrimary,
              foregroundColor: AppColors.textDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceCore,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderCyan),
            ),
            child: Text(shortcut, style: const TextStyle(color: AppColors.cyanPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sandboxInputController.dispose();
    HotkeyService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopWidth = screenWidth >= 800;

    // If direct lens mode active on desktop
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

    // ==================== DESKTOP ADAPTIVE LAYOUT (Width >= 800px) ====================
    if (isDesktopWidth) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: DesktopTitlebar(
          onHelpPressed: _showHotkeyGuide,
        ),
        body: Row(
          children: [
            // Left Collapsible Glass Sidebar
            DesktopSidebar(
              selectedIndex: _currentTabIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentTabIndex = index;
                });
              },
            ),

            // Main Desktop Content View
            Expanded(
              child: IndexedStack(
                index: _currentTabIndex,
                children: const [
                  DesktopStudioView(),
                  ProfilesScreen(isEmbedded: true),
                  HistoryScreen(isEmbedded: true),
                  SettingsScreen(isEmbedded: true),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ==================== MOBILE ADAPTIVE LAYOUT (Width < 800px) ====================
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LingoFlow',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.5,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: 8),
            StatusBadge(label: 'PRO', isLive: true),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppColors.cyanPrimary),
            tooltip: 'Hướng dẫn 3 bước',
            onPressed: () => OnboardingWizardDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textSecondary),
            tooltip: 'Phím tắt hệ thống',
            onPressed: _showHotkeyGuide,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Current Tab Body View
          Positioned.fill(
            bottom: 74, // Leave space for Floating Bottom Bar
            child: IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildMobileDashboardTab(settings),
                const ProfilesScreen(isEmbedded: true),
                const HistoryScreen(isEmbedded: true),
                const SettingsScreen(isEmbedded: true),
              ],
            ),
          ),

          // Floating Glass Bottom Navigation Bar (Thumb-Zone Optimized)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: _buildFloatingBottomNav(),
          ),
        ],
      ),
    );
  }

  /// Mobile Dashboard Tab
  Widget _buildMobileDashboardTab(SettingsState settings) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // 1. HERO CARD: Launch Xiaomi Floating Widget Button
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceShell.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.heroCardGradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderCyan, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyanPrimary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cyanPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.picture_in_picture_alt, color: AppColors.cyanPrimary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xiaomi HyperFloat Widget',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Thanh nổi hít mép thông minh cho Game & Manga',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Launch Overlay Button
                NestedButton(
                  label: 'KÍCH HOẠT FLOATING WIDGET',
                  icon: Icons.open_in_new,
                  trailingIcon: Icons.arrow_forward,
                  width: double.infinity,
                  height: 50,
                  isPrimary: true,
                  onPressed: _launchXiaomiOverlay,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. LANGUAGE SELECTOR BANNER
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceShell,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              // Source Lang Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DỊCH TỪ', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCore,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: settings.sourceLanguage,
                          dropdownColor: AppColors.surfaceModal,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
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
                  ],
                ),
              ),

              // Swap icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: IconButton(
                  icon: const Icon(Icons.swap_horiz, color: AppColors.cyanPrimary),
                  tooltip: 'Đổi chiều ngôn ngữ',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                  },
                ),
              ),

              // Target Lang Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SANG', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCore,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: settings.targetLanguage,
                          dropdownColor: AppColors.surfaceModal,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
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
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. LIVE TRANSLATION SANDBOX BOX
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceShell,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note, color: AppColors.cyanPrimary, size: 18),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'HỘP TEST DỊCH NHANH',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.cyanPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    ),
                    icon: const Icon(Icons.content_paste, size: 13),
                    label: const Text('Dán', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: _pasteFromClipboard,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Input field
              TextField(
                controller: _sandboxInputController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Nhập hoặc dán văn bản cần dịch...',
                  filled: true,
                  fillColor: AppColors.surfaceCore,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // Action translate button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyanPrimary,
                        foregroundColor: AppColors.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isTranslating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark))
                          : const Icon(Icons.g_translate, size: 18),
                      label: Text(_isTranslating ? 'Đang dịch...' : 'DỊCH NGAY', style: const TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _isTranslating ? null : _performSandboxTranslation,
                    ),
                  ),
                ],
              ),

              // Translation Result Box
              if (_sandboxResultText.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCore,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderCyan),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('BẢN DỊCH KẾT QUẢ', style: TextStyle(color: AppColors.cyanPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.volume_up, color: AppColors.cyanPrimary, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Nghe đọc',
                            onPressed: () => _speakText(_sandboxResultText, settings.targetLanguage),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy, color: AppColors.textSecondary, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Sao chép',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _sandboxResultText));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        _sandboxResultText,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Floating Glass Bottom Navigation Bar (Mobile)
  Widget _buildFloatingBottomNav() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceShell.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLight, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_filled, 'Dashboard'),
              _buildNavItem(1, Icons.sports_esports, 'Profiles'),
              _buildNavItem(2, Icons.history_edu, 'Lịch Sử'),
              _buildNavItem(3, Icons.settings, 'Cài Đặt'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _currentTabIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyanPrimary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.cyanPrimary.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.cyanPrimary : AppColors.textSecondary,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.cyanPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
