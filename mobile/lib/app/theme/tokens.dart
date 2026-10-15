import 'package:flutter/material.dart';

/// AI Diet Coach design tokens — single source of truth for the design system.
/// See docs/design/design-system.md.
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF168B72);
  static const primaryDark = Color(0xFF106D5B);
  static const primaryBright = Color(0xFF2BAA8E); // dark-mode primary

  // Backgrounds / surfaces
  static const backgroundLight = Color(0xFFF7FAF9);
  static const backgroundDark = Color(0xFF0B1420);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF13202E);

  // Text
  static const textPrimaryLight = Color(0xFF17212B);
  static const textPrimaryDark = Color(0xFFECF2F1);
  static const textSecondaryLight = Color(0xFF64748B);
  static const textSecondaryDark = Color(0xFF93A3B5);

  // Semantic
  static const success = Color(0xFF16A34A);
  static const successDark = Color(0xFF34C06A);
  static const warning = Color(0xFFD97706);
  static const warningDark = Color(0xFFED9B3C);
  static const danger = Color(0xFFDC2626);
  static const dangerDark = Color(0xFFEF5350);

  // Lines
  static const outlineLight = Color(0xFFE2E8F0);
  static const outlineDark = Color(0xFF223246);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal screen gutter.
  static const double gutter = 20;
}

abstract final class AppRadius {
  static const double card = 20;
  static const double button = 14;
  static const double input = 14;
  static const double chip = 999;

  static final BorderRadius cardRadius = BorderRadius.circular(card);
  static final BorderRadius buttonRadius = BorderRadius.circular(button);
  static final BorderRadius inputRadius = BorderRadius.circular(input);
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}

abstract final class AppShadows {
  static const soft = [
    BoxShadow(
      color: Color(0x0F0B1420), // rgba(11,20,32,0.06)
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}

/// Minimum accessible touch target.
const double kMinTouchTarget = 48;
