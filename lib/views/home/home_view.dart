import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_feature_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feira Mensal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildSummaryCard(context),
            const SizedBox(height: 24),
            Text(
              'Acessos rápidos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            AppFeatureCard(
              title: 'Produtos',
              subtitle: 'Cadastre e organize itens do mercado',
              icon: Icons.shopping_basket_outlined,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            AppFeatureCard(
              title: 'Compras',
              subtitle: 'Registre sua feira mensal em tempo real',
              icon: Icons.receipt_long_outlined,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            AppFeatureCard(
              title: 'Relatórios',
              subtitle: 'Acompanhe gastos, categorias e histórico',
              icon: Icons.bar_chart_rounded,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Controle sua feira com inteligência',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Organize produtos, acompanhe gastos e compare preços mês a mês.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _summaryItem(
              context,
              title: 'Mês atual',
              value: 'R\$ 0,00',
            ),
            _divider(),
            _summaryItem(
              context,
              title: 'Itens',
              value: '0',
            ),
            _divider(),
            _summaryItem(
              context,
              title: 'Categorias',
              value: '0',
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(
    BuildContext context, {
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 36,
      width: 1,
      color: AppColors.border,
    );
  }
}