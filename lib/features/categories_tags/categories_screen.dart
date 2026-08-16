import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/utils/phosphor_icons.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/category.dart';
import '../../data/models/tag.dart';
import '../../core/theme/journal_colors.dart';
import '../../core/theme/text_styles.dart';
import '../entries/journal_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _parseCategoryColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return JournalColors.burgundy;
    try {
      final hex = colorHex.replaceAll('0x', '').replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return JournalColors.burgundy;
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    String selectedColor = '0xFF7A2E2E';

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text('New Category', style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Category Name (e.g. Travel)'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  '0xFF7A2E2E',
                  '0xFF2F4739',
                  '0xFF7A96A8',
                  '0xFFD4A86A',
                  '0xFF9E8AA8',
                ].map((colorHex) {
                  final color = Color(int.parse(colorHex));
                  return GestureDetector(
                    onTap: () {
                      selectedColor = colorHex;
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  final cat = Category(
                    id: const Uuid().v4(),
                    name: nameController.text.trim(),
                    colorHex: selectedColor,
                    iconName: 'folder',
                  );
                  await ref.read(diaryRepositoryProvider).saveCategory(cat);
                  setState(() {});
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showAddTagDialog(BuildContext context) {
    final tagController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text('New Tag', style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface)),
          content: TextField(
            controller: tagController,
            decoration: const InputDecoration(hintText: 'Tag label (e.g. reflections)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final label = tagController.text.trim().replaceAll('#', '').toLowerCase();
                if (label.isNotEmpty) {
                  final tag = Tag(id: label, label: label);
                  await ref.read(diaryRepositoryProvider).saveTag(tag);
                  setState(() {});
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(diaryRepositoryProvider);
    final categories = repo.getAllCategories();
    final tags = repo.getAllTags();
    final allEntries = ref.watch(journalEntriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Categories & Tags', style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface)),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: JournalTextStyles.uiSubheader(theme.colorScheme.primary),
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Tags'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Categories Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final catColor = _parseCategoryColor(cat.colorHex);
              final count = allEntries.where((e) => e.categoryId == cat.id).length;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                  ),
                  title: Text(cat.name, style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                  subtitle: Text('$count pages', style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface)),
                  trailing: IconButton(
                    icon: Icon(PhosphorIcons.trash(), size: 18),
                    onPressed: () async {
                      await repo.deleteCategory(cat.id);
                      setState(() {});
                    },
                  ),
                ),
              );
            },
          ),

          // Tags Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              final count = allEntries.where((e) => e.tagIds.contains(tag.label)).length;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(PhosphorIcons.tag(), color: theme.colorScheme.primary),
                  title: Text('#${tag.label}', style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                  subtitle: Text('$count pages', style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface)),
                  trailing: IconButton(
                    icon: Icon(PhosphorIcons.trash(), size: 18),
                    onPressed: () async {
                      await repo.deleteTag(tag.id);
                      setState(() {});
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddCategoryDialog(context);
          } else {
            _showAddTagDialog(context);
          }
        },
        icon: Icon(PhosphorIcons.plus()),
        label: Text(_tabController.index == 0 ? 'Add Category' : 'Add Tag'),
      ),
    );
  }
}
