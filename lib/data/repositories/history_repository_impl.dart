import '../../domain/entities/history_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/local/history_local_datasource.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryLocalDatasource _datasource;

  HistoryRepositoryImpl({HistoryLocalDatasource? datasource})
      : _datasource = datasource ?? HistoryLocalDatasource();

  @override
  Future<List<HistoryItem>> getAllHistory() {
    return _datasource.getHistory();
  }

  @override
  Future<void> saveHistory(HistoryItem item) {
    return _datasource.saveHistory(item);
  }

  @override
  Future<void> toggleFavorite(String id) {
    return _datasource.toggleFavorite(id);
  }

  @override
  Future<void> deleteHistory(String id) {
    return _datasource.deleteHistory(id);
  }

  @override
  Future<void> clearAllHistory() {
    return _datasource.clearAllHistory();
  }
}
