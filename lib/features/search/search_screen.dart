import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/utils/phosphor_icons.dart';

import '../../core/theme/text_styles.dart';
import '../../shared/widgets/page_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../entries/journal_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.text = ref.read(journalFilterProvider).searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(journalFilterProvider);
    final filteredEntries = ref.watch(filteredEntriesProvider);
    final repo = ref.watch(diaryRepositoryProvider);
    final categories = repo.getAllCategories();
    final tags = repo.getAllTags();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search & Filter',
          style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface),
        ),
      ),
      body: Column(
        children: [
          // Search Input Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              style: JournalTextStyles.uiBody(theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search entries, titles, tags...',
                prefixIcon: Icon(PhosphorIcons.magnifyingGlass()),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(PhosphorIcons.x(), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(journalFilterProvider.notifier).state = filter.copyWith(searchQuery: '');
                        },
                      )
                    : null,
              ),
              onChanged: (query) {
                ref.read(journalFilterProvider.notifier).state = filter.copyWith(searchQuery: query);
              },
            ),
          ),

          // Horizontal Filter Chips (Categories & Tags)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Category Filter Dropdown Chip
                if (categories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        filter.categoryId != null
                            ? repo.getCategoryById(filter.categoryId)?.name ?? 'Category'
                            : 'All Categories',
                      ),
                      selected: filter.categoryId != null,
                      onSelected: (selected) {
                        if (!selected) {
                          ref.read(journalFilterProvider.notifier).state = filter.copyWith(clearCategory: true);
                        } else {
                          _showCategoryFilterPicker(context, ref, categories, filter);
                        }
                      },
                      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),

                // Tags Chips
                ...tags.map((t) {
                  final isSelected = filter.tagId == t.label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('#${t.label}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        ref.read(journalFilterProvider.notifier).state = filter.copyWith(
                          tagId: selected ? t.label : null,
                          clearTag: !selected,
                        );
                      },
                      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 16),

          // Search Results
          Expanded(
            child: filteredEntries.isEmpty
                ? EmptyStateWidget(
                    title: 'No Matching Pages Found',
                    subtitle: 'Try adjusting your search term or clearing active filters.',
                    icon: PhosphorIcons.magnifyingGlass(),
                  )
                : ListView.builder(
                    itemCount: filteredEntries.length,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      final category = repo.getCategoryById(entry.categoryId);
                      return PageCard(
                        entry: entry,
                        category: category,
                        onTap: () => context.push('/entry/${entry.id}'),
                        onFavoriteToggle: () {
                          ref.read(journalEntriesProvider.notifier).toggleFavorite(entry.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCategoryFilterPicker(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> categories,
    JournalFilterState filter,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Filter by Category', style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface)),
              ),
              ListTile(
                title: const Text('All Categories'),
                onTap: () {
                  ref.read(journalFilterProvider.notifier).state = filter.copyWith(clearCategory: true);
                  Navigator.pop(context);
                },
              ),
              ...categories.map((cat) => ListTile(
                    title: Text(cat.name),
                    onTap: () {
                      ref.read(journalFilterProvider.notifier).state = filter.copyWith(categoryId: cat.id);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }
}
