import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Centralized structured logging for LingoFlow
class AppLogger {
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kReleaseMode && level == LogLevel.debug) {
      return; // Suppress verbose debug logs in release mode
    }

    final time = DateTime.now().toIso8601String().substring(11, 19);
    final prefix = _levelPrefix(level);
    final tagPart = tag != null ? '[$tag] ' : '';

    final logOutput = '[$time] $prefix $tagPart$message';
    debugPrint(logOutput);

    if (error != null) {
      debugPrint('   └─ Cause: $error');
    }
    if (stackTrace != null && (level == LogLevel.error || kDebugMode)) {
      debugPrint('   └─ StackTrace: $stackTrace');
    }
  }

  static String _levelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍 [DEBUG]';
      case LogLevel.info:
        return 'ℹ️ [INFO]';
      case LogLevel.warning:
        return '⚠️ [WARN]';
      case LogLevel.error:
        return '❌ [ERROR]';
    }
  }
}
