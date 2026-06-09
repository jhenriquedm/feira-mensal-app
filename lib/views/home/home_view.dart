import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feira Mensal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(
              context,
              title: 'Produtos',
              subtitle: 'Cadastrar produtos',
              icon: Icons.shopping_basket_outlined,
            ),
            const SizedBox(height: 12),
            _buildCard(
              context,
              title: 'Compras',
              subtitle: 'Registrar feira mensal',
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 12),
            _buildCard(
              context,
              title: 'Relatórios',
              subtitle: 'Consultar histórico',
              icon: Icons.bar_chart_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          icon,
          size: 36,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {},
      ),
    );
  }
}