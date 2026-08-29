import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';

class TtsService {
  static const String _tag = 'TtsService';

  /// Returns a valid URL to stream TTS audio for the given text and language
  static String getAudioStreamUrl(String text, {String language = 'ja'}) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return '';

    final encoded = Uri.encodeComponent(cleanText);
    var langCode = language.toLowerCase();
    if (langCode == 'auto') langCode = 'ja';

    return 'https://translate.google.com/translate_tts?ie=UTF-8&tl=$langCode&client=tw-ob&q=$encoded';
  }

  /// Synthesizes and speaks text out loud via the system speech engine
  static Future<bool> speak(String text, {String language = 'ja'}) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return false;

    if (kIsWeb) {
      AppLogger.info('TTS audio URL generated for web: $cleanText', tag: _tag);
      return true;
    }

    try {
      if (Platform.isWindows) {
        // Native Windows SAPI Speech Synthesis via PowerShell background task
        final safeText = cleanText.replaceAll('"', '`"').replaceAll("'", "`'");
        Process.run('powershell', [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          'Add-Type -AssemblyName System.Speech; \$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer; \$synth.Speak("$safeText");',
        ]).then((result) {
          if (result.exitCode == 0) {
            AppLogger.debug('Windows SAPI speech playback completed', tag: _tag);
          } else {
            AppLogger.warning('Windows SAPI speech non-zero exit: ${result.stderr}', tag: _tag);
          }
        }).catchError((e, stack) {
          AppLogger.warning('Windows TTS execution error', tag: _tag, error: e, stackTrace: stack);
        });
        return true;
      }
    } catch (e, stack) {
      AppLogger.warning('System TTS playback error', tag: _tag, error: e, stackTrace: stack);
    }
    return false;
  }
}
