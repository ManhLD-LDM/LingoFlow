import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/game_profile.dart';
import '../../core/utils/app_logger.dart';

class ProfileState {
  final List<GameProfile> profiles;
  final String activeProfileId;

  const ProfileState({
    required this.profiles,
    required this.activeProfileId,
  });

  GameProfile get activeProfile => profiles.firstWhere(
        (p) => p.id == activeProfileId,
        orElse: () => profiles.isNotEmpty ? profiles.first : GameProfile.defaultProfile,
      );

  ProfileState copyWith({
    List<GameProfile>? profiles,
    String? activeProfileId,
  }) {
    return ProfileState(
      profiles: profiles ?? this.profiles,
      activeProfileId: activeProfileId ?? this.activeProfileId,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  static const String _tag = 'ProfileNotifier';
  static const String _keyProfiles = 'lingoflow_profiles_v1';
  static const String _keyActiveId = 'lingoflow_active_profile_id_v1';

  @override
  ProfileState build() {
    _loadFromStorage();
    return const ProfileState(
      profiles: [GameProfile.defaultProfile],
      activeProfileId: 'default',
    );
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_keyProfiles);
      final activeId = prefs.getString(_keyActiveId) ?? 'default';

      if (rawJson != null && rawJson.isNotEmpty) {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        final loaded = decoded.map((e) => GameProfile.fromJson(e as Map<String, dynamic>)).toList();
        if (loaded.isNotEmpty) {
          state = ProfileState(
            profiles: loaded,
            activeProfileId: activeId,
          );
          AppLogger.debug('Loaded ${loaded.length} game profiles from storage', tag: _tag);
          return;
        }
      }
    } catch (e, stack) {
      AppLogger.warning('Failed to load profiles from SharedPreferences', tag: _tag, error: e, stackTrace: stack);
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = jsonEncode(state.profiles.map((p) => p.toJson()).toList());
      await prefs.setString(_keyProfiles, rawJson);
      await prefs.setString(_keyActiveId, state.activeProfileId);
    } catch (e, stack) {
      AppLogger.warning('Failed to save profiles to storage', tag: _tag, error: e, stackTrace: stack);
    }
  }

  void setActiveProfile(String id) {
    if (state.profiles.any((p) => p.id == id)) {
      state = state.copyWith(activeProfileId: id);
      _saveToStorage();
    }
  }

  void createProfile(String name, {String sourceLang = 'ja', String targetLang = 'vi'}) {
    final newId = 'profile_${DateTime.now().millisecondsSinceEpoch}';
    final newProfile = GameProfile(
      id: newId,
      name: name.trim().isEmpty ? 'Game Mới' : name.trim(),
      sourceLanguage: sourceLang,
      targetLanguage: targetLang,
    );

    final updated = [...state.profiles, newProfile];
    state = ProfileState(profiles: updated, activeProfileId: newId);
    _saveToStorage();
  }

  void updateProfile(GameProfile updated) {
    final updatedList = state.profiles.map((p) => p.id == updated.id ? updated : p).toList();
    state = state.copyWith(profiles: updatedList);
    _saveToStorage();
  }

  void deleteProfile(String id) {
    if (id == 'default' || state.profiles.length <= 1) return; // Prevent deleting last/default profile
    final updatedList = state.profiles.where((p) => p.id != id).toList();
    final nextActiveId = state.activeProfileId == id ? updatedList.first.id : state.activeProfileId;
    state = ProfileState(profiles: updatedList, activeProfileId: nextActiveId);
    _saveToStorage();
  }

  void addGlossaryTerm(String sourceTerm, String targetTerm) {
    final current = state.activeProfile;
    final updatedGlossary = Map<String, String>.from(current.glossary);
    updatedGlossary[sourceTerm.trim()] = targetTerm.trim();

    final updatedProfile = current.copyWith(glossary: updatedGlossary);
    updateProfile(updatedProfile);
  }

  void removeGlossaryTerm(String sourceTerm) {
    final current = state.activeProfile;
    final updatedGlossary = Map<String, String>.from(current.glossary);
    updatedGlossary.remove(sourceTerm);

    final updatedProfile = current.copyWith(glossary: updatedGlossary);
    updateProfile(updatedProfile);
  }

  String exportGlossaryToJson() {
    return jsonEncode(state.activeProfile.glossary);
  }

  bool importGlossaryFromJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final imported = decoded.map((k, v) => MapEntry(k, v.toString()));
      final current = state.activeProfile;
      final mergedGlossary = Map<String, String>.from(current.glossary)..addAll(imported);

      updateProfile(current.copyWith(glossary: mergedGlossary));
      return true;
    } catch (e) {
      AppLogger.warning('Failed to import glossary JSON: $e', tag: _tag);
      return false;
    }
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(() {
  return ProfileNotifier();
});
