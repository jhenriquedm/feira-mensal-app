import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/theme_viewmodel.dart';
import 'views/auth/auth_view.dart';
import 'views/main/main_shell.dart';
import 'widgets/app_mobile_frame.dart';

class FeiraMensalApp extends ConsumerWidget {
  const FeiraMensalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeColor = themeState.themeColor;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Feira Fácil',
      theme: AppTheme.lightTheme(
        primaryColor: themeColor.primary,
        primaryDarkColor: themeColor.primaryDark,
      ),
      darkTheme: AppTheme.darkTheme(
        primaryColor: themeColor.primary,
        primaryDarkColor: themeColor.primaryDark,
      ),
      themeMode: themeState.themeMode,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const AppMobileFrame(child: _AuthLoadingView());
    }

    if (!authState.isAuthenticated) {
      return const AppMobileFrame(child: AuthView());
    }

    return const AppMobileFrame(child: MainShell());
  }
}

class _AuthLoadingView extends StatelessWidget {
  const _AuthLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
