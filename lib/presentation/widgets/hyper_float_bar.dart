import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart' hide OverlayState;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/languages.dart';
import '../../core/services/native_overlay_service.dart';
import '../../core/theme/app_colors.dart';
import '../providers/settings_provider.dart';
import '../providers/overlay_provider.dart';

class HyperFloatBar extends ConsumerStatefulWidget {
  final VoidCallback onToggleLens;
  final VoidCallback onToggleRegionSelect;
  final VoidCallback onToggleSubtitleBubble;
  final VoidCallback onClose;
  final bool isLensActive;
  final bool isSelectingRegion;
  final bool isSubtitleBubbleVisible;

  const HyperFloatBar({
    super.key,
    required this.onToggleLens,
    required this.onToggleRegionSelect,
    required this.onToggleSubtitleBubble,
    required this.onClose,
    this.isLensActive = false,
    this.isSelectingRegion = false,
    this.isSubtitleBubbleVisible = true,
  });

  @override
  ConsumerState<HyperFloatBar> createState() => _HyperFloatBarState();
}

class _HyperFloatBarState extends ConsumerState<HyperFloatBar>
    with TickerProviderStateMixin {
  // Floating position
  Offset _position = const Offset(0, 150);
  bool _isCollapsed = true;
  bool _isAutoDimmed = false;
  bool _isDragging = false;
  bool _isLeftEdge = true;

  Timer? _autoDimTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _resetAutoDimTimer();
  }

  @override
  void dispose() {
    _autoDimTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _resetAutoDimTimer() {
    _autoDimTimer?.cancel();
    if (_isAutoDimmed) {
      setState(() {
        _isAutoDimmed = false;
      });
    }
    if (_isCollapsed) {
      _autoDimTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted && _isCollapsed && !_isDragging) {
          setState(() {
            _isAutoDimmed = true;
          });
        }
      });
    }
  }

  void _snapToNearestEdge(Size screenSize) {
    final centerX = _position.dx;
    final isLeft = centerX < (screenSize.width / 2);
    final targetX = isLeft ? 0.0 : (screenSize.width - (_isCollapsed ? 34.0 : 380.0));
    final clampedY = _position.dy.clamp(60.0, screenSize.height - 120.0);

    setState(() {
      _isLeftEdge = isLeft;
      _position = Offset(targetX.clamp(0.0, screenSize.width - 34.0), clampedY);
      _isDragging = false;
    });

    _resetAutoDimTimer();
  }

  void _toggleExpand() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isCollapsed = !_isCollapsed;
      _isAutoDimmed = false;
    });
    _resetAutoDimTimer();
  }

  void _showQuickLanguagePicker(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.translate, color: AppColors.cyanPrimary, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'ĐỔI NHANH CẶP NGÔN NGỮ',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Ngôn ngữ nguồn (OCR dịch từ):',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppLanguages.supportedSources.entries.map((e) {
                  final isSelected = settings.sourceLanguage == e.key;
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: isSelected,
                    selectedColor: AppColors.cyanPrimary.withValues(alpha: 0.25),
                    backgroundColor: AppColors.surfaceCore,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.cyanPrimary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.cyanPrimary : AppColors.borderLight,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(settingsProvider.notifier).setSourceLanguage(e.key);
                        Navigator.pop(ctx);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ngôn ngữ đích (Dịch sang):',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppLanguages.supportedTargets.entries.map((e) {
                  final isSelected = settings.targetLanguage == e.key;
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: isSelected,
                    selectedColor: AppColors.cyanPrimary.withValues(alpha: 0.25),
                    backgroundColor: AppColors.surfaceCore,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.cyanPrimary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.cyanPrimary : AppColors.borderLight,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(settingsProvider.notifier).setTargetLanguage(e.key);
                        Navigator.pop(ctx);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final settings = ref.watch(settingsProvider);
    final overlay = ref.watch(overlayProvider);

    final double currentOpacity = _isAutoDimmed ? 0.35 : 1.0;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) {
          _isDragging = true;
          _resetAutoDimTimer();
        },
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        onPanEnd: (_) {
          _snapToNearestEdge(screenSize);
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: currentOpacity,
          child: _isCollapsed
              ? _buildCollapsedXiaomiPill(overlay.isScanning)
              : _buildExpandedXiaomiIsland(settings, overlay),
        ),
      ),
    );
  }

  /// 1. Collapsed Xiaomi-style Edge Pill (Nửa viên nhộng hít mép)
  Widget _buildCollapsedXiaomiPill(bool isScanning) {
    return GestureDetector(
      onTap: _toggleExpand,
      child: Container(
        width: 38,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceShell.withValues(alpha: 0.88),
          borderRadius: BorderRadius.horizontal(
            left: _isLeftEdge ? Radius.zero : const Radius.circular(26),
            right: _isLeftEdge ? const Radius.circular(26) : Radius.zero,
          ),
          border: Border.all(
            color: isScanning
                ? AppColors.emeraldLive.withValues(alpha: 0.8)
                : AppColors.borderLight,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isScanning ? AppColors.emeraldLive : Colors.black)
                  .withValues(alpha: isScanning ? 0.35 : 0.6),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.horizontal(
            left: _isLeftEdge ? Radius.zero : const Radius.circular(26),
            right: _isLeftEdge ? const Radius.circular(26) : Radius.zero,
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isScanning
                          ? AppColors.emeraldLive.withValues(alpha: _pulseAnimation.value)
                          : AppColors.cyanPrimary.withValues(alpha: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: (isScanning ? AppColors.emeraldLive : AppColors.cyanPrimary)
                              .withValues(alpha: _pulseAnimation.value * 0.8),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isLeftEdge ? Icons.chevron_right : Icons.chevron_left,
                  color: isScanning ? AppColors.emeraldLive : AppColors.cyanPrimary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 2. Expanded Xiaomi-style Floating Island Toolbar
  Widget _buildExpandedXiaomiIsland(SettingsState settings, OverlayState overlay) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceShell.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: overlay.isScanning
                  ? AppColors.emeraldLive.withValues(alpha: 0.7)
                  : AppColors.borderLight,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag indicator icon
              const Icon(Icons.drag_indicator, color: AppColors.textMuted, size: 16),
              const SizedBox(width: 6),

              // 1. LIVE Scan Toggle (Pill Button with pulsing indicator)
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _resetAutoDimTimer();
                  if (overlay.isScanning) {
                    ref.read(overlayProvider.notifier).stopScanning();
                  } else {
                    ref.read(overlayProvider.notifier).startScanning();
                  }
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: overlay.isScanning
                        ? AppColors.emeraldLive.withValues(alpha: 0.22)
                        : AppColors.surfaceCore,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: overlay.isScanning
                          ? AppColors.emeraldLive
                          : AppColors.borderLight,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (overlay.isScanning)
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) => Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.emeraldLive
                                  .withValues(alpha: _pulseAnimation.value),
                            ),
                          ),
                        )
                      else
                        const Icon(Icons.play_arrow, color: AppColors.textPrimary, size: 14),
                      Text(
                        overlay.isScanning ? 'LIVE' : 'QUÉT',
                        style: TextStyle(
                          color: overlay.isScanning
                              ? AppColors.emeraldLive
                              : AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Instant Single Capture Button (📸)
              _buildIconButton(
                icon: Icons.camera_alt_outlined,
                tooltip: 'Chụp & Dịch 1 lần (Alt+S)',
                color: AppColors.cyanPrimary,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _resetAutoDimTimer();
                  ref.read(overlayProvider.notifier).performScanCycle();
                },
              ),
              const SizedBox(width: 8),

              // 3. Floating Lens / Reticle Toggle (🔲)
              _buildIconButton(
                icon: widget.isLensActive ? Icons.crop_free : Icons.filter_center_focus,
                tooltip: widget.isLensActive ? 'Đóng Khung Dịch' : 'Bật Khung Dịch Nổi',
                color: widget.isLensActive ? AppColors.emeraldLive : AppColors.cyanPrimary,
                isActive: widget.isLensActive,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _resetAutoDimTimer();
                  widget.onToggleLens();
                },
              ),
              const SizedBox(width: 8),

              // 4. Quick Language Switcher Button (🌐)
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _resetAutoDimTimer();
                  _showQuickLanguagePicker(context, ref);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCore,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${settings.sourceLanguage.toUpperCase()}→${settings.targetLanguage.toUpperCase()}',
                        style: const TextStyle(
                          color: AppColors.cyanPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, color: AppColors.cyanPrimary, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 5. Floating Subtitle Bubble Toggle (💬)
              _buildIconButton(
                icon: widget.isSubtitleBubbleVisible
                    ? Icons.subtitles
                    : Icons.subtitles_off_outlined,
                tooltip: widget.isSubtitleBubbleVisible
                    ? 'Ẩn Bong Bóng Phụ Đề'
                    : 'Hiện Bong Bóng Phụ Đề',
                color: widget.isSubtitleBubbleVisible
                    ? AppColors.cyanPrimary
                    : AppColors.textMuted,
                isActive: widget.isSubtitleBubbleVisible,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _resetAutoDimTimer();
                  widget.onToggleSubtitleBubble();
                },
              ),
              const SizedBox(width: 8),

              // 6. Click-through toggle (👁️)
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _resetAutoDimTimer();
                  final next = !settings.isClickThrough;
                  ref.read(settingsProvider.notifier).setClickThrough(next);
                  NativeOverlayService.setClickThrough(next);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: settings.isClickThrough
                        ? AppColors.cyanPrimary.withValues(alpha: 0.18)
                        : AppColors.amberStar.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: settings.isClickThrough
                          ? AppColors.cyanPrimary
                          : AppColors.amberStar,
                    ),
                  ),
                  child: Text(
                    settings.isClickThrough ? 'Xuyên' : 'Chạm',
                    style: TextStyle(
                      color: settings.isClickThrough
                          ? AppColors.cyanPrimary
                          : AppColors.amberStar,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 7. Collapse Button (◀️)
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Thu nhỏ vào mép viền',
                onPressed: _toggleExpand,
              ),
              const SizedBox(width: 6),

              // 8. Close Overlay Button (✕)
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.redRecord, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Đóng LingoFlow Overlay',
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onClose();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : AppColors.surfaceCore,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : AppColors.borderLight,
            width: 1.0,
          ),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
