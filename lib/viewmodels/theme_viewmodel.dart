import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_storage_service.dart';

final themeProvider = StateNotifierProvider<ThemeViewModel, ThemeMode>((ref) {
  return ThemeViewModel();
});

class ThemeViewModel extends StateNotifier<ThemeMode> {
  ThemeViewModel() : super(ThemeMode.light) {
    _loadSavedThemeMode();
  }

  Future<void> _loadSavedThemeMode() async {
    final savedThemeMode = await LocalStorageService.loadThemeMode();

    if (savedThemeMode == ThemeMode.dark.name) {
      state = ThemeMode.dark;
      return;
    }

    state = ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = themeMode;

    await LocalStorageService.saveThemeMode(themeMode.name);
  }

  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }
}
