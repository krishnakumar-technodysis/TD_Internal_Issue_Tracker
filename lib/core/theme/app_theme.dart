 // lib/core/theme/app_theme.dart

// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Base surfaces — warm linen, never harsh white ─────────────────────
  static const Color ink         = Color(0xFFF5F2EE); // warm linen — scaffold bg
  static const Color inkSoft     = Color(0xFFEDE8E1); // sidebar background
  static const Color inkMid      = Color(0xFFDDD5C8); // sidebar border / hover states
  static const Color border      = Color(0xFFE2D9CE); // default card & row dividers
  static const Color borderLight = Color(0xFFD4C9BC); // input fields / stronger borders

  // ── Card & surface ────────────────────────────────────────────────────
  static const Color card    = Color(0xFFFDFCFA); // main card / white surface
  static const Color cardAlt = Color(0xFFF8F5F0); // input bg / alternating rows

  // ── Text — warm slate, never cold grey ───────────────────────────────
  static const Color textColor = Color(0xFF2C2825); // near-black, warm
  static const Color textMuted = Color(0xFF6B635A); // body / secondary text
  static const Color textDim   = Color(0xFF9E9188); // labels / placeholders

  // ── Brand accent — deep calm teal ────────────────────────────────────
  static const Color accent   = Color(0xFF2D7D6F); // primary CTA colour
  static const Color accentBg = Color(0xFFEAF4F2); // teal tint background

  // ── Semantic colours — muted jewel tones, eye-friendly ───────────────
  static const Color blue    = Color(0xFF1D5F9E); // "New" status
  static const Color orange  = Color(0xFFB45309); // "High" priority / "Waiting"
  static const Color red     = Color(0xFFC0392B); // "Critical" priority
  static const Color yellow  = Color(0xFF92720A); // "Medium" priority (muted gold)
  static const Color green   = Color(0xFF276749); // "Low" priority / "Resolved"
  static const Color purple  = Color(0xFF6B48A0); // "In Progress" status

  // ── Semantic background fills (badge tints) ───────────────────────────
  static const Color blueBg   = Color(0xFFEBF5FC);
  static const Color orangeBg = Color(0xFFFEF3E2);
  static const Color redBg    = Color(0xFFFDECEA);
  static const Color yellowBg = Color(0xFFFEF9E7);
  static const Color greenBg  = Color(0xFFEAFAF1);
  static const Color purpleBg = Color(0xFFF3EEFF);
  static const Color slateBg  = Color(0xFFF0F2F5);

  // ── Dim opacity versions (charts / icon backgrounds) ─────────────────
  static Color accentDim = accent.withOpacity(0.13);
  static Color blueDim   = blue.withOpacity(0.12);
  static Color orangeDim = orange.withOpacity(0.12);
  static Color redDim    = red.withOpacity(0.12);
  static Color yellowDim = yellow.withOpacity(0.13);
  static Color greenDim  = green.withOpacity(0.12);
  static Color purpleDim = purple.withOpacity(0.12);

  // ── Client brand colours ──────────────────────────────────────────────
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

  // ── Priority helpers ──────────────────────────────────────────────────
  static Color priorityColor(String p) {
    switch (p) {
      case 'Critical': return red;
      case 'High':     return orange;
      case 'Medium':   return yellow;
      default:         return green;
    }
  }

  static Color priorityBg(String p) {
    switch (p) {
      case 'Critical': return redBg;
      case 'High':     return orangeBg;
      case 'Medium':   return yellowBg;
      default:         return greenBg;
    }
  }

  // ── Status helpers ────────────────────────────────────────────────────
  static Color statusColor(String s) {
    switch (s) {
      case 'New':                return blue;
      case 'In Progress':        return purple;
      case 'Waiting for Client': return orange;
      case 'Resolved':           return green;
      case 'Closed':             return const Color(0xFF5A6272);
      default:                   return textMuted;
    }
  }

  static Color statusBg(String s) {
    switch (s) {
      case 'New':                return blueBg;
      case 'In Progress':        return purpleBg;
      case 'Waiting for Client': return orangeBg;
      case 'Resolved':           return greenBg;
      case 'Closed':             return slateBg;
      default:                   return cardAlt;
    }
  }

  // ── MaterialApp ThemeData ─────────────────────────────────────────────
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ink,

      colorScheme: const ColorScheme.light(
        primary:     accent,
        secondary:   blue,
        surface:     card,
        error:       red,
        onPrimary:   Colors.white,
        onSecondary: Colors.white,
        onSurface:   textColor,
        onError:     Colors.white,
      ),

      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme)
          .apply(bodyColor: textColor, displayColor: textColor),

      appBarTheme: const AppBarTheme(
        backgroundColor:   card,
        foregroundColor:   textColor,
        elevation:         0,
        surfaceTintColor:  Colors.transparent,
        shadowColor:       Colors.transparent,
        titleTextStyle: TextStyle(
          color: textColor, fontSize: 17, fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textMuted),
      ),

      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),

      dividerColor: border,
      dividerTheme: const DividerThemeData(color: border, space: 1),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardAlt,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderLight)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderLight)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: red, width: 1.5)),
        labelStyle:       const TextStyle(color: textMuted, fontSize: 13),
        hintStyle:        const TextStyle(color: textDim,   fontSize: 13),
        prefixIconColor:  textDim,
        suffixIconColor:  textDim,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation:       0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMuted,
          side: const BorderSide(color: borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? accent : Colors.transparent),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: borderLight, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? accent : textDim),
        trackColor: WidgetStateProperty.resolveWith((s) =>
        s.contains(WidgetState.selected) ? accentBg : border),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: cardAlt,
        labelStyle: const TextStyle(color: textMuted, fontSize: 12),
        side: const BorderSide(color: borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      listTileTheme: const ListTileThemeData(
        tileColor:  Colors.transparent,
        textColor:  textColor,
        iconColor:  textMuted,
      ),

      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: inkSoft,
        selectedIconTheme:   IconThemeData(color: accent),
        unselectedIconTheme: IconThemeData(color: textMuted),
        selectedLabelTextStyle:   TextStyle(color: accent,     fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: textMuted),
        indicatorColor: accentBg,
      ),

      dialogTheme: DialogTheme(
        backgroundColor: card,
        elevation:   8,
        shadowColor: const Color(0x1A2C2825),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
        titleTextStyle: GoogleFonts.dmSans(
            fontSize: 17, fontWeight: FontWeight.w700, color: textColor),
        contentTextStyle: GoogleFonts.dmSans(fontSize: 14, color: textMuted),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2C2825),
        contentTextStyle: GoogleFonts.dmSans(fontSize: 13, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2825),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: GoogleFonts.dmSans(fontSize: 12, color: Colors.white),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color:             accent,
        linearTrackColor:  accentBg,
        circularTrackColor: accentBg,
      ),

      tabBarTheme: const TabBarTheme(
        labelColor:           accent,
        unselectedLabelColor: textMuted,
        indicatorColor:       accent,
        dividerColor:         border,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled:      true,
          fillColor:   cardAlt,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: borderLight)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: borderLight)),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// class AppTheme {
