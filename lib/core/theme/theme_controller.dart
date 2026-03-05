import 'package:flutter/material.dart';

import '../persistence/settings_store.dart';

/// Controls app ThemeMode and persists it via SettingsStore.
class ThemeController {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const _themeKey = 'theme_mode';

  final SettingsStore _settings = SettingsStore();
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  Future<void> load() async {
    final stored = await _settings.getString(_themeKey);
    switch (stored) {
      case 'light':
        themeMode.value = ThemeMode.light;
        break;
      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;
      case 'system':
      default:
        themeMode.value = ThemeMode.system;
        break;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _settings.setString(_themeKey, value);
  }
}

