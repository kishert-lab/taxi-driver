import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return _theme(
      brightness: Brightness.light,
      seedColor: const Color(0xFF0B8457),
      surface: const Color(0xFFF7F8FA),
    );
  }

  static ThemeData dark() {
    return _theme(
      brightness: Brightness.dark,
      seedColor: const Color(0xFF31C48D),
      surface: const Color(0xFF111827),
    );
  }

  static ThemeData _theme({
    required Brightness brightness,
    required Color seedColor,
    required Color surface,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      appBarTheme: const AppBarTheme(centerTitle: false),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }
}
