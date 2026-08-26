import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/entities/history_item.dart';

class HistoryLocalDatasource {
  static const String _historyKey = 'lingoflow_translation_history';

  Future<List<HistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_historyKey) ?? [];

    final items = <HistoryItem>[];
    for (var str in rawList) {
      try {
        final map = jsonDecode(str) as Map<String, dynamic>;
        items.add(HistoryItem.fromJson(map));
      } catch (_) {}
    }
    // Sort newest first
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<void> saveHistory(HistoryItem item) async {
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
  }

  Future<void> toggleFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getHistory();

    final index = items.indexWhere((element) => element.id == id);
    if (index != -1) {
      final old = items[index];
      items[index] = old.copyWith(isFavorite: !old.isFavorite);
      final strList = items.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_historyKey, strList);
    }
  }

  Future<void> deleteHistory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getHistory();

    items.removeWhere((element) => element.id == id);
    final strList = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_historyKey, strList);
  }

  Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
