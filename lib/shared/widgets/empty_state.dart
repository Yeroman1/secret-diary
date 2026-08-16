import 'package:flutter/material.dart';
import '../utils/phosphor_icons.dart';
import '../../core/theme/text_styles.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final VoidCallback? onActionTap;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    this.title = 'Your first page is waiting.',
    this.subtitle = 'Write down your quiet thoughts, memories, or moments of gratitude.',
    this.icon,
    this.onActionTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayIcon = icon ?? PhosphorIcons.bookOpen();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                displayIcon,
                size: 48.0,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: JournalTextStyles.journalTitle(theme.colorScheme.onSurface).copyWith(
                fontSize: 20.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: JournalTextStyles.journalBody(
                theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 14.0,
              ),
              textAlign: TextAlign.center,
            ),
            if (onActionTap != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onActionTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                icon: Icon(PhosphorIcons.plus(), size: 18),
                label: Text(actionLabel!, style: JournalTextStyles.uiSubheader(Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
