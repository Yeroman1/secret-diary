import 'package:hive/hive.dart';
import '../hive/hive_setup.dart';
import '../models/diary_entry.dart';
import '../models/category.dart';
import '../models/tag.dart';
import '../models/app_settings.dart';

class DiaryRepository {
  bool isDecoyActive;

  DiaryRepository({this.isDecoyActive = false});

  Box<DiaryEntry> get _entriesBox => isDecoyActive
      ? Hive.box<DiaryEntry>(HiveSetup.decoyEntriesBoxName)
      : Hive.box<DiaryEntry>(HiveSetup.entriesBoxName);

  Box<Category> get _categoriesBox => Hive.box<Category>(HiveSetup.categoriesBoxName);
  Box<Tag> get _tagsBox => Hive.box<Tag>(HiveSetup.tagsBoxName);
  Box<AppSettings> get _settingsBox => Hive.box<AppSettings>(HiveSetup.settingsBoxName);

  // --- ENTRIES CRUD ---

  List<DiaryEntry> getAllEntries() {
    final list = _entriesBox.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  DiaryEntry? getEntryById(String id) {
    return _entriesBox.get(id);
  }

  Future<void> saveEntry(DiaryEntry entry) async {
    entry.updatedAt = DateTime.now();
    await _entriesBox.put(entry.id, entry);
  }

  Future<void> deleteEntry(String id) async {
    await _entriesBox.delete(id);
  }

  // --- CATEGORIES CRUD ---

  List<Category> getAllCategories() {
    return _categoriesBox.values.toList();
  }

  Category? getCategoryById(String? id) {
    if (id == null) return null;
    return _categoriesBox.get(id);
  }

  Future<void> saveCategory(Category category) async {
    await _categoriesBox.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    await _categoriesBox.delete(id);
  }

  // --- TAGS CRUD ---

  List<Tag> getAllTags() {
    return _tagsBox.values.toList();
  }

  Future<void> saveTag(Tag tag) async {
    await _tagsBox.put(tag.id, tag);
  }

  Future<void> deleteTag(String id) async {
    await _tagsBox.delete(id);
  }

  // --- APP SETTINGS CRUD ---

  AppSettings getSettings() {
    return _settingsBox.get('app_settings') ?? AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put('app_settings', settings);
  }
}
