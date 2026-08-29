import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

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
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.3)),
        ),
        title: const Text('Tạo Profile Mới', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: _profileNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nhập tên Game / Manga (VD: Fate/Grand Order)...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () {
              final name = _profileNameController.text.trim();
              if (name.isNotEmpty) {
                ref.read(profileProvider.notifier).createProfile(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Tạo Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _addGlossaryTerm() {
    final src = _sourceTermController.text.trim();
    final tgt = _targetTermController.text.trim();
    if (src.isNotEmpty && tgt.isNotEmpty) {
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Hồ Sơ Game & Từ Điển Thuật Ngữ (Glossary)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section 1: Profiles Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'HỒ SƠ GAME ĐANG CHỌN (ACTIVE PROFILE)',
                style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _showAddProfileDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E293B),
                    value: activeProfile.id,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: profileState.profiles.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Row(
                          children: [
                            Icon(
                              p.id == activeProfile.id ? Icons.gamepad : Icons.sports_esports_outlined,
                              color: Colors.cyanAccent,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text(
                              '(${p.glossary.length} thuật ngữ)',
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) notifier.setActiveProfile(val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Custom Glossary Manager
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BỘ TỪ ĐIỂN THUẬT NGỮ CỦA "${activeProfile.name.toUpperCase()}"',
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                '${activeProfile.glossary.length} từ',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Thuật ngữ trong bảng này sẽ tự động thay thế chuẩn xác khi dịch thuật, bảo toàn tên riêng/kỹ năng nhân vật.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Add term input
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sourceTermController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Từ gốc (VD: 宝具 / HP)...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, size: 16, color: Colors.cyanAccent),
                ),
                Expanded(
                  child: TextField(
                    controller: _targetTermController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Nghĩa dịch (VD: Bảo Khí / Máu)...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _addGlossaryTerm,
                  child: const Text('Thêm từ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Glossary Table / List
          if (activeProfile.glossary.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.menu_book, color: Colors.white24, size: 36),
                  SizedBox(height: 8),
                  Text('Chưa có thuật ngữ riêng nào cho profile này.', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  SizedBox(height: 4),
                  Text('Nhập từ gốc và nghĩa dịch ở trên để thêm vào từ điển!', style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeProfile.glossary.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                itemBuilder: (ctx, idx) {
                  final entry = activeProfile.glossary.entries.elementAt(idx);
                  return ListTile(
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                          ),
                          child: Text(entry.key, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.arrow_right_alt, color: Colors.white38, size: 18),
                        ),
                        Expanded(
                          child: Text(entry.value, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      onPressed: () => notifier.removeGlossaryTerm(entry.key),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
