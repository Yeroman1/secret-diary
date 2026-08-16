import 'package:flutter/material.dart';
import 'journal_colors.dart';
import 'text_styles.dart';

ThemeData get candlelightJournalTheme {
  const colorScheme = ColorScheme.dark(
    primary: JournalColors.candleTextPrimary,
    secondary: JournalColors.goldAccent,
    surface: JournalColors.candleSurface,
    onSurface: JournalColors.candleTextPrimary,
    onPrimary: JournalColors.candleBg,
    onSecondary: JournalColors.candleBg,
    outline: JournalColors.candleBorder,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: JournalColors.candleBg,
    cardTheme: CardThemeData(
      color: JournalColors.candleCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: JournalColors.candleBorder, width: 1.0),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: JournalColors.candleBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: JournalColors.candleTextPrimary),
      titleTextStyle: JournalTextStyles.uiHeader(JournalColors.candleTextPrimary),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: JournalColors.candleSurface,
      selectedItemColor: JournalColors.candleTextPrimary,
      unselectedItemColor: JournalColors.candleTextSecondary,
      elevation: 4,
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: JournalColors.candleTextPrimary,
      foregroundColor: JournalColors.candleBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 3,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: JournalColors.candleSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: JournalColors.candleBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: JournalColors.candleBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: JournalColors.candleTextPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: JournalColors.candleBorder,
      thickness: 1,
    ),
  );
}
