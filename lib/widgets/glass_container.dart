import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:onyxfi_frontend/core/constants/colors.dart';
import 'package:onyxfi_frontend/core/theme/app_theme.dart';

/// ──────────────────────────────────────────────────────────
/// OnyxFi — Dark Glassmorphism Container
/// ──────────────────────────────────────────────────────────
/// Reusable glass panel: ClipRRect → BackdropFilter → Container
/// with low-opacity dark/white fills and subtle glowing borders.
/// ──────────────────────────────────────────────────────────
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderWidth;
  final Color? borderColor;
  final double? width;
  final double? height;
  final List<BoxShadow>? glowShadows;

  const GlassContainer({
    super.key,
    required this.child,
    this.blurSigma = AppTheme.blurMedium,
    this.opacity = 0.06,
    this.borderRadius = AppTheme.cardRadius,
    this.padding,
    this.margin,
    this.borderWidth = 1.0,
    this.borderColor,
    this.width,
    this.height,
    this.glowShadows,
  });

  /// Heavy variant for sidebars and modals — higher opacity, more blur.
  factory GlassContainer.heavy({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
  }) {
    return GlassContainer(
      blurSigma: AppTheme.blurHeavy,
      opacity: 0.10,
      borderRadius: AppTheme.sidebarRadius,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: glowShadows ?? [AppColors.glassShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppTheme.cardPadding),
            decoration: BoxDecoration(
              // Dark glass fill with subtle white tint
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: opacity + 0.02),
                  Colors.white.withValues(alpha: opacity),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? AppColors.frostBorder,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
