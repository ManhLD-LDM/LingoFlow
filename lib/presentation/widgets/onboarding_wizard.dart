import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/languages.dart';
import '../../domain/entities/ocr_engine_mode.dart';
import '../providers/settings_provider.dart';

class OnboardingWizardDialog extends ConsumerStatefulWidget {
  const OnboardingWizardDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const OnboardingWizardDialog(),
    );
  }

  @override
  ConsumerState<OnboardingWizardDialog> createState() => _OnboardingWizardDialogState();
}

class _OnboardingWizardDialogState extends ConsumerState<OnboardingWizardDialog> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Chào mừng đến với LingoFlow',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Step Progress Indicator
            Row(
              children: [
                _buildStepBadge(0, '1. Ngôn ngữ'),
                _buildStepDivider(0),
                _buildStepBadge(1, '2. Nhận diện'),
                _buildStepDivider(1),
                _buildStepBadge(2, '3. Hoàn tất'),
              ],
            ),
            const SizedBox(height: 24),

            // Step Content
            if (_currentStep == 0) ...[
              _buildStep1Language(settings, notifier),
            ] else if (_currentStep == 1) ...[
              _buildStep2OcrStrategy(settings, notifier),
            ] else ...[
              _buildStep3Hotkeys(),
            ],

            const SizedBox(height: 24),

            // Actions Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  TextButton.icon(
                    onPressed: () => setState(() => _currentStep--),
                    icon: const Icon(Icons.arrow_back, size: 16, color: Colors.white70),
                    label: const Text('Quay lại', style: TextStyle(color: Colors.white70)),
                  )
                else
                  const SizedBox.shrink(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (_currentStep < 2) {
                      setState(() => _currentStep++);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(_currentStep < 2 ? Icons.arrow_forward : Icons.check_circle, size: 18),
                  label: Text(
                    _currentStep < 2 ? 'Tiếp tục' : 'Bắt đầu sử dụng ngay',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBadge(int stepIndex, String title) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.cyanAccent
                : isDone
                    ? Colors.cyanAccent.withValues(alpha: 0.3)
                    : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive || isDone ? Colors.cyanAccent : Colors.white24,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.white,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int afterStep) {
    final isDone = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: isDone ? Colors.cyanAccent : Colors.white12,
      ),
    );
  }

  Widget _buildStep1Language(SettingsState settings, SettingsNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bước 1: Chọn cặp ngôn ngữ bạn muốn dịch', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        const Text('Cấu hình này áp dụng cho toàn bộ Game, Visual Novel và Manga.', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ngôn ngữ nguồn:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        value: settings.sourceLanguage,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: AppLanguages.supportedSources.entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text(e.value));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) notifier.setSourceLanguage(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Icon(Icons.arrow_forward, color: Colors.cyanAccent),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ngôn ngữ dịch ra:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E293B),
                        value: settings.targetLanguage,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: AppLanguages.supportedTargets.entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text(e.value));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) notifier.setTargetLanguage(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2OcrStrategy(SettingsState settings, SettingsNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bước 2: Chọn chiến lược nhận diện chữ viết (OCR)', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        const Text('LingoFlow hỗ trợ đa tầng nhận diện linh hoạt.', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 14),
        ...OcrEngineMode.values.map((mode) {
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
                        Text(mode.description, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep3Hotkeys() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bước 3: Ghi nhớ 3 phím tắt quan trọng nhất', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        const Text('Phím tắt hoạt động toàn cầu đè lên mọi game/cửa sổ không cần Alt+Tab.', style: TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 12),
        _buildHotkeySummaryRow('Alt + Q', 'Bật / Tắt Khung Dịch Nổi (Floating Lens)'),
        const Divider(color: Colors.white10, height: 12),
        _buildHotkeySummaryRow('Alt + S', 'Chụp & Dịch ngay lập tức vùng đang chọn'),
        const Divider(color: Colors.white10, height: 12),
        _buildHotkeySummaryRow('Alt + X', 'Bật chế độ Xuyên Thấu (Click-Through Game)'),
      ],
    );
  }

  Widget _buildHotkeySummaryRow(String shortcut, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
          ),
          child: Text(shortcut, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }
}
