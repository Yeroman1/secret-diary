import 'package:hive_flutter/hive_flutter.dart';
import '../../core/security/encryption_service.dart';
import '../models/diary_entry.dart';
import '../models/category.dart';
import '../models/tag.dart';
import '../models/app_settings.dart';

class HiveSetup {
  static const String entriesBoxName = 'whisper_entries_box';
  static const String decoyEntriesBoxName = 'whisper_decoy_entries_box';
  static const String categoriesBoxName = 'whisper_categories_box';
  static const String tagsBoxName = 'whisper_tags_box';
  static const String settingsBoxName = 'whisper_settings_box';

  static Future<void> initHive() async {
    await Hive.initFlutter();

    // Register TypeAdapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(DiaryEntryAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CategoryAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TagAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AppSettingsAdapter());

    // Get secure AES 256-bit encryption cipher key
    final encryptionService = EncryptionService();
    final keyBytes = await encryptionService.getOrCreateEncryptionKey();
    final cipher = HiveAesCipher(keyBytes);

    // Open Encrypted Boxes
    await Hive.openBox<DiaryEntry>(entriesBoxName, encryptionCipher: cipher);
    await Hive.openBox<DiaryEntry>(decoyEntriesBoxName, encryptionCipher: cipher);
    final categoriesBox = await Hive.openBox<Category>(categoriesBoxName, encryptionCipher: cipher);
    final tagsBox = await Hive.openBox<Tag>(tagsBoxName, encryptionCipher: cipher);
    final settingsBox = await Hive.openBox<AppSettings>(settingsBoxName, encryptionCipher: cipher);

    // Initialize Default Settings if empty
    if (settingsBox.isEmpty) {
      await settingsBox.put('app_settings', AppSettings());
    }

    // Seed default categories if empty
    if (categoriesBox.isEmpty) {
      final defaultCategories = [
        Category(id: 'personal', name: 'Personal', colorHex: '0xFF7A2E2E', iconName: 'heart'),
        Category(id: 'work', name: 'Work & Ideas', colorHex: '0xFF2F4739', iconName: 'briefcase'),
        Category(id: 'dreams', name: 'Dreams & Reflection', colorHex: '0xFF7A96A8', iconName: 'moon'),
        Category(id: 'gratitude', name: 'Gratitude', colorHex: '0xFFD4A86A', iconName: 'sparkle'),
      ];
      for (final cat in defaultCategories) {
        await categoriesBox.put(cat.id, cat);
      }
    }

    // Seed default tags if empty
    if (tagsBox.isEmpty) {
      final defaultTags = [
        Tag(id: 'reflections', label: 'reflections'),
        Tag(id: 'milestones', label: 'milestones'),
        Tag(id: 'ideas', label: 'ideas'),
        Tag(id: 'memory', label: 'memory'),
      ];
      for (final tag in defaultTags) {
        await tagsBox.put(tag.id, tag);
      }
    }

    // Seed decoy box with bland placeholder entries if empty
    final decoyBox = Hive.box<DiaryEntry>(decoyEntriesBoxName);
    if (decoyBox.isEmpty) {
      final sampleDecoy = DiaryEntry(
        id: 'decoy-1',
        title: 'Weekly Grocery List',
        contentMarkdown: '- Almond milk\n- Whole grain bread\n- Organic apples\n- Green tea',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        categoryId: 'personal',
        mood: 'calm',
      );
      await decoyBox.put(sampleDecoy.id, sampleDecoy);
    }
  }
}
