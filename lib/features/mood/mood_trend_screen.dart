import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/utils/phosphor_icons.dart';

import '../../core/theme/journal_colors.dart';
import '../../core/theme/text_styles.dart';
import '../entries/journal_provider.dart';
import 'mood_picker_widget.dart';

class MoodTrendScreen extends ConsumerWidget {
  const MoodTrendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entries = ref.watch(journalEntriesProvider);

    // Calculate mood distribution
    final Map<String, int> moodCounts = {
      'ecstatic': 0,
      'happy': 0,
      'calm': 0,
      'pensive': 0,
      'sad': 0,
      'anxious': 0,
      'angry': 0,
    };

    for (final entry in entries) {
      if (entry.mood != null && moodCounts.containsKey(entry.mood)) {
        moodCounts[entry.mood!] = moodCounts[entry.mood!]! + 1;
      }
    }

    final totalMoodEntries = entries.where((e) => e.mood != null).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mood Trends & Heatmap', style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Mood Entries Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(PhosphorIcons.heartbeat(), color: theme.colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$totalMoodEntries Tracked Days',
                          style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your emotional journey over time',
                          style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Mood Distribution Statistics Bars
            Text('Mood Distribution', style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            ...MoodPickerWidget.moods.map((item) {
              final count = moodCounts[item.key] ?? 0;
              final percent = totalMoodEntries > 0 ? (count / totalMoodEntries) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(item.icon, size: 18, color: item.color),
                        const SizedBox(width: 8),
                        Text(item.label, style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                        const Spacer(),
                        Text(
                          '$count entries (${(percent * 100).toStringAsFixed(0)}%)',
                          style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(item.color),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Calendar Heatmap Grid (Last 30 Days)
            Text('Recent 30 Days Heatmap', style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 28,
              itemBuilder: (context, index) {
                final date = DateTime.now().subtract(Duration(days: 27 - index));
                final entryOnDate = entries.where((e) {
                  return e.createdAt.year == date.year &&
                      e.createdAt.month == date.month &&
                      e.createdAt.day == date.day;
                }).firstOrNull;

                Color tileColor = theme.colorScheme.surface;
                IconData? moodIcon;
                if (entryOnDate?.mood != null) {
                  tileColor = JournalColors.moodColorMap[entryOnDate!.mood!] ?? theme.colorScheme.primary;
                  final moodItem = MoodPickerWidget.moods.firstWhere((m) => m.key == entryOnDate.mood);
                  moodIcon = moodItem.icon;
                }

                return Tooltip(
                  message: '${DateFormat('MMM d').format(date)}: ${entryOnDate?.mood ?? 'No entry'}',
                  child: Container(
                    decoration: BoxDecoration(
                      color: tileColor.withValues(alpha: entryOnDate?.mood != null ? 0.8 : 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: moodIcon != null
                        ? Icon(
                            moodIcon,
                            size: 16,
                            color: theme.colorScheme.onPrimary,
                          )
                        : Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
