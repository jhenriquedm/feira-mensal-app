import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class AppMobileFrame extends StatelessWidget {
  final Widget child;

  const AppMobileFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLargeScreen = constraints.maxWidth > 600;

        if (!isLargeScreen) {
          return child;
        }

        return Container(
          color: const Color(0xFFEFF3F6),
          alignment: Alignment.center,
          child: Container(
            width: 420,
            height: constraints.maxHeight * 0.94,
            constraints: const BoxConstraints(maxHeight: 900, minHeight: 640),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: AppColors.border, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        );
      },
    );
  }
}
