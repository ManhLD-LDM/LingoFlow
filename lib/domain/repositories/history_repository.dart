import '../entities/history_item.dart';

abstract class HistoryRepository {
  Future<List<HistoryItem>> getAllHistory();
  Future<void> saveHistory(HistoryItem item);
  Future<void> toggleFavorite(String id);
  Future<void> deleteHistory(String id);
  Future<void> clearAllHistory();
}
