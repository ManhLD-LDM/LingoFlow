import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/history_item.dart';

class HistoryLocalDatasource {
  static const String _historyKey = 'lingoflow_translation_history';
  static const String _tag = 'HistoryLocalDatasource';

  Future<List<HistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_historyKey) ?? [];

      final items = <HistoryItem>[];
      for (var str in rawList) {
        try {
          final map = jsonDecode(str) as Map<String, dynamic>;
          items.add(HistoryItem.fromJson(map));
        } catch (e) {
          AppLogger.warning('Corrupted history item skipped', tag: _tag, error: e);
        }
      }
      // Sort newest first
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return items;
    } catch (e, stack) {
      AppLogger.error('Failed to load history from SharedPreferences', tag: _tag, error: e, stackTrace: stack);
      return [];
    }
  }

  Future<void> saveHistory(HistoryItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await getHistory();

      // Prevent duplicate consecutive entries with same text
      if (items.isNotEmpty && items.first.originalText == item.originalText) {
        return;
      }

      // Keep max 500 items to keep storage lean
      if (items.length >= 500) {
        items.removeLast();
      }

      items.insert(0, item);
      final strList = items.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_historyKey, strList);
      AppLogger.debug('Saved history record: "${item.originalText}"', tag: _tag);
    } catch (e, stack) {
      AppLogger.error('Failed to save history item', tag: _tag, error: e, stackTrace: stack);
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await getHistory();

      final index = items.indexWhere((element) => element.id == id);
      if (index != -1) {
        final old = items[index];
        items[index] = old.copyWith(isFavorite: !old.isFavorite);
        final strList = items.map((e) => jsonEncode(e.toJson())).toList();
        await prefs.setStringList(_historyKey, strList);
        AppLogger.debug('Toggled favorite for: $id (${!old.isFavorite})', tag: _tag);
      }
    } catch (e, stack) {
      AppLogger.error('Failed to toggle favorite', tag: _tag, error: e, stackTrace: stack);
    }
  }

  Future<void> deleteHistory(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await getHistory();

      items.removeWhere((element) => element.id == id);
      final strList = items.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_historyKey, strList);
      AppLogger.debug('Deleted history record: $id', tag: _tag);
    } catch (e, stack) {
      AppLogger.error('Failed to delete history record: $id', tag: _tag, error: e, stackTrace: stack);
    }
  }

  Future<void> clearAllHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      AppLogger.info('Cleared all history records', tag: _tag);
    } catch (e, stack) {
      AppLogger.error('Failed to clear history', tag: _tag, error: e, stackTrace: stack);
    }
  }
}
