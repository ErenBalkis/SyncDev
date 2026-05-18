import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────
/// OnyxFi — Ambient Transparent Glass Design System: Color Tokens
/// ──────────────────────────────────────────────────────────
/// Deep Black & Solar Orange glassmorphism palette.
/// Every color in the app is referenced from this single file.
/// ──────────────────────────────────────────────────────────

class AppColors {
  AppColors._(); // Non-instantiable

  // ── Backgrounds & Surfaces ─────────────────────────────
  /// The deep base background behind all glass elements.
  static const Color midnightInk = Color(0xFF0A0000);

  /// Slightly elevated surface for cards and panels.
  static const Color obsidianSurface = Color(0xFF120400);

  /// Subtle raised surface for secondary panels.
  static const Color deepSlate = Color(0xFF1A0800);

  /// Glass card fill — highly transparent white.
  static Color glassHeavy = Colors.white.withValues(alpha: 0.08);

  /// Light glass fill for secondary elements.
  static Color glassLight = Colors.white.withValues(alpha: 0.05);

  /// Critical border for glass elements — defines the frost edge on dark bg.
  static Color frostBorder = Colors.white.withValues(alpha: 0.20);

  // ── Typography Colors ──────────────────────────────────
  /// Primary headings, active states — pure white for maximum contrast on dark bg.
  static const Color snowWhite = Color(0xFFFFFFFF);

  /// Secondary body text — frosted white at 70% opacity.
  static Color silverMist = Colors.white.withValues(alpha: 0.70);

  /// Tertiary text, placeholders, inactive icons — muted white.
  static Color stoneGrey = Colors.white.withValues(alpha: 0.45);

  // ── Accents ────────────────────────────────────────────
  /// Primary accent — Solar Orange for CTAs, active states, and chart lines.
  static const Color solarOrange = Color(0xFFFF7A00);

  /// Solar Orange subtle glow for hover/active backgrounds.
  static Color solarOrangeSubtle = const Color(0xFFFF7A00).withValues(alpha: 0.15);

  /// Solar Orange active pill background for nav items.
  static Color solarOrangeActive = const Color(0xFFFF7A00).withValues(alpha: 0.15);

  /// Success / Growth accent — Growth Mint.
  static const Color growthMint = Color(0xFF10B981);

  /// Warning / Risk accent — Amber Flame.
  static const Color amberFlame = Color(0xFFF59E0B);

  /// Danger / Critical — Crimson Pulse.
  static const Color crimsonPulse = Color(0xFFEF4444);

  /// Solid white for text placed on top of Solar Orange elements.
  static const Color solidWhite = Color(0xFFFFFFFF);

  // ── Shadows & Overlays ─────────────────────────────────
  /// Soft shadow for glass elevation.
  static BoxShadow glassShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.30),
    blurRadius: 32,
    offset: const Offset(0, 8),
  );

  /// Glow shadow for Solar Orange accents.
  static BoxShadow orangeGlow = BoxShadow(
    color: const Color(0xFFFF7A00).withValues(alpha: 0.30),
    blurRadius: 24,
    offset: const Offset(0, 4),
  );

  /// Subtle inner glow for selected/active Solar Orange elements.
  static BoxShadow orangeGlowSubtle = BoxShadow(
    color: const Color(0xFFFF7A00).withValues(alpha: 0.18),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );

  /// Glow shadow for Growth Mint accents.
  static BoxShadow mintGlow = BoxShadow(
    color: const Color(0xFF10B981).withValues(alpha: 0.2),
    blurRadius: 20,
    offset: const Offset(0, 4),
  );

  /// Legibility overlay placed directly above the dynamic background image.
  /// Kept moderate so the background is still visible through transparent glass.
  static Color legibilityOverlay = Colors.black.withValues(alpha: 0.40);

  // ── Gradients ──────────────────────────────────────────
  /// Fallback gradient used when background image fails to load.
  /// Deep black with a warm orange-tinted undertone.
  static const LinearGradient midnightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0000),
      Color(0xFF1A0500),
      Color(0xFF0A0000),
    ],
  );

  /// Primary button gradient — Solar Orange.
  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF7A00),
      Color(0xFFE06000),
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

  // ── Ambient Glow Overlays (for background layers) ──────
  /// Top-right Solar Orange ambient glow overlay.
  static RadialGradient ambientOrangeGlowTopRight = RadialGradient(
    center: Alignment.topRight,
    radius: 1.2,
    colors: [
      const Color(0xFFFF7A00).withValues(alpha: 0.35),
      Colors.transparent,
    ],
  );

  /// Bottom-left dimmer Solar Orange ambient glow overlay.
  static RadialGradient ambientOrangeGlowBottomLeft = RadialGradient(
    center: Alignment.bottomLeft,
    radius: 1.0,
    colors: [
      const Color(0xFFFF4500).withValues(alpha: 0.18),
      Colors.transparent,
    ],
  );
}
