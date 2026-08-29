import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import '../utils/app_logger.dart';

typedef HotkeyCallback = void Function();

class HotkeyService {
  static const String _tag = 'HotkeyService';

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
        keyDownHandler: (hotKey) {
          AppLogger.debug('Hotkey triggered: Alt + X', tag: _tag);
          onToggleClickThrough();
        },
      );

      await hotKeyManager.register(
        singleCaptureHotKey,
        keyDownHandler: (hotKey) {
          AppLogger.debug('Hotkey triggered: Alt + S', tag: _tag);
          onSingleCapture();
        },
      );

      await hotKeyManager.register(
        toggleScanHotKey,
        keyDownHandler: (hotKey) {
          AppLogger.debug('Hotkey triggered: Alt + Q', tag: _tag);
          onToggleScan();
        },
      );

      AppLogger.info('Global hotkeys registered successfully', tag: _tag);
    } catch (e, stack) {
      AppLogger.warning('Failed to register global hotkeys (may lack platform permissions)', tag: _tag, error: e, stackTrace: stack);
    }
  }

  static Future<void> dispose() async {
    if (kIsWeb) return;
    try {
      await hotKeyManager.unregisterAll();
      AppLogger.info('Global hotkeys unregistered', tag: _tag);
    } catch (e, stack) {
      AppLogger.warning('Failed to unregister hotkeys', tag: _tag, error: e, stackTrace: stack);
    }
  }
}
