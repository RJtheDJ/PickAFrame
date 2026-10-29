import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// Bar 5: Muted Zinc (`#71717A`) — spec labels, dashed borders, captions, footer.
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

/// Shared typography (`Poppins` across the entire system) and theme helpers.
abstract final class AppTheme {
  static const String fontFamily = 'Poppins';

  static bool _fontLoadStarted = false;

  /// Loads the official Google Fonts `Poppins` weights into Flutter's
  /// [FontLoader] so `Poppins` renders on every device without needing
  /// manual font asset setup. Safe to call offline (falls back silently).
  static Future<void> ensurePoppinsLoaded() async {
    if (_fontLoadStarted || kIsWeb) return;
    _fontLoadStarted = true;

    const urls = <String>[
      'https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Regular.ttf',
      'https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Medium.ttf',
      'https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-SemiBold.ttf',
      'https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Bold.ttf',
      'https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-ExtraBold.ttf',
    ];

    try {
      final loader = FontLoader(fontFamily);
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);

      for (final url in urls) {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode == 200) {
          final bytes = await consolidateHttpClientResponseBytes(response);
          loader.addFont(Future.value(ByteData.sublistView(bytes)));
        }
      }
      client.close();
      await loader.load();
    } catch (_) {
      // Offline or blocked: gracefully falls back to system Poppins / sans-serif.
    }
  }

  /// System-wide text style helper using `Poppins`.
  static TextStyle monoStyle({
    double fontSize = 10.5,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppPalette.mutedZinc,
    double letterSpacing = 0.2,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
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
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontSize: 13,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: fontFamily),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: fontFamily),
    );
  }
}
