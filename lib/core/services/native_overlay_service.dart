import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeOverlayService {
  static const MethodChannel _channel = MethodChannel('com.lingoflow/native');

  /// Switch the application window into a full-screen borderless transparent overlay
  static Future<bool> enterOverlayMode() async {
    if (kIsWeb) return false;
    try {
      final result = await _channel.invokeMethod<bool>('enterOverlayMode');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Restore the window back to standard dashboard window size with title bar
  static Future<bool> exitOverlayMode() async {
    if (kIsWeb) return false;
    try {
      final result = await _channel.invokeMethod<bool>('exitOverlayMode');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Toggle click-through mode on Windows (WS_EX_TRANSPARENT)
  static Future<bool> setClickThrough(bool enable) async {
    if (kIsWeb) return false;
    try {
      final result = await _channel.invokeMethod<bool>('setClickThrough', {'enable': enable});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Make the overlay window stay on top of fullscreen/borderless games
  static Future<bool> setAlwaysOnTop(bool enable) async {
    if (kIsWeb) return false;
    try {
      final result = await _channel.invokeMethod<bool>('setAlwaysOnTop', {'enable': enable});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Set overall window opacity (alpha)
  static Future<bool> setWindowOpacity(double opacity) async {
    if (kIsWeb) return false;
    try {
      final result = await _channel.invokeMethod<bool>('setWindowOpacity', {'opacity': opacity.clamp(0.1, 1.0)});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Capture screen region directly via Win32 GDI BitBlt
  static Future<Map<String, dynamic>?> captureScreen({
    int x = 0,
    int y = 0,
    int width = 0,
    int height = 0,
  }) async {
    if (kIsWeb) return null;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('captureScreen', {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      });
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Call Native OCR
  static Future<Map<String, dynamic>?> recognizeText({
    int x = 0,
    int y = 0,
    int width = 0,
    int height = 0,
    String? language,
  }) async {
    if (kIsWeb) return null;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('recognizeText', {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'language': language ?? 'auto',
      });
      return result;
    } catch (_) {
      return null;
    }
  }
}
