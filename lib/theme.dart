import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFFD4622A); // terracotta
  static const Color primaryLight = Color(0xFFE8845A);
  static const Color primaryDark  = Color(0xFFB04A1A);

  static const Color secondary    = Color(0xFF4A7C59); // herb green
  static const Color secondaryLight = Color(0xFF6A9E76);

  static const Color accent       = Color(0xFFF5C842); // saffron yellow
  static const Color accentDark   = Color(0xFFD4A82A);

  static const Color background   = Color(0xFFFDF6EE); // warm cream
  static const Color surface      = Color(0xFFFFF9F2);
  static const Color surfaceCard  = Color(0xFFFFFFFF);

  static const Color textPrimary  = Color(0xFF2C1810);
  static const Color textSecondary= Color(0xFF7A5C4E);
  static const Color textHint     = Color(0xFFB89080);

  static const Color divider      = Color(0xFFEDD9C8);
  static const Color error        = Color(0xFFD64545);
  static const Color success      = Color(0xFF4A7C59);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFD4622A), Color(0xFFE8A87C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFF9F2), Color(0xFFFDF0E0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Typography ────────────────────────────────────────────────────────────
  static TextTheme get textTheme => TextTheme(
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 48, fontWeight: FontWeight.w700, color: textPrimary, height: 1.1,
    ),
    displayMedium: GoogleFonts.playfairDisplay(
      fontSize: 36, fontWeight: FontWeight.w700, color: textPrimary, height: 1.2,
    ),
    displaySmall: GoogleFonts.playfairDisplay(
      fontSize: 28, fontWeight: FontWeight.w600, color: textPrimary, height: 1.3,
    ),
    headlineLarge: GoogleFonts.playfairDisplay(
      fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary,
    ),
    headlineMedium: GoogleFonts.playfairDisplay(
      fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary,
    ),
    headlineSmall: GoogleFonts.playfairDisplay(
      fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
    ),
    bodyLarge: GoogleFonts.lato(
      fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary, height: 1.6,
    ),
    bodyMedium: GoogleFonts.lato(
      fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary, height: 1.5,
    ),
    bodySmall: GoogleFonts.lato(
      fontSize: 12, fontWeight: FontWeight.w400, color: textHint,
    ),
    labelLarge: GoogleFonts.lato(
      fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5,
    ),
    labelMedium: GoogleFonts.lato(
      fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.3,
    ),
    labelSmall: GoogleFonts.lato(
      fontSize: 11, fontWeight: FontWeight.w500, color: textHint, letterSpacing: 0.5,
    ),
  );

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryLight,
      onPrimaryContainer: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFD0EAD8),
      onSecondaryContainer: secondary,
      tertiary: accent,
      onTertiary: textPrimary,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: background,
      onSurfaceVariant: textSecondary,
      outline: divider,
      outlineVariant: const Color(0xFFF0DDD0),
      shadow: textPrimary.withValues(alpha: 0.08),
      scrim: Colors.black,
      inverseSurface: textPrimary,
      onInverseSurface: surface,
    ),
    scaffoldBackgroundColor: background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: divider, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      hintStyle: GoogleFonts.lato(color: textHint, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: background,
      selectedColor: primary.withValues(alpha: 0.12),
      labelStyle: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w500),
      side: const BorderSide(color: divider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceCard,
      selectedItemColor: primary,
      unselectedItemColor: textHint,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: const DividerThemeData(color: divider, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimary,
      contentTextStyle: GoogleFonts.lato(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
