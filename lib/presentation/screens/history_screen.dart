import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_provider.dart';
import '../../domain/entities/history_item.dart';
import '../../core/services/export_service.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label vào clipboard!'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Xoá toàn bộ lịch sử?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Hành động này sẽ xoá tất cả các câu đã lưu trong lịch sử dịch. Các từ vựng đã đánh dấu sao cũng sẽ bị xoá.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('HỦY', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(historyProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('XOÁ HẾT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, List<HistoryItem> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'XUẤT DỮ LIỆU TỪ VỰNG / LỊCH SỬ',
              style: TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...ExportFormat.values.map(
              (fmt) => ListTile(
                leading: const Icon(Icons.file_download_outlined, color: Colors.cyanAccent),
                title: Text(fmt.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
                trailing: const Icon(Icons.copy, color: Colors.white60, size: 18),
                onTap: () {
                  final content = ExportService.exportItems(items, fmt);
                  Clipboard.setData(ClipboardData(text: content));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã sao chép ${items.length} từ theo định dạng ${fmt.label} vào Clipboard!'),
                      duration: const Duration(seconds: 3),
                      backgroundColor: const Color(0xFF0F172A),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);
    final notifier = ref.read(historyProvider.notifier);
    final items = historyState.filteredItems;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          title: const Text('Lịch sử & Sổ từ vựng', style: TextStyle(color: Colors.white, fontSize: 18)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (historyState.items.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.download, color: Colors.cyanAccent),
                tooltip: 'Xuất dữ liệu (Anki / CSV / TXT)',
                onPressed: () => _showExportDialog(context, items),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Xoá tất cả',
                onPressed: () => _showClearConfirmDialog(context, ref),
              ),
            ],
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            indicatorColor: Colors.cyanAccent,
            labelColor: Colors.cyanAccent,
            unselectedLabelColor: Colors.white60,
            onTap: (index) {
              notifier.setFilterFavorites(index == 1);
            },
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, size: 18),
                    const SizedBox(width: 8),
                    Text('Tất cả (${historyState.items.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, size: 18, color: Colors.amberAccent),
                    const SizedBox(width: 8),
                    Text('Từ vựng (${historyState.items.where((e) => e.isFavorite).length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search Box
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo từ gốc hoặc bản dịch...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent, size: 20),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => notifier.setSearchQuery(val),
              ),
            ),

            // List of records
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            historyState.filterFavoritesOnly ? Icons.star_border : Icons.history_edu,
                            size: 64,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            historyState.filterFavoritesOnly
                                ? 'Chưa có từ vựng nào được đánh dấu sao ⭐'
                                : 'Chưa có lịch sử dịch thuật nào.',
                            style: const TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildHistoryCard(context, ref, item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, WidgetRef ref, HistoryItem item) {
    final formattedTime =
        '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')} • ${item.timestamp.day}/${item.timestamp.month}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isFavorite
              ? Colors.amberAccent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Language badge & timestamp & Star action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${item.sourceLanguage.toUpperCase()} → ${item.targetLanguage.toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    formattedTime,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      item.isFavorite ? Icons.star : Icons.star_border,
                      color: item.isFavorite ? Colors.amberAccent : Colors.white38,
                      size: 20,
                    ),
                    tooltip: item.isFavorite ? 'Bỏ lưu từ vựng' : 'Lưu vào sổ từ vựng',
                    onPressed: () {
                      ref.read(historyProvider.notifier).toggleFavorite(item.id);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                    tooltip: 'Xoá mục này',
                    onPressed: () {
                      ref.read(historyProvider.notifier).deleteRecord(item.id);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Original Text
          Text(
            item.originalText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),

          // Translated Text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.translatedText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.cyanAccent, size: 16),
                  tooltip: 'Sao chép bản dịch',
                  onPressed: () => _copyToClipboard(context, item.translatedText, 'bản dịch'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
