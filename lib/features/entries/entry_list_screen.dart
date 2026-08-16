import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/utils/phosphor_icons.dart';

import '../../data/models/diary_entry.dart';
import '../../core/theme/journal_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../shared/utils/date_formatter.dart';
import '../../shared/widgets/page_card.dart';
import '../../shared/widgets/empty_state.dart';
import 'journal_provider.dart';

class EntryListScreen extends ConsumerStatefulWidget {
  const EntryListScreen({super.key});

  @override
  ConsumerState<EntryListScreen> createState() => _EntryListScreenState();
}

class _EntryListScreenState extends ConsumerState<EntryListScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedEntryIds = {};

  Map<String, List<DiaryEntry>> _groupEntriesByMonth(List<DiaryEntry> entries) {
    final Map<String, List<DiaryEntry>> groups = {};
    for (final entry in entries) {
      final key = DateFormatter.formatMonthYear(entry.createdAt);
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(entry);
    }
    return groups;
  }

  void _enterSelectionMode(String initialId) {
    setState(() {
      _isSelectionMode = true;
      _selectedEntryIds.add(initialId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedEntryIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedEntryIds.contains(id)) {
        _selectedEntryIds.remove(id);
        if (_selectedEntryIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedEntryIds.add(id);
      }
    });
  }

  void _selectAll(List<DiaryEntry> allEntries) {
    setState(() {
      if (_selectedEntryIds.length == allEntries.length) {
        _selectedEntryIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedEntryIds.addAll(allEntries.map((e) => e.id));
      }
    });
  }

  Future<void> _bulkDelete() async {
    if (_selectedEntryIds.isEmpty) return;

    final count = _selectedEntryIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Delete $count ${count == 1 ? 'Page' : 'Pages'}?',
            style: JournalTextStyles.uiHeader(Theme.of(context).colorScheme.onSurface),
          ),
          content: Text(
            'Are you sure you want to permanently delete $count selected secret ${count == 1 ? 'page' : 'pages'}? This action cannot be undone.',
            style: JournalTextStyles.uiBody(Theme.of(context).colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: JournalColors.burgundy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final idsToDelete = List<String>.from(_selectedEntryIds);
      await ref.read(journalEntriesProvider.notifier).bulkDeleteEntries(idsToDelete);
      if (mounted) {
        _exitSelectionMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count ${count == 1 ? 'page' : 'pages'} deleted'),
            backgroundColor: JournalColors.burgundy,
          ),
        );
      }
    }
  }

  Future<void> _bulkToggleFavorite() async {
    final ids = List<String>.from(_selectedEntryIds);
    _exitSelectionMode();
    await ref.read(journalEntriesProvider.notifier).bulkToggleFavorite(ids);
  }

  Future<void> _bulkToggleLock() async {
    final ids = List<String>.from(_selectedEntryIds);
    _exitSelectionMode();
    await ref.read(journalEntriesProvider.notifier).bulkToggleLock(ids);
  }

  Future<bool?> _confirmSingleDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Entry?', style: JournalTextStyles.uiHeader(Theme.of(context).colorScheme.onSurface)),
          content: Text(
            'Are you sure you want to permanently delete this secret page? This action cannot be undone.',
            style: JournalTextStyles.uiBody(Theme.of(context).colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: JournalColors.burgundy,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = ref.watch(filteredEntriesProvider);
    final repo = ref.watch(diaryRepositoryProvider);
    final filter = ref.watch(journalFilterProvider);
    final groupedEntries = _groupEntriesByMonth(entries);

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: Icon(PhosphorIcons.x()),
                onPressed: _exitSelectionMode,
              ),
              title: Text(
                '${_selectedEntryIds.length} Selected',
                style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _selectedEntryIds.length == entries.length
                        ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                        : PhosphorIcons.checkCircle(),
                  ),
                  tooltip: _selectedEntryIds.length == entries.length ? 'Deselect All' : 'Select All',
                  onPressed: () => _selectAll(entries),
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.star()),
                  tooltip: 'Favorite Selected',
                  onPressed: _bulkToggleFavorite,
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.lockKey()),
                  tooltip: 'Lock/Unlock Selected',
                  onPressed: _bulkToggleLock,
                ),
                IconButton(
                  icon: Icon(
                    PhosphorIcons.trash(),
                    color: JournalColors.burgundy,
                  ),
                  tooltip: 'Delete Selected',
                  onPressed: _bulkDelete,
                ),
              ],
            )
          : AppBar(
              title: Text(
                'SecDiary',
                style: JournalTextStyles.journalTitle(theme.colorScheme.onSurface).copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    filter.favoritesOnly
                        ? PhosphorIcons.star(PhosphorIconsStyle.fill)
                        : PhosphorIcons.star(),
                    color: filter.favoritesOnly ? JournalColors.goldAccent : theme.colorScheme.onSurface,
                  ),
                  tooltip: 'Filter Favorites',
                  onPressed: () {
                    ref.read(journalFilterProvider.notifier).state = filter.copyWith(
                      favoritesOnly: !filter.favoritesOnly,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.chartBar()),
                  tooltip: 'Mood Trends',
                  onPressed: () => context.push('/mood-trends'),
                ),
              ],
            ),
      body: entries.isEmpty
          ? EmptyStateWidget(
              title: filter.favoritesOnly ? 'No Favorite Pages Yet' : 'Your first page is waiting.',
              subtitle: filter.favoritesOnly
                  ? 'Tap the star on any entry to add it to your favorites.'
                  : 'Tap the button below to write your first entry.',
              onActionTap: () => context.push('/entry/new'),
              actionLabel: 'Write New Entry',
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: groupedEntries.keys.length,
              itemBuilder: (context, index) {
                final monthKey = groupedEntries.keys.elementAt(index);
                final monthEntries = groupedEntries[monthKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sticky Date Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        monthKey,
                        style: JournalTextStyles.uiSubheader(
                          theme.colorScheme.primary.withValues(alpha: 0.8),
                        ).copyWith(
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...monthEntries.map((entry) {
                      final category = repo.getCategoryById(entry.categoryId);
                      final isSelected = _selectedEntryIds.contains(entry.id);

                      final pageCard = PageCard(
                        entry: entry,
                        category: category,
                        isSelectionMode: _isSelectionMode,
                        isSelected: isSelected,
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(entry.id);
                          } else {
                            context.push('/entry/${entry.id}');
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _enterSelectionMode(entry.id);
                          } else {
                            _toggleSelection(entry.id);
                          }
                        },
                        onFavoriteToggle: () {
                          ref.read(journalEntriesProvider.notifier).toggleFavorite(entry.id);
                        },
                      );

                      if (_isSelectionMode) {
                        return pageCard;
                      }

                      return Dismissible(
                        key: Key(entry.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) => _confirmSingleDelete(context),
                        onDismissed: (direction) async {
                          await ref.read(journalEntriesProvider.notifier).deleteEntry(entry.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Entry deleted'),
                                backgroundColor: JournalColors.burgundy,
                              ),
                            );
                          }
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: JournalColors.burgundy.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Delete', style: JournalTextStyles.uiSubheader(Colors.white)),
                              const SizedBox(width: 8),
                              Icon(PhosphorIcons.trash(), color: Colors.white),
                            ],
                          ),
                        ),
                        child: pageCard,
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}
