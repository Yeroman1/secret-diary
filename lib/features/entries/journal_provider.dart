import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/hive/hive_setup.dart';
import '../../data/models/diary_entry.dart';
import '../../data/models/app_settings.dart';
import '../../data/repositories/diary_repository.dart';
import '../../core/security/auth_service.dart';

// --- AUTH STATUS PROVIDER ---
enum AuthState { unconfigured, locked, unlocked, decoyUnlocked }

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.locked) {
    _init();
  }

  Box<AppSettings> get _settingsBox => Hive.box<AppSettings>(HiveSetup.settingsBoxName);

  AppSettings _getSettings() {
    return _settingsBox.get('app_settings') ?? AppSettings();
  }

  void _init() {
    final settings = _getSettings();
    if (settings.pinHash == null || settings.pinHash!.isEmpty) {
      state = AuthState.unconfigured;
    } else {
      state = AuthState.locked;
    }
  }

  void lock() {
    state = AuthState.locked;
  }

  void unlockSuccess() {
    state = AuthState.unlocked;
  }

  void unlockDecoy() {
    state = AuthState.decoyUnlocked;
  }

  void setupPin(String pin, {String? decoyPin}) {
    final salt = AuthService.generateSalt();
    final hash = AuthService.hashPin(pin, salt);
    final settings = _getSettings();

    settings.pinSalt = salt;
    settings.pinHash = hash;

    if (decoyPin != null && decoyPin.isNotEmpty) {
      final decoySalt = AuthService.generateSalt();
      final decoyHash = AuthService.hashPin(decoyPin, decoySalt);
      settings.enableDecoyMode = true;
      settings.decoyPinSalt = decoySalt;
      settings.decoyPinHash = decoyHash;
    }

    _settingsBox.put('app_settings', settings);
    state = AuthState.unlocked;
  }

  bool changePin({required String currentPin, required String newPin}) {
    final settings = _getSettings();
    if (settings.pinHash == null || settings.pinSalt == null) return false;

    final computedCurrent = AuthService.hashPin(currentPin, settings.pinSalt!);
    if (computedCurrent != settings.pinHash) {
      return false; // Old password is incorrect
    }

    final newSalt = AuthService.generateSalt();
    final newHash = AuthService.hashPin(newPin, newSalt);

    settings.pinSalt = newSalt;
    settings.pinHash = newHash;

    _settingsBox.put('app_settings', settings);
    return true;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// --- DIARY REPOSITORY PROVIDER ---
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  final authState = ref.watch(authProvider);
  final isDecoy = authState == AuthState.decoyUnlocked;
  return DiaryRepository(isDecoyActive: isDecoy);
});

// --- SETTINGS PROVIDER ---
class SettingsNotifier extends StateNotifier<AppSettings> {
  final DiaryRepository repository;

  SettingsNotifier(this.repository) : super(repository.getSettings());

  void updateSettings(AppSettings newSettings) {
    repository.saveSettings(newSettings);
    state = newSettings;
  }

  void setThemeMode(String themeName) {
    final updated = state.copyWith(themeModeName: themeName);
    updateSettings(updated);
  }

  void setBiometricEnabled(bool enabled) {
    final updated = state.copyWith(isBiometricEnabled: enabled);
    updateSettings(updated);
  }

  void setAutoLockTimeout(int seconds) {
    final updated = state.copyWith(autoLockTimeoutSeconds: seconds);
    updateSettings(updated);
  }

  void setPanicShakeEnabled(bool enabled) {
    final updated = state.copyWith(panicShakeEnabled: enabled);
    updateSettings(updated);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final repo = ref.watch(diaryRepositoryProvider);
  return SettingsNotifier(repo);
});

// --- JOURNAL ENTRIES FILTER STATE ---
class JournalFilterState {
  final String searchQuery;
  final String? categoryId;
  final String? tagId;
  final String? mood;
  final bool favoritesOnly;

  JournalFilterState({
    this.searchQuery = '',
    this.categoryId,
    this.tagId,
    this.mood,
    this.favoritesOnly = false,
  });

  JournalFilterState copyWith({
    String? searchQuery,
    String? categoryId,
    String? tagId,
    String? mood,
    bool? favoritesOnly,
    bool clearCategory = false,
    bool clearTag = false,
    bool clearMood = false,
  }) {
    return JournalFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      tagId: clearTag ? null : (tagId ?? this.tagId),
      mood: clearMood ? null : (mood ?? this.mood),
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }
}

class JournalEntriesNotifier extends StateNotifier<List<DiaryEntry>> {
  final DiaryRepository repository;

  JournalEntriesNotifier(this.repository) : super([]) {
    loadEntries();
  }

  void loadEntries() {
    state = repository.getAllEntries();
  }

  Future<void> addOrUpdateEntry(DiaryEntry entry) async {
    await repository.saveEntry(entry);
    loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    await repository.deleteEntry(id);
    loadEntries();
  }

  Future<void> toggleFavorite(String id) async {
    final entry = repository.getEntryById(id);
    if (entry != null) {
      entry.isFavorite = !entry.isFavorite;
      await repository.saveEntry(entry);
      loadEntries();
    }
  }

  Future<void> toggleLock(String id) async {
    final entry = repository.getEntryById(id);
    if (entry != null) {
      entry.isLocked = !entry.isLocked;
      await repository.saveEntry(entry);
      loadEntries();
    }
  }

  Future<void> bulkDeleteEntries(List<String> ids) async {
    for (final id in ids) {
      await repository.deleteEntry(id);
    }
    loadEntries();
  }

  Future<void> bulkToggleFavorite(List<String> ids) async {
    for (final id in ids) {
      final entry = repository.getEntryById(id);
      if (entry != null) {
        entry.isFavorite = !entry.isFavorite;
        await repository.saveEntry(entry);
      }
    }
    loadEntries();
  }

  Future<void> bulkToggleLock(List<String> ids) async {
    for (final id in ids) {
      final entry = repository.getEntryById(id);
      if (entry != null) {
        entry.isLocked = !entry.isLocked;
        await repository.saveEntry(entry);
      }
    }
    loadEntries();
  }
}

final journalEntriesProvider = StateNotifierProvider<JournalEntriesNotifier, List<DiaryEntry>>((ref) {
  final repo = ref.watch(diaryRepositoryProvider);
  return JournalEntriesNotifier(repo);
});

final journalFilterProvider = StateProvider<JournalFilterState>((ref) => JournalFilterState());

// Filtered entries provider
final filteredEntriesProvider = Provider<List<DiaryEntry>>((ref) {
  final allEntries = ref.watch(journalEntriesProvider);
  final filter = ref.watch(journalFilterProvider);

  return allEntries.where((entry) {
    if (filter.favoritesOnly && !entry.isFavorite) return false;
    if (filter.categoryId != null && entry.categoryId != filter.categoryId) return false;
    if (filter.tagId != null && !entry.tagIds.contains(filter.tagId)) return false;
    if (filter.mood != null && entry.mood != filter.mood) return false;

    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      final inTitle = entry.title.toLowerCase().contains(q);
      final inContent = entry.contentMarkdown.toLowerCase().contains(q);
      final inTags = entry.tagIds.any((t) => t.toLowerCase().contains(q));
      if (!inTitle && !inContent && !inTags) return false;
    }

    return true;
  }).toList();
});
