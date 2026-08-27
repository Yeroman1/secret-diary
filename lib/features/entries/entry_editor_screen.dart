import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/utils/phosphor_icons.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/diary_entry.dart';
import '../../core/theme/journal_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../shared/widgets/wax_seal_badge.dart';
import '../mood/mood_picker_widget.dart';
import 'journal_provider.dart';
import '../../shared/utils/markdown_editing_controller.dart';
import 'widgets/markdown_toolbar.dart';

class EntryEditorScreen extends ConsumerStatefulWidget {
  final String entryId;

  const EntryEditorScreen({super.key, required this.entryId});

  @override
  ConsumerState<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends ConsumerState<EntryEditorScreen> {
  late TextEditingController _titleController;
  late MarkdownEditingController _contentController;
  late TextEditingController _tagController;
  final FocusNode _contentFocusNode = FocusNode();

  late String _currentEntryId;
  String? _selectedCategory;
  String? _selectedMood;
  List<String> _tags = [];
  bool _isFavorite = false;
  bool _isLocked = false;
  bool _isSaving = false;
  Timer? _debounceSaveTimer;
  DateTime _createdAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = MarkdownEditingController();
    _tagController = TextEditingController();

    _currentEntryId = widget.entryId == 'new' ? const Uuid().v4() : widget.entryId;

    _loadExistingEntry();

    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
  }

  void _loadExistingEntry() {
    if (widget.entryId != 'new') {
      final repo = ref.read(diaryRepositoryProvider);
      final existing = repo.getEntryById(widget.entryId);
      if (existing != null) {
        _titleController.text = existing.title;
        _contentController.text = existing.contentMarkdown;
        _selectedCategory = existing.categoryId;
        _selectedMood = existing.mood;
        _tags = List.from(existing.tagIds);
        _isFavorite = existing.isFavorite;
        _isLocked = existing.isLocked;
        _createdAt = existing.createdAt;
      }
    }
  }

  void _onContentChanged() {
    _debounceSaveTimer?.cancel();
    setState(() {
      _isSaving = true;
    });
    _debounceSaveTimer = Timer(const Duration(milliseconds: 800), () {
      _autoSave();
    });
  }

  Future<void> _autoSave() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    final entry = DiaryEntry(
      id: _currentEntryId,
      title: title,
      contentMarkdown: content,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
      tagIds: _tags,
      categoryId: _selectedCategory,
      mood: _selectedMood,
      isFavorite: _isFavorite,
      isLocked: _isLocked,
    );

    await ref.read(journalEntriesProvider.notifier).addOrUpdateEntry(entry);
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                _debounceSaveTimer?.cancel();
                await ref.read(journalEntriesProvider.notifier).deleteEntry(_currentEntryId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Entry deleted'),
                      backgroundColor: JournalColors.burgundy,
                    ),
                  );
                  context.pop();
                }
              },
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

  int get _wordCount {
    final text = _contentController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  void _addTag(String tag) {
    final clean = tag.trim().replaceAll('#', '').toLowerCase();
    if (clean.isNotEmpty && !_tags.contains(clean)) {
      setState(() {
        _tags.add(clean);
        _tagController.clear();
      });
      _autoSave();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    _autoSave();
  }

  @override
  void dispose() {
    _debounceSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(diaryRepositoryProvider);
    final categories = repo.getAllCategories();

    return Hero(
      tag: 'entry_hero_${widget.entryId}',
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(PhosphorIcons.caretLeft()),
            onPressed: () {
              _autoSave();
              context.pop();
            },
          ),
          actions: [
            // Autosave Indicator Feather / Check
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isSaving
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(
                        PhosphorIcons.feather(),
                        size: 20,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
            ),
            // Lock Toggle (Wax Seal)
            IconButton(
              icon: _isLocked
                  ? const WaxSealBadge(isSmall: true)
                  : Icon(
                      PhosphorIcons.lockKey(),
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              tooltip: _isLocked ? 'Unlock Entry' : 'Lock Entry (Extra Secure)',
              onPressed: () {
                setState(() {
                  _isLocked = !_isLocked;
                });
                _autoSave();
              },
            ),
            // Favorite Toggle
            IconButton(
              icon: Icon(
                _isFavorite ? PhosphorIcons.star(PhosphorIconsStyle.fill) : PhosphorIcons.star(),
                color: _isFavorite ? JournalColors.goldAccent : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              onPressed: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                });
                _autoSave();
              },
            ),
            // Delete Entry Button
            IconButton(
              icon: Icon(
                PhosphorIcons.trash(),
                color: JournalColors.burgundy,
              ),
              tooltip: 'Delete Page',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Word Count header row
                      Row(
                        children: [
                          // Category Selector Dropdown
                          DropdownButton<String>(
                            value: _selectedCategory,
                            hint: Text('Select Category', style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface)),
                            underline: const SizedBox(),
                            icon: Icon(PhosphorIcons.caretDown(), size: 16),
                            items: categories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat.id,
                                child: Text(cat.name, style: JournalTextStyles.uiBody(theme.colorScheme.onSurface)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCategory = val;
                              });
                              _autoSave();
                            },
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              '$_wordCount words',
                              style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Mood Selector
                      MoodPickerWidget(
                        selectedMood: _selectedMood,
                        onMoodSelected: (mood) {
                          setState(() {
                            _selectedMood = mood;
                          });
                          _autoSave();
                        },
                      ),
                      const SizedBox(height: 20),

                      // Title Field
                      TextField(
                        controller: _titleController,
                        style: JournalTextStyles.journalTitle(theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Title...',
                          hintStyle: JournalTextStyles.journalTitle(theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          fillColor: Colors.transparent,
                        ),
                      ),
                      const Divider(height: 24),

                      // Live Rich-Text Content Editor
                      TextField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        maxLines: null,
                        inputFormatters: const [
                          MarkdownTextInputFormatter(),
                        ],
                        style: JournalTextStyles.journalBody(theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Write your thoughts out loud...',
                          hintStyle: JournalTextStyles.journalBody(
                            theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          fillColor: Colors.transparent,
                        ),
                      ),

                      const SizedBox(height: 32),
                      // Tag Chips Section
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ..._tags.map((tag) => Chip(
                                label: Text('#$tag', style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface)),
                                onDeleted: () => _removeTag(tag),
                                backgroundColor: theme.colorScheme.surface,
                                side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                              )),
                          SizedBox(
                            width: 120,
                            height: 36,
                            child: TextField(
                              controller: _tagController,
                              style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface),
                              decoration: InputDecoration(
                                hintText: '+ Add tag',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                fillColor: theme.colorScheme.surface,
                              ),
                              onSubmitted: _addTag,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Live Formatting Toolbar
              MarkdownToolbar(
                controller: _contentController,
                focusNode: _contentFocusNode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
