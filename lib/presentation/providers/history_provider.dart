import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/history_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../../data/repositories/history_repository_impl.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl();
});

class HistoryState {
  final List<HistoryItem> items;
  final bool filterFavoritesOnly;
  final String searchQuery;
  final bool isLoading;

  const HistoryState({
    this.items = const [],
    this.filterFavoritesOnly = false,
    this.searchQuery = '',
    this.isLoading = false,
  });

  List<HistoryItem> get filteredItems {
    return items.where((item) {
      if (filterFavoritesOnly && !item.isFavorite) {
        return false;
      }
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchOriginal = item.originalText.toLowerCase().contains(q);
        final matchTranslated = item.translatedText.toLowerCase().contains(q);
        return matchOriginal || matchTranslated;
      }
      return true;
    }).toList();
  }

  HistoryState copyWith({
    List<HistoryItem>? items,
    bool? filterFavoritesOnly,
    String? searchQuery,
    bool? isLoading,
  }) {
    return HistoryState(
      items: items ?? this.items,
      filterFavoritesOnly: filterFavoritesOnly ?? this.filterFavoritesOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() {
    loadHistory();
    return const HistoryState(isLoading: true);
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    final repo = ref.read(historyRepositoryProvider);
    final list = await repo.getAllHistory();
    state = state.copyWith(items: list, isLoading: false);
  }

  Future<void> addRecord({
    required String originalText,
    required String translatedText,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (originalText.trim().isEmpty || translatedText.trim().isEmpty) return;

    final item = HistoryItem(
      id: 'hist_${DateTime.now().millisecondsSinceEpoch}',
      originalText: originalText.trim(),
      translatedText: translatedText.trim(),
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      timestamp: DateTime.now(),
    );

    final repo = ref.read(historyRepositoryProvider);
    await repo.saveHistory(item);
    await loadHistory();
  }

  Future<void> toggleFavorite(String id) async {
    final repo = ref.read(historyRepositoryProvider);
    await repo.toggleFavorite(id);
    await loadHistory();
  }

  Future<void> deleteRecord(String id) async {
    final repo = ref.read(historyRepositoryProvider);
    await repo.deleteHistory(id);
    await loadHistory();
  }

  Future<void> clearAll() async {
    final repo = ref.read(historyRepositoryProvider);
    await repo.clearAllHistory();
    state = state.copyWith(items: []);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilterFavorites(bool onlyFavorites) {
    state = state.copyWith(filterFavoritesOnly: onlyFavorites);
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, HistoryState>(() {
  return HistoryNotifier();
});
