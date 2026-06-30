import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/purchase_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/products_viewmodel.dart';
import '../../viewmodels/purchases_viewmodel.dart';
import '../../widgets/app_feature_card.dart';

final NumberFormat _homeCurrencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
);

class HomeView extends ConsumerWidget {
  final VoidCallback? onProductsTap;
  final VoidCallback? onPurchasesTap;
  final VoidCallback? onReportsTap;

  const HomeView({
    super.key,
    this.onProductsTap,
    this.onPurchasesTap,
    this.onReportsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final productsState = ref.watch(productsProvider);
    final purchasesState = ref.watch(purchasesProvider);

    final firstName = _getFirstName(authState.currentUser?.name);

    final now = DateTime.now();

    final currentMonthPurchases = purchasesState.purchases.where((purchase) {
      return purchase.date.year == now.year && purchase.date.month == now.month;
    }).toList();

    final currentMonthTotal = currentMonthPurchases.fold<double>(
      0,
      (sum, purchase) => sum + purchase.total,
    );

    final totalItems = purchasesState.purchases.fold<int>(
      0,
      (sum, purchase) => sum + purchase.items.length,
    );

    final inProgressPurchases = purchasesState.purchases.where((purchase) {
      return !purchase.isCompleted;
    }).length;

    final latestPurchase = _latestPurchase(purchasesState.purchases);
    final topCategory = _topCategory(currentMonthPurchases);
    final averageTicket = currentMonthPurchases.isEmpty
        ? 0.0
        : currentMonthTotal / currentMonthPurchases.length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                context,
                firstName: firstName,
                currentMonthTotal: currentMonthTotal,
                inProgressPurchases: inProgressPurchases,
              ),
              const SizedBox(height: 24),
              _buildSummaryCard(
                context,
                currentMonthTotal: currentMonthTotal,
                productsCount: productsState.products.length,
                categoriesCount: productsState.categories.length,
              ),
              const SizedBox(height: 24),
              _buildDashboardSection(
                context,
                purchasesCount: purchasesState.purchases.length,
                totalItems: totalItems,
                averageTicket: averageTicket,
                latestPurchase: latestPurchase,
                topCategory: topCategory,
              ),
              const SizedBox(height: 28),
              Text(
                'Acessos rápidos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              AppFeatureCard(
                title: 'Produtos',
                subtitle: 'Cadastre e organize itens do mercado',
                icon: Icons.shopping_basket_outlined,
                onTap: onProductsTap ?? () {},
              ),
              const SizedBox(height: 12),
              AppFeatureCard(
                title: 'Compras',
                subtitle: 'Registre sua feira mensal',
                icon: Icons.receipt_long_outlined,
                onTap: onPurchasesTap ?? () {},
              ),
              const SizedBox(height: 12),
              AppFeatureCard(
                title: 'Relatórios',
                subtitle: 'Acompanhe gastos e evolução',
                icon: Icons.bar_chart_rounded,
                onTap: onReportsTap ?? () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required String? firstName,
    required double currentMonthTotal,
    required int inProgressPurchases,
  }) {
    final welcomeMessage = firstName == null
        ? 'Seja bem-vindo!'
        : 'Seja bem-vindo, $firstName!';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.waving_hand_rounded,
                  color: Colors.white,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    welcomeMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Controle sua feira com inteligência',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Organize produtos, acompanhe gastos e compare preços mês a mês.',
            style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeaderMetric(
                    title: 'Gasto no mês',
                    value: _homeCurrencyFormatter.format(currentMonthTotal),
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
                Expanded(
                  child: _HeaderMetric(
                    title: 'Em andamento',
                    value: inProgressPurchases.toString(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required double currentMonthTotal,
    required int productsCount,
    required int categoriesCount,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Row(
          children: [
            _summaryItem(
              context,
              title: 'Mês atual',
              value: _homeCurrencyFormatter.format(currentMonthTotal),
            ),
            _divider(),
            _summaryItem(
              context,
              title: 'Produtos',
              value: productsCount.toString(),
            ),
            _divider(),
            _summaryItem(
              context,
              title: 'Categorias',
              value: categoriesCount.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardSection(
    BuildContext context, {
    required int purchasesCount,
    required int totalItems,
    required double averageTicket,
    required PurchaseModel? latestPurchase,
    required _CategoryHighlight? topCategory,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resumo geral', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _DashboardCard(
                icon: Icons.receipt_long_outlined,
                title: 'Compras',
                value: purchasesCount.toString(),
                subtitle: 'Registradas',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashboardCard(
                icon: Icons.inventory_2_outlined,
                title: 'Itens',
                value: totalItems.toString(),
                subtitle: 'Adicionados',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DashboardCard(
                icon: Icons.payments_outlined,
                title: 'Ticket médio',
                value: _homeCurrencyFormatter.format(averageTicket),
                subtitle: 'Mês atual',
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashboardCard(
                icon: Icons.category_outlined,
                title: 'Top categoria',
                value: topCategory?.name ?? '-',
                subtitle: topCategory == null
                    ? 'Sem dados'
                    : _homeCurrencyFormatter.format(topCategory.total),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _LatestPurchaseCard(purchase: latestPurchase),
      ],
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(height: 38, width: 1, color: AppColors.border);
  }

  PurchaseModel? _latestPurchase(List<PurchaseModel> purchases) {
    if (purchases.isEmpty) {
      return null;
    }

    final sortedPurchases = [...purchases];

    sortedPurchases.sort((first, second) {
      return second.date.compareTo(first.date);
    });

    return sortedPurchases.first;
  }

  _CategoryHighlight? _topCategory(List<PurchaseModel> purchases) {
    final totals = <String, double>{};

    for (final purchase in purchases) {
      for (final item in purchase.items) {
        totals[item.categoryName] =
            (totals[item.categoryName] ?? 0) + item.total;
      }
    }

    if (totals.isEmpty) {
      return null;
    }

    final entries = totals.entries.toList()
      ..sort((first, second) {
        return second.value.compareTo(first.value);
      });

    final topEntry = entries.first;

    return _CategoryHighlight(name: topEntry.key, total: topEntry.value);
  }

  String? _getFirstName(String? fullName) {
    final name = fullName?.trim();

    if (name == null || name.isEmpty) {
      return null;
    }

    final firstName = name.split(RegExp(r'\s+')).first.trim();

    if (firstName.isEmpty) {
      return null;
    }

    return firstName;
  }
}

class _HeaderMetric extends StatelessWidget {
  final String title;
  final String value;

  const _HeaderMetric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestPurchaseCard extends StatelessWidget {
  final PurchaseModel? purchase;

  const _LatestPurchaseCard({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final hasPurchase = purchase != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: hasPurchase
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Última compra',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        purchase!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${purchase!.market} • ${_homeCurrencyFormatter.format(purchase!.total)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  )
                : const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Última compra',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Nenhuma compra registrada',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Cadastre sua primeira compra para visualizar aqui.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHighlight {
  final String name;
  final double total;

  const _CategoryHighlight({required this.name, required this.total});
}
