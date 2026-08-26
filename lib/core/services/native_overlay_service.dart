import 'package:flutter/services.dart';

class NativeOverlayService {
  static const MethodChannel _channel = MethodChannel('com.lingoflow/native');

  /// Toggle click-through mode on Windows (WS_EX_TRANSPARENT)
  static Future<bool> setClickThrough(bool enable) async {
    try {
      final result = await _channel.invokeMethod<bool>('setClickThrough', {'enable': enable});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Make the overlay window stay on top of fullscreen/borderless games
  static Future<bool> setAlwaysOnTop(bool enable) async {
    try {
      final result = await _channel.invokeMethod<bool>('setAlwaysOnTop', {'enable': enable});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Set overall window opacity (alpha)
  static Future<bool> setWindowOpacity(double opacity) async {
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
