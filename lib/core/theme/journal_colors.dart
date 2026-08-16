import 'package:flutter/material.dart';

/// Design tokens for the "Whisper" Quiet Luxury Journal theme.
class JournalColors {
  JournalColors._();

  // --- Primary Accents ---
  static const Color burgundy = Color(0xFF7A2E2E);
  static const Color forest = Color(0xFF2F4739);
  static const Color goldAccent = Color(0xFFC89A4B);

  // --- Light Theme Colors ---
  static const Color lightBg = Color(0xFFF7F1E8);
  static const Color lightSurface = Color(0xFFFAF5ED);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightPaperGrain = Color(0xFFEFE6D8);
  static const Color lightTextPrimary = Color(0xFF1A1817);
  static const Color lightTextSecondary = Color(0xFF6B625B);
  static const Color lightBorder = Color(0xFFE5DACB);

  // --- Dark Theme Colors ---
  static const Color darkBg = Color(0xFF1C1815);
  static const Color darkSurface = Color(0xFF12100E);
  static const Color darkCard = Color(0xFF26211D);
  static const Color darkPaperGrain = Color(0xFF2D2723);
  static const Color darkTextPrimary = Color(0xFFE8E2D9);
  static const Color darkTextSecondary = Color(0xFFA3988E);
  static const Color darkBorder = Color(0xFF38302A);

  // --- Candlelight Theme Colors (Warm Sepia Night Mode) ---
  static const Color candleBg = Color(0xFF2B1D12);
  static const Color candleSurface = Color(0xFF23170E);
  static const Color candleCard = Color(0xFF38271A);
  static const Color candlePaperGrain = Color(0xFF453020);
  static const Color candleTextPrimary = Color(0xFFE8C99B);
  static const Color candleTextSecondary = Color(0xFFB59468);
  static const Color candleBorder = Color(0xFF4D3726);

  // --- Mood Pastel Colors ---
  static const Color moodEcstatic = Color(0xFFE6AD52); // Soft amber gold
  static const Color moodHappy = Color(0xFFD4A86A);    // Warm honey
  static const Color moodCalm = Color(0xFF8AA894);     // Sage green
  static const Color moodPensive = Color(0xFF7A96A8);  // Dust blue
  static const Color moodSad = Color(0xFF9E8AA8);      // Soft lavender gray
  static const Color moodAnxious = Color(0xFFC97A63);  // Terracotta rust
  static const Color moodAngry = Color(0xFFB55454);    // Muted crimson

  static Map<String, Color> get moodColorMap => {
    'ecstatic': moodEcstatic,
    'happy': moodHappy,
    'calm': moodCalm,
    'pensive': moodPensive,
    'sad': moodSad,
    'anxious': moodAnxious,
    'angry': moodAngry,
  };
}
