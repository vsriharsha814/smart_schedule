import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _seed = Color(0xFF1A73E8);

  static final _lightScheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.light,
    primary: const Color(0xFF1A73E8),
    onPrimary: Colors.white,
    surface: const Color(0xFFFAFAFA),
    onSurface: const Color(0xFF202124),
    surfaceContainerHighest: const Color(0xFFF1F3F4),
    onSurfaceVariant: const Color(0xFF5F6368),
    outline: const Color(0xFFDADCE0),
  );

  static final _darkScheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.dark,
    primary: const Color(0xFF8AB4F8),
    onPrimary: const Color(0xFF062E6F),
    surface: const Color(0xFF1E1E1E),
    onSurface: const Color(0xFFE8EAED),
    surfaceContainerHighest: const Color(0xFF2D2D2D),
    onSurfaceVariant: const Color(0xFF9AA0A6),
    outline: const Color(0xFF3C4043),
  );

  static final light = ThemeData(
    colorScheme: _lightScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Colors.white,
      foregroundColor: _lightScheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(color: _lightScheme.outline.withOpacity(0.5)),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _lightScheme.outline),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (_) => const Icon(Icons.arrow_back),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
  );

  static final dark = ThemeData(
    colorScheme: _darkScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: const Color(0xFF121212),
      foregroundColor: _darkScheme.onSurface,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(color: _darkScheme.outline.withOpacity(0.5)),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _darkScheme.outline),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (_) => const Icon(Icons.arrow_back),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
  );
}

