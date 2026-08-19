import 'package:flutter/material.dart';
import 'journal_colors.dart';
import 'text_styles.dart';

ThemeData get darkJournalTheme {
  const colorScheme = ColorScheme.dark(
    primary: JournalColors.goldAccent,
    secondary: JournalColors.forest,
    surface: JournalColors.darkSurface,
    onSurface: JournalColors.darkTextPrimary,
    onPrimary: JournalColors.darkBg,
    onSecondary: Colors.white,
    outline: JournalColors.darkBorder,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: JournalColors.darkBg,
    cardTheme: CardThemeData(
      color: JournalColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: JournalColors.darkBorder, width: 1.0),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: JournalColors.darkBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: JournalColors.darkTextPrimary),
      titleTextStyle: JournalTextStyles.uiHeader(JournalColors.darkTextPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: JournalColors.darkSurface,
      selectedItemColor: JournalColors.goldAccent,
      unselectedItemColor: JournalColors.darkTextSecondary,
      elevation: 4,
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: JournalColors.goldAccent,
      foregroundColor: JournalColors.darkBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 3,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: JournalColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: JournalColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: JournalColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: JournalColors.goldAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: JournalColors.darkBorder,
      thickness: 1,
    ),
  );
}
