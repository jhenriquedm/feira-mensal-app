import 'package:flutter/material.dart';

void main() {
  runApp(const FeiraMensalApp());
}

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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feira Mensal'),
      ),
      body: const Center(
        child: Text(
          'Projeto iniciado 🚀',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}