import 'package:flutter/material.dart';

class PurchasesView extends StatelessWidget {
  const PurchasesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderView(
      title: 'Compras',
      subtitle: 'Registre suas feiras mensais e acompanhe o total em tempo real.',
      icon: Icons.receipt_long_outlined,
    );
  }
}

class _PlaceholderView extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _PlaceholderView({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}