import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Builds the light and dark ThemeData from design tokens.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.primaryBright : AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: isDark ? AppColors.primaryDark : const Color(0xFFDDF2EC),
      onPrimaryContainer:
          isDark ? Colors.white : AppColors.primaryDark,
      secondary: isDark ? AppColors.primaryBright : AppColors.primaryDark,
      onSecondary: Colors.white,
      error: isDark ? AppColors.dangerDark : AppColors.danger,
      onError: Colors.white,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      onSurface: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      onSurfaceVariant:
          isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      outline: isDark ? AppColors.outlineDark : AppColors.outlineLight,
      outlineVariant: isDark ? AppColors.outlineDark : AppColors.outlineLight,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface:
          isDark ? AppColors.surfaceLight : AppColors.backgroundDark,
      onInverseSurface:
          isDark ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
      inversePrimary: AppColors.primary,
      tertiary: isDark ? AppColors.warningDark : AppColors.warning,
      onTertiary: Colors.white,
    );

    final textTheme = _textTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: isDark
              ? BorderSide(color: colorScheme.outline)
              : BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          side: BorderSide(color: colorScheme.primary),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip)),
        side: BorderSide(color: colorScheme.outline),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outline, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final base = GoogleFonts.interTextTheme();
    TextStyle s(TextStyle? t, double size, double height, FontWeight w,
            {double ls = 0, Color? color}) =>
        (t ?? const TextStyle()).copyWith(
          fontSize: size,
          height: height / size,
          fontWeight: w,
          letterSpacing: ls,
          color: color ?? scheme.onSurface,
        );

    return base.copyWith(
      displaySmall: s(base.displaySmall, 32, 38, FontWeight.w700),
      headlineMedium: s(base.headlineMedium, 24, 30, FontWeight.w700),
      titleLarge: s(base.titleLarge, 18, 24, FontWeight.w600),
      titleMedium: s(base.titleMedium, 16, 22, FontWeight.w600),
      bodyLarge: s(base.bodyLarge, 15, 22, FontWeight.w400),
      bodyMedium: s(base.bodyMedium, 14, 20, FontWeight.w400),
      labelLarge: s(base.labelLarge, 14, 18, FontWeight.w600, ls: 0.2),
      labelSmall: s(base.labelSmall, 12, 16, FontWeight.w500,
          color: scheme.onSurfaceVariant),
      bodySmall: s(base.bodySmall, 12, 16, FontWeight.w500,
          color: scheme.onSurfaceVariant),
    );
  }
}
