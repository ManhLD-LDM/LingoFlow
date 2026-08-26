import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/languages.dart';
import '../../core/services/native_overlay_service.dart';
import '../providers/settings_provider.dart';
import '../providers/overlay_provider.dart';

class MiniControlBar extends ConsumerStatefulWidget {
  final VoidCallback onToggleRegionSelect;
  final VoidCallback onClose;
  final bool isSelectingRegion;

  const MiniControlBar({
    super.key,
    required this.onToggleRegionSelect,
    required this.onClose,
    this.isSelectingRegion = false,
  });

  @override
  ConsumerState<MiniControlBar> createState() => _MiniControlBarState();
}

class _MiniControlBarState extends ConsumerState<MiniControlBar> {
  Offset _position = const Offset(20, 20);
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final overlay = ref.watch(overlayProvider);

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: overlay.isScanning
                  ? Colors.greenAccent.withValues(alpha: 0.8)
                  : Colors.cyanAccent.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: _isCollapsed
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: overlay.isScanning ? Colors.greenAccent : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.cyanAccent, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Mở rộng thanh điều khiển',
                      onPressed: () {
                        setState(() {
                          _isCollapsed = false;
                        });
                      },
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle Icon
                    const Icon(Icons.drag_indicator, color: Colors.white38, size: 16),
                    const SizedBox(width: 6),

                    // Live Scan Toggle Button
                    InkWell(
                      onTap: () {
                        if (overlay.isScanning) {
                          ref.read(overlayProvider.notifier).stopScanning();
                        } else {
                          ref.read(overlayProvider.notifier).startScanning();
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: overlay.isScanning
                              ? Colors.greenAccent.withValues(alpha: 0.2)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: overlay.isScanning ? Colors.greenAccent : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              overlay.isScanning ? Icons.pause : Icons.play_arrow,
                              color: overlay.isScanning ? Colors.greenAccent : Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              overlay.isScanning ? 'LIVE' : 'QUÉT',
                              style: TextStyle(
                                color: overlay.isScanning ? Colors.greenAccent : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Instant Single Capture Button
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined, color: Colors.cyanAccent, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Chụp & Dịch 1 lần (Alt+S)',
                      onPressed: () {
                        ref.read(overlayProvider.notifier).performScanCycle();
                      },
                    ),
                    const SizedBox(width: 8),

                    // Click-Through Toggle Button
                    InkWell(
                      onTap: () {
                        final next = !settings.isClickThrough;
                        ref.read(settingsProvider.notifier).setClickThrough(next);
                        NativeOverlayService.setClickThrough(next);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: settings.isClickThrough
                              ? Colors.blueAccent.withValues(alpha: 0.2)
                              : Colors.orangeAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: settings.isClickThrough ? Colors.cyanAccent : Colors.orangeAccent,
                          ),
                        ),
                        child: Text(
                          settings.isClickThrough ? 'Xuyên thấu' : 'Tương tác',
                          style: TextStyle(
                            color: settings.isClickThrough ? Colors.cyanAccent : Colors.orangeAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Quick Language Switcher Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: settings.sourceLanguage,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent, size: 16),
                          items: AppLanguages.supportedSources.entries.map((e) {
                            return DropdownMenuItem(
                              value: e.key,
                              child: Text(e.key.toUpperCase()),
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
                    const SizedBox(width: 8),

                    // Region Selector Trigger
                    IconButton(
                      icon: Icon(
                        widget.isSelectingRegion ? Icons.check : Icons.crop_free,
                        color: widget.isSelectingRegion ? Colors.greenAccent : Colors.cyanAccent,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: widget.isSelectingRegion ? 'Xong chọn vùng' : 'Kéo chọn vùng quét',
                      onPressed: widget.onToggleRegionSelect,
                    ),
                    const SizedBox(width: 8),

                    // Collapse button
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white60, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Thu nhỏ thanh điều khiển',
                      onPressed: () {
                        setState(() {
                          _isCollapsed = true;
                        });
                      },
                    ),
                    const SizedBox(width: 6),

                    // Close overlay button
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Đóng Overlay',
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
