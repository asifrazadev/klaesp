import 'package:flutter/material.dart';

/// KLAESP brand colors. Values are estimated from the brand sheet;
/// confirm them against the source design file before release.
class KlaespColors {
  KlaespColors._();

  static const navy = Color(0xFF0B1F4B);
  static const electricBlue = Color(0xFF2563EB);
  static const skyBlue = Color(0xFF5B9BFF);
  static const skyBlueHover = Color(0xFF7DB0FF);

  // Light theme
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF4F7FC);
  static const lightSecondaryText = Color(0xFF4A5878);
  static const lightBorder = Color(0xFFD9E1F0);
  static const lightAccentHover = Color(0xFF1D4FBF);

  // Dark theme
  static const darkBackground = Color(0xFF0A1430);
  static const darkSurface = Color(0xFF121E40);
  static const darkText = Color(0xFFF4F7FC);
  static const darkSecondaryText = Color(0xFFA9B6D3);
  static const darkBorder = Color(0xFF22325E);
}

class KlaespTheme {
  KlaespTheme._();

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: KlaespColors.electricBlue,
      onPrimary: Colors.white,
      secondary: KlaespColors.navy,
      onSecondary: Colors.white,
      error: Color(0xFFB3261E),
      onError: Colors.white,
      surface: KlaespColors.lightBackground,
      onSurface: KlaespColors.navy,
    );

    return _build(
      scheme: scheme,
      scaffoldBackground: KlaespColors.lightBackground,
      appBarBackground: KlaespColors.navy,
      appBarForeground: Colors.white,
      border: KlaespColors.lightBorder,
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: KlaespColors.skyBlue,
      onPrimary: KlaespColors.darkBackground,
      secondary: KlaespColors.darkSecondaryText,
      onSecondary: KlaespColors.darkBackground,
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: KlaespColors.darkBackground,
      onSurface: KlaespColors.darkText,
    );

    return _build(
      scheme: scheme,
      scaffoldBackground: KlaespColors.darkBackground,
      appBarBackground: KlaespColors.darkSurface,
      appBarForeground: KlaespColors.darkText,
      border: KlaespColors.darkBorder,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color scaffoldBackground,
    required Color appBarBackground,
    required Color appBarForeground,
    required Color border,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
