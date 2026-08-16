import 'package:flutter/material.dart';
import '../utils/phosphor_icons.dart';
import '../../data/models/diary_entry.dart';
import '../../data/models/category.dart';
import '../../core/theme/journal_colors.dart';
import '../../core/theme/text_styles.dart';
import '../utils/date_formatter.dart';
import '../utils/markdown_stripper.dart';
import 'wax_seal_badge.dart';

class PageCard extends StatelessWidget {
  final DiaryEntry entry;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const PageCard({
    super.key,
    required this.entry,
    this.category,
    required this.onTap,
    required this.onFavoriteToggle,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  Color _parseCategoryColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return JournalColors.burgundy;
    try {
      final hex = colorHex.replaceAll('0x', '').replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return JournalColors.burgundy;
    }
  }

  String _getMoodEmoji(String? mood) {
    switch (mood) {
      case 'ecstatic':
        return '✨';
      case 'happy':
        return '😊';
      case 'calm':
        return '🌿';
      case 'pensive':
        return '🌙';
      case 'sad':
        return '🌧️';
      case 'anxious':
        return '⚡';
      case 'angry':
        return '🔥';
      default:
        return '📖';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _parseCategoryColor(category?.colorHex);
    final excerpt = MarkdownStripper.strip(entry.contentMarkdown);

    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline.withValues(alpha: 0.7);

    final cardBgColor = isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : theme.cardTheme.color;

    return Hero(
      tag: 'entry_hero_${entry.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Stack(
                children: [
                  // Left category color accent stripe
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 5.0,
                      color: categoryColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18.0, 16.0, 16.0, 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Selection checkbox or Date, Mood emoji, Category pill & Wax seal / Favorite
                        Row(
                          children: [
                            if (isSelectionMode) ...[
                              Icon(
                                isSelected
                                    ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                                    : PhosphorIcons.circle(),
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                            ],
                            Text(
                              _getMoodEmoji(entry.mood),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormatter.formatJournalDate(entry.createdAt),
                              style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface),
                            ),
                            const Spacer(),
                            if (category != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  category!.name,
                                  style: JournalTextStyles.uiCaption(categoryColor).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (entry.isLocked) const WaxSealBadge(isSmall: true),
                            if (!isSelectionMode)
                              IconButton(
                                icon: Icon(
                                  entry.isFavorite
                                      ? PhosphorIcons.star(PhosphorIconsStyle.fill)
                                      : PhosphorIcons.star(),
                                  color: entry.isFavorite
                                      ? JournalColors.goldAccent
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                  size: 18,
                                ),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                onPressed: onFavoriteToggle,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Title
                        Text(
                          entry.title.isEmpty ? 'Untitled Page' : entry.title,
                          style: JournalTextStyles.journalTitle(theme.colorScheme.onSurface).copyWith(
                            fontSize: 18.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Content Excerpt or Lock placeholder
                        if (entry.isLocked)
                          Text(
                            '🔒 This page is private and locked.',
                            style: JournalTextStyles.journalBody(
                              theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 13.0,
                            ).copyWith(fontStyle: FontStyle.italic),
                          )
                        else
                          Text(
                            excerpt.isEmpty ? 'No text content...' : excerpt,
                            style: JournalTextStyles.journalBody(
                              theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              fontSize: 14.0,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        // Tags row
                        if (entry.tagIds.isNotEmpty && !entry.isLocked) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: entry.tagIds.map((tagId) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Text(
                                  '#$tagId',
                                  style: JournalTextStyles.uiCaption(
                                    theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
