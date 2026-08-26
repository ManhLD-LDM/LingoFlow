import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

typedef HotkeyCallback = void Function();

class HotkeyService {
  static final HotKey toggleClickThroughHotKey = HotKey(
    key: PhysicalKeyboardKey.keyX,
    modifiers: [HotKeyModifier.alt],
    scope: HotKeyScope.system,
  );

  static final HotKey singleCaptureHotKey = HotKey(
    key: PhysicalKeyboardKey.keyS,
    modifiers: [HotKeyModifier.alt],
    scope: HotKeyScope.system,
  );

  static final HotKey toggleScanHotKey = HotKey(
    key: PhysicalKeyboardKey.keyQ,
    modifiers: [HotKeyModifier.alt],
    scope: HotKeyScope.system,
  );

  static Future<void> initialize({
    required HotkeyCallback onToggleClickThrough,
    required HotkeyCallback onSingleCapture,
    required HotkeyCallback onToggleScan,
  }) async {
    if (kIsWeb) return;
    try {
      await hotKeyManager.unregisterAll();

      await hotKeyManager.register(
        toggleClickThroughHotKey,
        keyDownHandler: (hotKey) => onToggleClickThrough(),
      );

      await hotKeyManager.register(
        singleCaptureHotKey,
        keyDownHandler: (hotKey) => onSingleCapture(),
      );

      await hotKeyManager.register(
        toggleScanHotKey,
        keyDownHandler: (hotKey) => onToggleScan(),
      );
    } catch (_) {
      // Hotkeys might be unavailable on some platforms or need special permissions
    }
  }

  static Future<void> dispose() async {
    if (kIsWeb) return;
    try {
      await hotKeyManager.unregisterAll();
    } catch (_) {}
  }
}
