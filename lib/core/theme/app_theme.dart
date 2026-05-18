import 'package:flutter/material.dart';
import 'package:onyxfi_frontend/core/constants/colors.dart';

/// ──────────────────────────────────────────────────────────
/// OnyxFi — Midnight Ledger Theme
/// ──────────────────────────────────────────────────────────
/// Full ThemeData implementation for the High-Contrast Dark
/// Glassmorphism design system.
///
/// Typography Scale:
///   caption    : 12px / 1.5  / -0.007px
///   body-sm    : 14px / 1.43 / -0.013px
///   body       : 16px / 1.38 / -0.02px
///   subheading : 20px / 1.33 / -0.022px
///   heading    : 32px / 1.25 / -0.025px
///
/// Font: Inter (Google Fonts)
/// Weights: 400 (Body), 500 (Buttons/Labels), 600 (Headings), 700 (Balances)
/// ──────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  // ── Font Family ────────────────────────────────────────
  static const String _fontFamily = 'Inter';

  // ── Spacing Constants ──────────────────────────────────
  static const double cardPadding = 24.0;
  static const double cardPaddingLarge = 32.0;
  static const double elementGapSmall = 8.0;
  static const double elementGap = 16.0;

  // ── Border Radius ──────────────────────────────────────
  static const double cardRadius = 20.0;
  static const double pillRadius = 9999.0;
  static const double sidebarRadius = 24.0;

  // ── Blur Values ────────────────────────────────────────
  static const double blurMedium = 16.0;
  static const double blurHeavy = 24.0;

  // ── Custom Text Styles (Midnight Ledger Type Scale) ────
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    height: 1.5,
    letterSpacing: -0.007,
    fontWeight: FontWeight.w400,
    color: AppColors.stoneGrey,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    height: 1.43,
    letterSpacing: -0.013,
    fontWeight: FontWeight.w400,
    color: AppColors.silverMist,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    height: 1.38,
    letterSpacing: -0.02,
    fontWeight: FontWeight.w400,
    color: AppColors.silverMist,
  );

  static const TextStyle subheading = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    height: 1.33,
    letterSpacing: -0.022,
    fontWeight: FontWeight.w600,
    color: AppColors.snowWhite,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    height: 1.25,
    letterSpacing: -0.025,
    fontWeight: FontWeight.w700,
    color: AppColors.snowWhite,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    height: 1.38,
    letterSpacing: -0.02,
    fontWeight: FontWeight.w600,
    color: AppColors.solidWhite,
  );

  static const TextStyle balanceText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    height: 1.25,
    letterSpacing: -0.025,
    fontWeight: FontWeight.w700,
    color: AppColors.snowWhite,
  );

  // ── ThemeData ──────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,

      // ── Scaffold ────────────────────────────────────
      scaffoldBackgroundColor: AppColors.midnightInk,

      // ── Color Scheme ────────────────────────────────
      colorScheme: const ColorScheme.dark(
        primary: AppColors.electricBlue,
        onPrimary: AppColors.solidWhite,
        secondary: AppColors.growthMint,
        onSecondary: AppColors.solidWhite,
        surface: AppColors.obsidianSurface,
        onSurface: AppColors.snowWhite,
        error: AppColors.crimsonPulse,
        onError: AppColors.solidWhite,
      ),

      // ── AppBar ──────────────────────────────────────
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.snowWhite,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.022,
          color: AppColors.snowWhite,
        ),
      ),

      // ── Text Theme ─────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: heading,
        displayMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 28,
          height: 1.28,
          letterSpacing: -0.025,
          fontWeight: FontWeight.w700,
          color: AppColors.snowWhite,
        ),
        displaySmall: subheading,
        headlineLarge: heading,
        headlineMedium: subheading,
        headlineSmall: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          height: 1.35,
          letterSpacing: -0.02,
          fontWeight: FontWeight.w600,
          color: AppColors.snowWhite,
        ),
        titleLarge: subheading,
        titleMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          height: 1.38,
          letterSpacing: -0.02,
          fontWeight: FontWeight.w500,
          color: AppColors.snowWhite,
        ),
        titleSmall: bodySm,
        bodyLarge: body,
        bodyMedium: bodySm,
        bodySmall: caption,
        labelLarge: buttonLabel,
        labelMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          height: 1.43,
          letterSpacing: -0.013,
          fontWeight: FontWeight.w500,
          color: AppColors.snowWhite,
        ),
        labelSmall: caption,
      ),

      // ── Elevated Button ─────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricBlue,
          foregroundColor: AppColors.solidWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          textStyle: buttonLabel,
        ),
      ),

      // ── Outlined Button (Ghost / Glass Button) ──────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.snowWhite,
          side: BorderSide(color: AppColors.frostBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          textStyle: buttonLabel.copyWith(color: AppColors.snowWhite),
        ),
      ),

      // ── Text Button ────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.electricBlue,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input Decoration ────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassLight,
        hintStyle: bodySm.copyWith(color: AppColors.stoneGrey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(pillRadius),
          borderSide: BorderSide(color: AppColors.frostBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(pillRadius),
          borderSide: BorderSide(color: AppColors.frostBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(pillRadius),
          borderSide: const BorderSide(color: AppColors.electricBlue, width: 2),
        ),
      ),

      // ── Card ────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.glassHeavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: AppColors.frostBorder, width: 1.5),
        ),
        margin: const EdgeInsets.all(0),
      ),

      // ── Icon ────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.stoneGrey,
        size: 24,
      ),

      // ── Divider ─────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: AppColors.frostBorder,
        thickness: 1,
        space: 32,
      ),

      // ── Bottom Navigation Bar ───────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.electricBlue,
        unselectedItemColor: AppColors.stoneGrey,
        selectedLabelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
