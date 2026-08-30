import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/profile_provider.dart';

class ProfilesScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;

  const ProfilesScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  final _sourceTermController = TextEditingController();
  final _targetTermController = TextEditingController();
  final _profileNameController = TextEditingController();

  @override
  void dispose() {
    _sourceTermController.dispose();
    _targetTermController.dispose();
    _profileNameController.dispose();
    super.dispose();
  }

  void _showAddProfileDialog() {
    _profileNameController.clear();
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
            Icon(Icons.sports_esports_outlined, color: AppColors.cyanPrimary),
            SizedBox(width: 10),
            Text('Tạo Hồ Sơ Game Mới', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: _profileNameController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'VD: Fate/Grand Order, Genshin, Honkai...',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceCore,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('HỦY', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyanPrimary,
              foregroundColor: AppColors.textDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final name = _profileNameController.text.trim();
              if (name.isNotEmpty) {
                ref.read(profileProvider.notifier).createProfile(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('TẠO PROFILE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addGlossaryTerm() {
    final src = _sourceTermController.text.trim();
    final tgt = _targetTermController.text.trim();
    if (src.isNotEmpty && tgt.isNotEmpty) {
      HapticFeedback.lightImpact();
      ref.read(profileProvider.notifier).addGlossaryTerm(src, tgt);
      _sourceTermController.clear();
      _targetTermController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final activeProfile = profileState.activeProfile;
    final notifier = ref.read(profileProvider.notifier);

    Widget content = ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. Profile Switcher Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DANH SÁCH HỒ SƠ GAME',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.cyanPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('+ Thêm Profile Game', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: _showAddProfileDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Horizontal Profile Cards Carousel
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: profileState.profiles.length,
            itemBuilder: (context, index) {
              final p = profileState.profiles[index];
              final isActive = p.id == activeProfile.id;

              return Container(
                width: 170,
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    notifier.setActiveProfile(p.id);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.cyanPrimary.withValues(alpha: 0.15)
                          : AppColors.surfaceShell,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive ? AppColors.cyanPrimary : AppColors.borderLight,
                        width: isActive ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isActive ? AppColors.cyanPrimary : Colors.black)
                              .withValues(alpha: isActive ? 0.2 : 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.sports_esports,
                              color: isActive ? AppColors.cyanPrimary : AppColors.textMuted,
                              size: 18,
                            ),
                            const Spacer(),
                            if (p.id != 'default')
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.redRecord, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Xóa profile này',
                                onPressed: () => notifier.deleteProfile(p.id),
                              ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isActive ? AppColors.cyanPrimary : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.glossary.length} thuật ngữ',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // 2. Active Profile Glossary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceShell,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book, color: AppColors.cyanPrimary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'TỪ ĐIỂN THUẬT NGỮ: ${activeProfile.name.toUpperCase()}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Các từ ngữ này sẽ được ưu tiên dịch chính xác theo nghĩa riêng của game thay vì dịch máy thông thường.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),

              // Inputs for new Glossary Term
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sourceTermController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'Từ gốc (VD: マスター)',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: AppColors.cyanPrimary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _targetTermController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'Dịch sang (VD: Master)',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.cyanPrimary,
                      foregroundColor: AppColors.textDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: 'Thêm thuật ngữ',
                    onPressed: _addGlossaryTerm,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.borderLight, height: 1),
              const SizedBox(height: 14),

              // Glossary Terms List
              if (activeProfile.glossary.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Chưa có thuật ngữ nào. Hãy thêm từ vựng để cá nhân hóa bản dịch game!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: activeProfile.glossary.entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCore,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(
                              color: AppColors.cyanPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, color: AppColors.textMuted, size: 12),
                          const SizedBox(width: 6),
                          Text(
                            e.value,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              notifier.removeGlossaryTerm(e.key);
                            },
                            child: const Icon(Icons.close, color: AppColors.redRecord, size: 14),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Hồ Sơ Game & Thuật Ngữ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: content,
    );
  }
}
