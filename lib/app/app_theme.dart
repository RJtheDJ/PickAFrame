import 'package:flutter/material.dart';

/// Color palette extracted from `mae_colorPalette` (Coolors) paired with a
/// clean architectural light surface for the PickAFrame UI.
abstract final class AppPalette {
  // --- 5 Core Palette Colors from Image 2 (`mae_colorPalette`) ---

  /// Bar 1: Dark Charcoal (`#1E2229`) — dark accents, frame shadow bar, strong borders.
  static const Color darkCharcoal = Color(0xFF1E2229);

  /// Bar 2: Obsidian Black (`#090A0C`) — primary CTA button fill, primary headings, logo box.
  static const Color obsidianBlack = Color(0xFF090A0C);

  /// Bar 3: Midnight Slate (`#2C3E50`) — technical badges, step pills, specialty tags.
  static const Color midnightSlate = Color(0xFF2C3E50);

  /// Bar 4: Cool Slate Grey (`#4B5563`) — body copy, secondary button text, active icons.
  static const Color coolSlate = Color(0xFF4B5563);

  /// Bar 5: Muted Zinc (`#71717A`) — monospace spec labels, dashed borders, captions, footer.
  static const Color mutedZinc = Color(0xFF71717A);

  // --- Clean Light Canvas & Architectural Surfaces ---

  /// Main page background.
  static const Color background = Color(0xFFFFFFFF);

  /// Subtle off-white surface for secondary cards and preview mat area.
  static const Color surfaceLight = Color(0xFFF8FAFC);

  /// Soft slate-tinted surface for badges, step number boxes, and partner banner.
  /// Derived as a 9% tint of [midnightSlate] on white.
  static const Color slateTintSurface = Color(0xFFEEF2F7);

  /// Hairline border grey derived from [mutedZinc] / [coolSlate].
  static const Color borderLight = Color(0xFFD4D8DF);

  /// Stronger card border for buttons and inputs.
  static const Color borderMedium = Color(0xFF9CA3AF);
}

/// Shared typography and theme helpers for PickAFrame screens.
abstract final class AppTheme {
  static const String monoFontFamily = 'monospace';

  static TextStyle monoStyle({
    double fontSize = 10.5,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppPalette.mutedZinc,
    double letterSpacing = 0.6,
    double? height,
  }) {
    return TextStyle(
      fontFamily: monoFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppPalette.background,
      colorScheme: const ColorScheme.light(
        primary: AppPalette.obsidianBlack,
        onPrimary: Colors.white,
        secondary: AppPalette.midnightSlate,
        onSecondary: Colors.white,
        surface: AppPalette.background,
        onSurface: AppPalette.obsidianBlack,
        outline: AppPalette.coolSlate,
      ),
      dividerColor: AppPalette.borderLight,
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppPalette.darkCharcoal,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
