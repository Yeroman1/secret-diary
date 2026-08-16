import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography configuration for the Whisper Journal.
/// - Literary Serif (`Lora`) for entry title & body content.
/// - Warm Humanist Sans (`Karla`) for UI chrome (labels, navigation, buttons).
class JournalTextStyles {
  JournalTextStyles._();

  // --- Serif Styles for Entries ---
  static TextStyle journalTitle(Color color) {
    return GoogleFonts.lora(
      fontSize: 24.0,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.3,
      letterSpacing: -0.2,
    );
  }

  static TextStyle journalBody(Color color, {double fontSize = 16.0}) {
    return GoogleFonts.lora(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.65, // Generous line height for quiet reading
      letterSpacing: 0.1,
    );
  }

  static TextStyle journalQuote(Color color) {
    return GoogleFonts.lora(
      fontSize: 16.0,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      color: color.withValues(alpha: 0.85),
      height: 1.6,
    );
  }

  // --- Humanist Sans for UI Chrome ---
  static TextStyle uiHeader(Color color) {
    return GoogleFonts.karla(
      fontSize: 20.0,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: -0.3,
    );
  }

  static TextStyle uiSubheader(Color color) {
    return GoogleFonts.karla(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: -0.1,
    );
  }

  static TextStyle uiBody(Color color) {
    return GoogleFonts.karla(
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle uiLabel(Color color) {
    return GoogleFonts.karla(
      fontSize: 12.0,
      fontWeight: FontWeight.w600,
      color: color,
      letterSpacing: 0.5,
    );
  }

  static TextStyle uiCaption(Color color) {
    return GoogleFonts.karla(
      fontSize: 11.0,
      fontWeight: FontWeight.w500,
      color: color.withValues(alpha: 0.7),
    );
  }
}
