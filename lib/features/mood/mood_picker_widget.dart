import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/journal_colors.dart';
import '../../core/theme/text_styles.dart';

class MoodItem {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const MoodItem({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class MoodPickerWidget extends StatelessWidget {
  final String? selectedMood;
  final Function(String moodKey) onMoodSelected;

  static const List<MoodItem> moods = [
    MoodItem(key: 'ecstatic', label: 'Ecstatic', icon: Icons.auto_awesome, color: JournalColors.moodEcstatic),
    MoodItem(key: 'happy', label: 'Happy', icon: Icons.sentiment_very_satisfied, color: JournalColors.moodHappy),
    MoodItem(key: 'calm', label: 'Calm', icon: Icons.spa, color: JournalColors.moodCalm),
    MoodItem(key: 'pensive', label: 'Pensive', icon: Icons.psychology, color: JournalColors.moodPensive),
    MoodItem(key: 'sad', label: 'Sad', icon: Icons.sentiment_dissatisfied, color: JournalColors.moodSad),
    MoodItem(key: 'anxious', label: 'Anxious', icon: Icons.bolt, color: JournalColors.moodAnxious),
    MoodItem(key: 'angry', label: 'Angry', icon: Icons.local_fire_department, color: JournalColors.moodAngry),
  ];

  const MoodPickerWidget({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: moods.length,
        itemBuilder: (context, index) {
          final item = moods[index];
          final isSelected = selectedMood == item.key;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onMoodSelected(item.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? item.color.withValues(alpha: 0.25) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? item.color : theme.colorScheme.outline.withValues(alpha: 0.5),
                  width: isSelected ? 1.8 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: isSelected ? item.color : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: JournalTextStyles.uiCaption(
                      isSelected ? item.color : theme.colorScheme.onSurface,
                    ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
