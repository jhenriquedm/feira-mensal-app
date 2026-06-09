import 'package:flutter/material.dart';

import 'views/home/home_view.dart';

class FeiraMensalApp extends StatelessWidget {
  const FeiraMensalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Feira Mensal',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const HomeView(),
    );
  }
}