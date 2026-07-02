import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../services/local_storage_service.dart';

final themeProvider = StateNotifierProvider<ThemeViewModel, AppThemeState>((
  ref,
) {
  return ThemeViewModel();
});

class AppThemeState {
  final ThemeMode themeMode;
  final AppThemeColor themeColor;

  const AppThemeState({required this.themeMode, required this.themeColor});

  AppThemeState copyWith({ThemeMode? themeMode, AppThemeColor? themeColor}) {
    return AppThemeState(
      themeMode: themeMode ?? this.themeMode,
      themeColor: themeColor ?? this.themeColor,
    );
  }
}

class ThemeViewModel extends StateNotifier<AppThemeState> {
  ThemeViewModel()
    : super(
        const AppThemeState(
          themeMode: ThemeMode.light,
          themeColor: AppThemeColor.green,
        ),
      ) {
    _loadSavedThemeSettings();
  }

  Future<void> _loadSavedThemeSettings() async {
    final savedThemeMode = await LocalStorageService.loadThemeMode();
    final savedThemeColor = await LocalStorageService.loadThemeColor();

    final themeMode = savedThemeMode == ThemeMode.dark.name
        ? ThemeMode.dark
        : ThemeMode.light;

    final themeColor = parseAppThemeColor(savedThemeColor);

    state = state.copyWith(themeMode: themeMode, themeColor: themeColor);
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = state.copyWith(themeMode: themeMode);

    await LocalStorageService.saveThemeMode(themeMode.name);
  }

  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  Future<void> setThemeColor(AppThemeColor themeColor) async {
    state = state.copyWith(themeColor: themeColor);

    await LocalStorageService.saveThemeColor(themeColor.name);
  }
}