//   // ── Base palette — warm navy-slate, much easier on the eyes ──────────
//   static const Color ink         = Color(0xFF111827); // warm dark navy
//   static const Color inkSoft     = Color(0xFF1A2233); // card backgrounds
//   static const Color inkMid      = Color(0xFF253047); // elevated surfaces
//   static const Color border      = Color(0xFF2D3A50); // subtle dividers
//   static const Color borderLight = Color(0xFF3B4D6A); // hover borders
//
//   // ── Text — warmer whites ──────────────────────────────────────────────
//   static const Color textColor = Color(0xFFE2E8F0); // soft white, not pure
//   static const Color textMuted = Color(0xFF8896B0); // readable muted
//   static const Color textDim   = Color(0xFF566480); // very dim, labels
//
//   // ── Card & surface ───────────────────────────────────────────────────
//   static const Color card     = Color(0xFF1A2233); // main card color
//   static const Color cardAlt  = Color(0xFF1F2B3E); // slightly different card
//
//   // ── Brand accent — softer teal ────────────────────────────────────────
//   static const Color accent  = Color(0xFF38BDF8); // sky blue (less neon)
//   static const Color blue    = Color(0xFF60A5FA); // soft blue
//   static const Color orange  = Color(0xFFFB923C); // warm orange
//   static const Color red     = Color(0xFFF87171); // soft red
//   static const Color yellow  = Color(0xFFFBBF24); // amber
//   static const Color green   = Color(0xFF34D399); // emerald
//   static const Color purple  = Color(0xFFA78BFA); // violet
//
//   // ── Dim versions ─────────────────────────────────────────────────────
//   static Color accentDim = accent.withOpacity(0.12);
//   static Color blueDim   = blue.withOpacity(0.12);
//   static Color orangeDim = orange.withOpacity(0.12);
//   static Color redDim    = red.withOpacity(0.12);
//   static Color yellowDim = yellow.withOpacity(0.12);
//   static Color greenDim  = green.withOpacity(0.12);
//   static Color purpleDim = purple.withOpacity(0.12);
//
//   // ── Semantic colors ───────────────────────────────────────────────────
//   static Color priorityColor(String p) {
//     switch (p) {
//       case 'Critical': return red;
//       case 'High':     return orange;
//       case 'Medium':   return yellow;
//       default:         return green;
//     }
//   }
//   static Color priorityBg(String p) => priorityColor(p).withOpacity(0.14);
//
//   static Color statusColor(String s) {
//     switch (s) {
//       case 'New':                return blue;
//       case 'In Progress':        return purple;
//       case 'Waiting for Client': return yellow;
//       case 'Resolved':           return green;
//       case 'Closed':             return textDim;
//       default:                   return textMuted;
//     }
//   }
//   static Color statusBg(String s) => statusColor(s).withOpacity(0.14);
//
//   static Color clientColor(String c) {
//     switch (c) {
//       case 'Ecocash':      return green;
//       case 'Econet':       return blue;
//       case 'CWS':          return orange;
//       case 'EMM':          return purple;
//       case 'EthioTelecom': return red;
//       default:             return textMuted;
//     }
//   }
//
//   // ── MaterialApp theme ─────────────────────────────────────────────────
//   static ThemeData get theme {
//     return ThemeData(
//       useMaterial3: true,
//       brightness: Brightness.dark,
//       scaffoldBackgroundColor: ink,
//       colorScheme: const ColorScheme.dark(
//         primary: accent,
//         secondary: blue,
//         surface: card,
//         error: red,
//         onPrimary: Color(0xFF0F172A),
//         onSurface: textColor,
//       ),
//       textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
//           .apply(bodyColor: textColor, displayColor: textColor),
//       appBarTheme: const AppBarTheme(
//         backgroundColor: inkSoft,
//         foregroundColor: textColor,
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//       ),
//       cardTheme: CardTheme(
//         color: card,
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//           side: const BorderSide(color: border),
//         ),
//         margin: EdgeInsets.zero,
//       ),
//       dividerColor: border,
//       dividerTheme: const DividerThemeData(color: border, space: 1),
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: inkSoft,
//         border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: const BorderSide(color: border)),
//         enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: const BorderSide(color: border)),
//         focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//             borderSide: const BorderSide(color: accent, width: 1.5)),
//         labelStyle: const TextStyle(color: textMuted, fontSize: 13),
//         hintStyle: const TextStyle(color: textDim, fontSize: 13),
//         contentPadding:
//         const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//       ),
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: accent,
//           foregroundColor: Color(0xFF0F172A),
//           elevation: 0,
//           padding:
//           const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
//           shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8)),
//           textStyle: GoogleFonts.inter(
//               fontSize: 14, fontWeight: FontWeight.w600),
//         ),
//       ),
//       outlinedButtonTheme: OutlinedButtonThemeData(
//         style: OutlinedButton.styleFrom(
//           foregroundColor: textMuted,
//           side: const BorderSide(color: border),
//           padding:
//           const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
//           shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8)),
//           textStyle: GoogleFonts.inter(
//               fontSize: 14, fontWeight: FontWeight.w500),
//         ),
//       ),
//       checkboxTheme: CheckboxThemeData(
//         fillColor: WidgetStateProperty.resolveWith((s) =>
//         s.contains(WidgetState.selected) ? accent : Colors.transparent),
//         checkColor:
//         WidgetStateProperty.all(const Color(0xFF0F172A)),
//         side: const BorderSide(color: borderLight),
//         shape:
//         RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
//       ),
//     );
//   }
// }