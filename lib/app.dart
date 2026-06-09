import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'views/main/main_shell.dart';
import 'widgets/app_mobile_frame.dart';

class FeiraMensalApp extends StatelessWidget {
  const FeiraMensalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Feira Mensal',
      theme: AppTheme.lightTheme,
      home: const AppMobileFrame(child: MainShell()),
    );
  }
}
