import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/utils/phosphor_icons.dart';

import '../../core/theme/journal_colors.dart';
import '../../core/theme/text_styles.dart';
import '../entries/journal_provider.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Appearance & Aesthetics', style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Text('Theme Palette', style: JournalTextStyles.uiHeader(theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          _buildThemeOption(
            context,
            ref,
            mode: 'candlelight',
            title: 'Candlelight (Warm Sepia)',
            subtitle: 'Warm amber text on deep espresso. Soft on eyes for late night writing.',
            color: JournalColors.candleBg,
            accentColor: JournalColors.candleTextPrimary,
            isSelected: settings.themeModeName == 'candlelight',
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            context,
            ref,
            mode: 'light',
            title: 'Ivory & Aged Paper',
            subtitle: 'Classic warm ivory journal with rich burgundy accents.',
            color: JournalColors.lightBg,
            accentColor: JournalColors.burgundy,
            isSelected: settings.themeModeName == 'light',
          ),
          const SizedBox(height: 12),
          _buildThemeOption(
            context,
            ref,
            mode: 'dark',
            title: 'Dark Charcoal Ink',
            subtitle: 'Sleek dark espresso with subtle gold accents.',
            color: JournalColors.darkBg,
            accentColor: JournalColors.goldAccent,
            isSelected: settings.themeModeName == 'dark',
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required String mode,
    required String title,
    required String subtitle,
    required Color color,
    required Color accentColor,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        ref.read(settingsProvider.notifier).setThemeMode(mode);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : theme.colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: accentColor, width: 2),
              ),
              child: isSelected ? Icon(PhosphorIcons.check(), color: accentColor, size: 22) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: JournalTextStyles.uiSubheader(theme.colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: JournalTextStyles.uiCaption(theme.colorScheme.onSurface)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
