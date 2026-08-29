import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/app_logger.dart';

class NativeOverlayService {
  static const MethodChannel _channel = MethodChannel('com.lingoflow/native');
  static const String _tag = 'NativeOverlayService';

  /// Switch the application window into a full-screen borderless transparent overlay
  static Future<bool> enterOverlayMode() async {
    if (kIsWeb) return false;
    try {
      final result = await _channel.invokeMethod<bool>('enterOverlayMode');
      AppLogger.info('Entered overlay mode', tag: _tag);
      return result ?? false;
    } catch (e, stack) {
      AppLogger.error('Failed to enter overlay mode', tag: _tag, error: e, stackTrace: stack);
      return false;
    }
  }

  /// Restore the window back to standard dashboard window size with title bar
  static Future<bool> exitOverlayMode() async {
    if (kIsWeb) return false;
    try {
      final result = await _channel.invokeMethod<bool>('exitOverlayMode');
      AppLogger.info('Exited overlay mode', tag: _tag);
      return result ?? false;
    } catch (e, stack) {
      AppLogger.error('Failed to exit overlay mode', tag: _tag, error: e, stackTrace: stack);
      return false;
    }
  }

  /// Toggle click-through mode on Windows (WS_EX_TRANSPARENT)
  static Future<bool> setClickThrough(bool enable) async {
    if (kIsWeb) return false;
    try {
      final result = await _channel.invokeMethod<bool>('setClickThrough', {'enable': enable});
      AppLogger.debug('Click-through set to: $enable', tag: _tag);
      return result ?? false;
    } catch (e, stack) {
      AppLogger.error('Failed to set click-through: $enable', tag: _tag, error: e, stackTrace: stack);
      return false;
    }
  }

  /// Make the overlay window stay on top of fullscreen/borderless games
  static Future<bool> setAlwaysOnTop(bool enable) async {
    if (kIsWeb) return false;
    try {
      final result = await _channel.invokeMethod<bool>('setAlwaysOnTop', {'enable': enable});
      AppLogger.debug('Always on top set to: $enable', tag: _tag);
      return result ?? false;
    } catch (e, stack) {
      AppLogger.error('Failed to set always on top: $enable', tag: _tag, error: e, stackTrace: stack);
      return false;
    }
  }

  /// Set overall window opacity (alpha)
  static Future<bool> setWindowOpacity(double opacity) async {
    if (kIsWeb) return false;
    try {
      final clamped = opacity.clamp(0.1, 1.0);
      final result = await _channel.invokeMethod<bool>('setWindowOpacity', {'opacity': clamped});
      AppLogger.debug('Window opacity set to: $clamped', tag: _tag);
      return result ?? false;
    } catch (e, stack) {
      AppLogger.error('Failed to set window opacity', tag: _tag, error: e, stackTrace: stack);
      return false;
    }
  }

  /// Capture screen region directly via Win32 GDI BitBlt.
  /// Automatically scales logical Flutter coordinates to physical screen pixels using devicePixelRatio.
  static Future<Map<String, dynamic>?> captureScreen({
    int x = 0,
    int y = 0,
    int width = 0,
    int height = 0,
    double? devicePixelRatio,
  }) async {
    if (kIsWeb) return null;
    try {
      // Calculate DPI scale factor
      final pixelRatio = devicePixelRatio ?? _getDevicePixelRatio();
      final physX = (x * pixelRatio).round();
      final physY = (y * pixelRatio).round();
      final physWidth = (width * pixelRatio).round();
      final physHeight = (height * pixelRatio).round();

      final result = await _channel.invokeMapMethod<String, dynamic>('captureScreen', {
        'x': physX,
        'y': physY,
        'width': physWidth,
        'height': physHeight,
      });

      return result;
    } catch (e, stack) {
      AppLogger.error('Screen capture failed at ($x, $y, $width, $height)', tag: _tag, error: e, stackTrace: stack);
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
    double? devicePixelRatio,
  }) async {
    if (kIsWeb) return null;
    try {
      final pixelRatio = devicePixelRatio ?? _getDevicePixelRatio();
      final physX = (x * pixelRatio).round();
      final physY = (y * pixelRatio).round();
      final physWidth = (width * pixelRatio).round();
      final physHeight = (height * pixelRatio).round();

      final result = await _channel.invokeMapMethod<String, dynamic>('recognizeText', {
        'x': physX,
        'y': physY,
        'width': physWidth,
        'height': physHeight,
        'language': language ?? 'auto',
      });
      return result;
    } catch (e, stack) {
      AppLogger.error('Native text recognition failed', tag: _tag, error: e, stackTrace: stack);
      return null;
    }
  }

  static double _getDevicePixelRatio() {
    try {
      final views = PlatformDispatcher.instance.views;
      if (views.isNotEmpty) {
        return views.first.devicePixelRatio;
      }
    } catch (_) {}
    return 1.0;
  }
}
