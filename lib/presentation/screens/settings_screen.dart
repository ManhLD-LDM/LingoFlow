import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
