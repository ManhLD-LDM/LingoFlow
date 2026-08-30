import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/export_service.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/history_item.dart';
import '../providers/history_provider.dart';
import '../widgets/status_badge.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;

  const HistoryScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.cyanPrimary, size: 18),
            const SizedBox(width: 8),
            Text('Đã sao chép $label vào clipboard!'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.surfaceModal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _speakText(String text, String lang) {
    HapticFeedback.lightImpact();
    TtsService.speak(text, language: lang);
  }

  void _showClearConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceModal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_outlined, color: AppColors.redRecord),
            SizedBox(width: 10),
            Text('Xoá toàn bộ lịch sử?', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Hành động này sẽ xoá tất cả các câu đã lưu trong lịch sử dịch. Bạn có chắc chắn muốn thực hiện?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('HỦY', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redRecord,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              ref.read(historyProvider.notifier).clearAll();
              Navigator.pop(ctx);
            },
            child: const Text('XOÁ HẾT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, List<HistoryItem> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.ios_share, color: AppColors.cyanPrimary, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'XUẤT SỔ TỪ VỰNG / ANKI FLASHCARD',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...ExportFormat.values.map(
                (fmt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cyanPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.file_download_outlined, color: AppColors.cyanPrimary, size: 18),
                  ),
                  title: Text(fmt.label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.copy, color: AppColors.textMuted, size: 18),
                  onTap: () {
                    final content = ExportService.exportItems(items, fmt);
                    Clipboard.setData(ClipboardData(text: content));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã sao chép ${items.length} từ theo định dạng ${fmt.label} vào Clipboard!'),
                        duration: const Duration(seconds: 3),
                        backgroundColor: AppColors.surfaceModal,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);
    final notifier = ref.read(historyProvider.notifier);
    final items = historyState.filteredItems;

    final starredItems = items.where((it) => it.isFavorite).toList();

    Widget body = Column(
      children: [
        // 1. Search Bar & Filter Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm từ hoặc bản dịch...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              notifier.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceCore,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                  onChanged: (val) {
                    notifier.setSearchQuery(val);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Export Button
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceCore,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                ),
                icon: const Icon(Icons.download_rounded, color: AppColors.cyanPrimary, size: 20),
                tooltip: 'Xuất Anki / CSV',
                onPressed: () => _showExportDialog(context, items),
              ),

              // Clear All Button
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceCore,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                ),
                icon: const Icon(Icons.delete_outline, color: AppColors.redRecord, size: 20),
                tooltip: 'Xóa toàn bộ',
                onPressed: () => _showClearConfirmDialog(context, ref),
              ),
            ],
          ),
        ),

        // 2. Custom Tabs (Tất Cả vs Đã Gắn Sao ⭐)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceCore,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: AppColors.textDark,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: [
              Tab(text: 'TẤT CẢ LỊCH SỬ (${items.length})'),
              Tab(text: 'SỔ TỪ VỰNG ⭐ (${starredItems.length})'),
            ],
          ),
        ),

        // 3. Tab Views (Bento Grid Items)
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildHistoryList(items, notifier),
              _buildHistoryList(starredItems, notifier),
            ],
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Lịch Sử & Sổ Từ Vựng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: body,
    );
  }

  Widget _buildHistoryList(List<HistoryItem> list, HistoryNotifier notifier) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 54, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'Chưa có dữ liệu dịch nào',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Các câu được dịch sẽ tự động lưu vào đây.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceShell,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isFavorite
                  ? AppColors.amberStar.withValues(alpha: 0.4)
                  : AppColors.borderLight,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Language Badge, Star, Speak, Copy, Delete
              Row(
                children: [
                  StatusBadge(
                    label: '${item.sourceLanguage.toUpperCase()} → ${item.targetLanguage.toUpperCase()}',
                    customColor: AppColors.cyanPrimary,
                  ),
                  const Spacer(),

                  // Star toggle
                  IconButton(
                    icon: Icon(
                      item.isFavorite ? Icons.star : Icons.star_border,
                      color: item.isFavorite ? AppColors.amberStar : AppColors.textMuted,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: item.isFavorite ? 'Bỏ lưu sao' : 'Lưu vào sổ từ vựng',
                    onPressed: () => notifier.toggleFavorite(item.id),
                  ),
                  const SizedBox(width: 12),

                  // Speak audio
                  IconButton(
                    icon: const Icon(Icons.volume_up_outlined, color: AppColors.cyanPrimary, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Nghe phát âm',
                    onPressed: () => _speakText(item.originalText, item.sourceLanguage),
                  ),
                  const SizedBox(width: 12),

                  // Copy
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppColors.textSecondary, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Sao chép bản dịch',
                    onPressed: () => _copyToClipboard(context, item.translatedText, 'bản dịch'),
                  ),
                  const SizedBox(width: 12),

                  // Delete single item
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Xóa câu này',
                    onPressed: () => notifier.deleteRecord(item.id),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Original Text
              SelectableText(
                item.originalText,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),

              // Translated Text
              SelectableText(
                item.translatedText,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
