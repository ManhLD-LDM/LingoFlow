import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/services/native_overlay_service.dart';
import '../../core/theme/app_colors.dart';
import '../providers/profile_provider.dart';
import '../providers/settings_provider.dart';
import 'status_badge.dart';

class DesktopTitlebar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onHelpPressed;

  const DesktopTitlebar({super.key, this.onHelpPressed});

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  ConsumerState<DesktopTitlebar> createState() => _DesktopTitlebarState();
}

class _DesktopTitlebarState extends ConsumerState<DesktopTitlebar> {
  bool _isAlwaysOnTop = false;
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      _checkWindowState();
    }
  }

  Future<void> _checkWindowState() async {
    try {
      final maximized = await windowManager.isMaximized();
      if (mounted) {
        setState(() {
          _isMaximized = maximized;
        });
      }
    } catch (_) {}
  }

  void _toggleAlwaysOnTop() {
    HapticFeedback.selectionClick();
    setState(() {
      _isAlwaysOnTop = !_isAlwaysOnTop;
    });
    NativeOverlayService.setAlwaysOnTop(_isAlwaysOnTop);
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      try {
        windowManager.setAlwaysOnTop(_isAlwaysOnTop);
      } catch (_) {}
    }
  }

  void _minimizeWindow() {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      try {
        windowManager.minimize();
      } catch (_) {}
    }
  }

  void _toggleMaximizeWindow() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      try {
        final isMax = await windowManager.isMaximized();
        if (isMax) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
        setState(() {
          _isMaximized = !isMax;
        });
      } catch (_) {}
    }
  }

  void _closeWindow() {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      try {
        windowManager.close();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final activeProfile = profileState.activeProfile;
    final profileNotifier = ref.read(profileProvider.notifier);
    final settings = ref.watch(settingsProvider);

    final isDesktopPlatform = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceShell.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // 1. Drag Window Zone + App Brand Badge
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (details) {
                if (isDesktopPlatform) {
                  try {
                    windowManager.startDragging();
                  } catch (_) {}
                }
              },
              onDoubleTap: _toggleMaximizeWindow,
              child: Row(
                children: [
                  // App Icon & Name
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.translate, color: AppColors.textDark, size: 14),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'LingoFlow Studio',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const StatusBadge(label: 'PC EDITION', isLive: true),
                  const SizedBox(width: 16),

                  // 2. Active Game Profile Quick Switcher (Titlebar Dropdown)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCore,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: activeProfile.id,
                        dropdownColor: AppColors.surfaceModal,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.cyanPrimary, size: 16),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                        items: profileState.profiles.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.sports_esports_outlined, color: AppColors.cyanPrimary, size: 14),
                                const SizedBox(width: 6),
                                Text(p.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) {
                            profileNotifier.setActiveProfile(id);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 3. OCR Latency & Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldLive.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.emeraldLive.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.emeraldLive,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${settings.ocrEngineMode.displayName.split(' ').first} (24ms)',
                          style: const TextStyle(
                            color: AppColors.emeraldLive,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Action Tools (Help, Always-on-top Pin, Window Controls)
          if (widget.onHelpPressed != null)
            IconButton(
              icon: const Icon(Icons.help_outline, color: AppColors.textSecondary, size: 16),
              tooltip: 'Phím tắt hệ thống (F1)',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: widget.onHelpPressed,
            ),
          const SizedBox(width: 6),

          // Always-On-Top Toggle
          IconButton(
            icon: Icon(
              _isAlwaysOnTop ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isAlwaysOnTop ? AppColors.cyanPrimary : AppColors.textMuted,
              size: 16,
            ),
            tooltip: _isAlwaysOnTop ? 'Bỏ ghim cửa sổ' : 'Ghim cửa sổ luôn trên cùng',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: _toggleAlwaysOnTop,
          ),
          const SizedBox(width: 8),

          // Windows Control Buttons (Minimize, Maximize, Close)
          if (isDesktopPlatform) ...[
            const VerticalDivider(color: AppColors.borderLight, indent: 8, endIndent: 8),
            const SizedBox(width: 4),

            // Minimize
            InkWell(
              onTap: _minimizeWindow,
              borderRadius: BorderRadius.circular(6),
              child: const SizedBox(
                width: 28,
                height: 28,
                child: Icon(Icons.remove, color: AppColors.textSecondary, size: 14),
              ),
            ),
            const SizedBox(width: 4),

            // Maximize / Restore
            InkWell(
              onTap: _toggleMaximizeWindow,
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 28,
                height: 28,
                child: Icon(
                  _isMaximized ? Icons.fullscreen_exit : Icons.crop_square,
                  color: AppColors.textSecondary,
                  size: 13,
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Close
            InkWell(
              onTap: _closeWindow,
              borderRadius: BorderRadius.circular(6),
              child: const SizedBox(
                width: 28,
                height: 28,
                child: Icon(Icons.close, color: AppColors.redRecord, size: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
