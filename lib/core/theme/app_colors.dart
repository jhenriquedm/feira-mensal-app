import 'package:flutter/material.dart';

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
    return primary.withValues(alpha: isDark(context) ? 0.20 : 0.12);
  }

  static Color primarySoftBackground(BuildContext context) {
    return primary.withValues(alpha: isDark(context) ? 0.18 : 0.10);
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
