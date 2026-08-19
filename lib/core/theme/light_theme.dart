import 'package:flutter/material.dart';
import 'journal_colors.dart';
import 'text_styles.dart';

ThemeData get lightJournalTheme {
  const colorScheme = ColorScheme.light(
    primary: JournalColors.burgundy,
    secondary: JournalColors.forest,
    surface: JournalColors.lightSurface,
    onSurface: JournalColors.lightTextPrimary,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    outline: JournalColors.lightBorder,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: JournalColors.lightBg,
    cardTheme: CardThemeData(
      color: JournalColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: JournalColors.lightBorder, width: 1.0),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: JournalColors.lightBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: JournalColors.lightTextPrimary),
      titleTextStyle: JournalTextStyles.uiHeader(JournalColors.lightTextPrimary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: JournalColors.lightSurface,
      selectedItemColor: JournalColors.burgundy,
      unselectedItemColor: JournalColors.lightTextSecondary,
      elevation: 4,
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: JournalColors.burgundy,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 3,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: JournalColors.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: JournalColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: JournalColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: JournalColors.burgundy, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: JournalColors.lightBorder,
      thickness: 1,
    ),
  );
}
