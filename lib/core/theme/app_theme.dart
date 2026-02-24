import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color ink        = Color(0xFF0A0E1A);
  static const Color inkSoft    = Color(0xFF1C2235);
  static const Color inkMid     = Color(0xFF2E3650);
  static const Color border     = Color(0xFF2A3147);
  static const Color borderLight= Color(0xFF3D4B68);
  static const Color textColor  = Color(0xFFE8EBF4);
  static const Color textMuted  = Color(0xFF8892AA);
  static const Color textDim    = Color(0xFF5C6880);
  static const Color card       = Color(0xFF141928);

  static const Color accent  = Color(0xFF00E5C3);
  static const Color blue    = Color(0xFF4D9FFF);
  static const Color orange  = Color(0xFFFF6B35);
  static const Color red     = Color(0xFFFF4560);
  static const Color yellow  = Color(0xFFFFD166);
  static const Color green   = Color(0xFF06D6A0);
  static const Color purple  = Color(0xFFB388FF);

  static Color accentDim  = accent.withOpacity(0.12);
  static Color blueDim    = blue.withOpacity(0.12);
  static Color orangeDim  = orange.withOpacity(0.12);
  static Color redDim     = red.withOpacity(0.12);
  static Color yellowDim  = yellow.withOpacity(0.12);
  static Color greenDim   = green.withOpacity(0.12);
  static Color purpleDim  = purple.withOpacity(0.12);

  static Color priorityColor(String p) {
    switch (p) {
      case 'Critical': return red;
      case 'High':     return orange;
      case 'Medium':   return yellow;
      default:         return green;
    }
  }

  static Color priorityBg(String p) => priorityColor(p).withOpacity(0.12);

  static Color statusColor(String s) {
    switch (s) {
      case 'New':                return blue;
      case 'In Progress':        return purple;
      case 'Waiting for Client': return yellow;
      case 'Resolved':           return green;
      case 'Closed':             return textDim;
      default:                   return textMuted;
    }
  }

  static Color statusBg(String s) => statusColor(s).withOpacity(0.12);

  static Color clientColor(String c) {
    switch (c) {
      case 'Ecocash':      return green;
      case 'Econet':       return blue;
      case 'CWS':          return orange;
      case 'EMM':          return purple;
      case 'EthioTelecom': return red;
      default:             return textMuted;
    }
  }

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme.dark(
        primary: accent, secondary: blue,
        surface: card,
        error: red, onPrimary: ink, onSurface: textColor,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme)
          .apply(bodyColor: textColor, displayColor: textColor),
      appBarTheme: const AppBarTheme(
        backgroundColor: inkSoft, foregroundColor: textColor,
        elevation: 0, surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        color: card, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerColor: border,
      dividerTheme: const DividerThemeData(color: border, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: inkSoft,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accent, width: 1.5)),
        labelStyle: const TextStyle(color: textMuted, fontSize: 13),
        hintStyle: const TextStyle(color: textDim, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent, foregroundColor: ink, elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMuted, side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? accent : Colors.transparent),
        checkColor: WidgetStateProperty.all(ink),
        side: const BorderSide(color: borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),
    );
  }
}
