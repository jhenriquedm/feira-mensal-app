import 'package:flutter/material.dart';

enum AppThemeColor { green, blue, purple, orange, rose }

extension AppThemeColorExtension on AppThemeColor {
  String get label {
    switch (this) {
      case AppThemeColor.green:
        return 'Verde';
      case AppThemeColor.blue:
        return 'Azul';
      case AppThemeColor.purple:
        return 'Roxo';
      case AppThemeColor.orange:
        return 'Laranja';
      case AppThemeColor.rose:
        return 'Rosa';
    }
  }

  Color get primary {
    switch (this) {
      case AppThemeColor.green:
        return const Color(0xFF16A34A);
      case AppThemeColor.blue:
        return const Color(0xFF2563EB);
      case AppThemeColor.purple:
        return const Color(0xFF7C3AED);
      case AppThemeColor.orange:
        return const Color(0xFFF97316);
      case AppThemeColor.rose:
        return const Color(0xFFE11D48);
    }
  }

  Color get primaryDark {
    switch (this) {
      case AppThemeColor.green:
        return const Color(0xFF15803D);
      case AppThemeColor.blue:
        return const Color(0xFF1D4ED8);
      case AppThemeColor.purple:
        return const Color(0xFF6D28D9);
      case AppThemeColor.orange:
        return const Color(0xFFEA580C);
      case AppThemeColor.rose:
        return const Color(0xFFBE123C);
    }
  }
}

AppThemeColor parseAppThemeColor(String? value) {
  return AppThemeColor.values.firstWhere(
    (color) => color.name == value,
    orElse: () => AppThemeColor.green,
  );
}

class AppColors {
  static const Color primary = Color(0xFF16A34A);
  static const Color primaryDark = Color(0xFF15803D);
  static const Color secondary = Color(0xFFF59E0B);

  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const Color border = Color(0xFFE5E7EB);

  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceSoft = Color(0xFF1F2937);

  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);

  static const Color darkBorder = Color(0xFF334155);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color primaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color primaryDarkColor(BuildContext context) {
    final currentPrimary = primaryColor(context);

    return Color.alphaBlend(
      Colors.black.withValues(alpha: 0.14),
      currentPrimary,
    );
  }

  static Color backgroundColor(BuildContext context) {
    return isDark(context) ? darkBackground : background;
  }

  static Color surfaceColor(BuildContext context) {
    return isDark(context) ? darkSurface : surface;
  }

  static Color surfaceSoftColor(BuildContext context) {
    return isDark(context) ? darkSurfaceSoft : const Color(0xFFF3F4F6);
  }

  static Color textPrimaryColor(BuildContext context) {
    return isDark(context) ? darkTextPrimary : textPrimary;
  }

  static Color textSecondaryColor(BuildContext context) {
    return isDark(context) ? darkTextSecondary : textSecondary;
  }

  static Color borderColor(BuildContext context) {
    return isDark(context) ? darkBorder : border;
  }

  static Color selectedPrimaryBackground(BuildContext context) {
    return primaryColor(
      context,
    ).withValues(alpha: isDark(context) ? 0.20 : 0.12);
  }

  static Color primarySoftBackground(BuildContext context) {
    return primaryColor(
      context,
    ).withValues(alpha: isDark(context) ? 0.18 : 0.10);
  }

  static Color successSoftBackground(BuildContext context) {
    return success.withValues(alpha: isDark(context) ? 0.18 : 0.10);
  }

  static Color warningSoftBackground(BuildContext context) {
    return warning.withValues(alpha: isDark(context) ? 0.18 : 0.10);
  }

  static Color dangerSoftBackground(BuildContext context) {
    return danger.withValues(alpha: isDark(context) ? 0.18 : 0.10);
  }

  static Color overlayColor(BuildContext context) {
    return Colors.black.withValues(alpha: isDark(context) ? 0.54 : 0.34);
  }
}
