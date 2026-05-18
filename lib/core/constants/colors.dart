import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────
/// OnyxFi — Midnight Ledger Design System: Color Tokens
/// ──────────────────────────────────────────────────────────
/// High-Contrast Dark Glassmorphism color palette.
/// Every color in the app is referenced from this single file.
/// ──────────────────────────────────────────────────────────

class AppColors {
  AppColors._(); // Non-instantiable

  // ── Backgrounds & Surfaces ─────────────────────────────
  /// The deep base background behind all glass elements.
  static const Color midnightInk = Color(0xFF0A0E1A);

  /// Slightly elevated surface for cards and panels.
  static const Color obsidianSurface = Color(0xFF12162A);

  /// Subtle raised surface for secondary panels.
  static const Color deepSlate = Color(0xFF1A1F35);

  /// Glass card fill — dark translucent white.
  static Color glassHeavy = Colors.white.withValues(alpha: 0.08);

  /// Light glass fill for secondary elements.
  static Color glassLight = Colors.white.withValues(alpha: 0.04);

  /// Critical border for glass elements — subtle glow.
  static Color frostBorder = Colors.white.withValues(alpha: 0.12);

  // ── Typography Colors ──────────────────────────────────
  /// Primary headings, active states — near-white for contrast.
  static const Color snowWhite = Color(0xFFF0F2F5);

  /// Secondary body text.
  static const Color silverMist = Color(0xFFB0B8C8);

  /// Tertiary text, placeholders, inactive icons.
  static const Color stoneGrey = Color(0xFF6B7280);

  // ── Accents ────────────────────────────────────────────
  /// Primary accent — Electric Blue for CTAs and active states.
  static const Color electricBlue = Color(0xFF3B82F6);

  /// Electric Blue subtle glow for hover/active backgrounds.
  static Color electricBlueSubtle = const Color(0xFF3B82F6).withValues(alpha: 0.12);

  /// Success / Growth accent — Growth Mint.
  static const Color growthMint = Color(0xFF10B981);

  /// Warning / Risk accent — Amber Flame.
  static const Color amberFlame = Color(0xFFF59E0B);

  /// Danger / Critical — Crimson Pulse.
  static const Color crimsonPulse = Color(0xFFEF4444);

  /// Solid white for text on accents.
  static const Color solidWhite = Color(0xFFFFFFFF);

  // ── Shadows & Overlays ─────────────────────────────────
  /// Soft shadow for glass elevation.
  static BoxShadow glassShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.3),
    blurRadius: 32,
    offset: const Offset(0, 8),
  );

  /// Glow shadow for Electric Blue accents.
  static BoxShadow electricGlow = BoxShadow(
    color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
    blurRadius: 24,
    offset: const Offset(0, 4),
  );

  /// Glow shadow for Growth Mint accents.
  static BoxShadow mintGlow = BoxShadow(
    color: const Color(0xFF10B981).withValues(alpha: 0.2),
    blurRadius: 20,
    offset: const Offset(0, 4),
  );

  /// Legibility overlay for backgrounds.
  static Color legibilityOverlay = Colors.black.withValues(alpha: 0.4);

  /// Subtle active state pill background for nav items.
  static Color electricBlueActive = const Color(0xFF3B82F6).withValues(alpha: 0.15);

  // ── Gradients ──────────────────────────────────────────
  /// Premium dark gradient for main backgrounds.
  static const LinearGradient midnightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0E1A),
      Color(0xFF0F1529),
      Color(0xFF0A0E1A),
    ],
  );

  /// Accent gradient for primary buttons.
  static const LinearGradient electricGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6),
      Color(0xFF2563EB),
    ],
  );

  /// Subtle mesh gradient hint for glass cards.
  static LinearGradient glassMeshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.06),
      Colors.white.withValues(alpha: 0.02),
      Colors.white.withValues(alpha: 0.04),
    ],
  );
}
