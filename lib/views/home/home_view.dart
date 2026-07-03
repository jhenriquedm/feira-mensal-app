import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/purchase_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/products_viewmodel.dart';
import '../../viewmodels/purchases_viewmodel.dart';

final NumberFormat _homeCurrencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
);

final DateFormat _homeDateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm');

class HomeView extends ConsumerStatefulWidget {
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
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  String? _feedbackMessage;
  bool _feedbackIsError = false;
  bool _isSyncingNow = false;
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: AppColors.backgroundColor(context),
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
              const SizedBox(height: 14),
              _buildConnectionStatusCard(
                context,
                authState: authState,
                productsState: productsState,
                purchasesState: purchasesState,
                isSyncingNow: _isSyncingNow,
                onSyncNow: _syncNow,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _feedbackMessage == null
                    ? const SizedBox(height: 24)
                    : Padding(
                        key: ValueKey<String>(_feedbackMessage!),
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        child: _HomeFeedback(
                          message: _feedbackMessage!,
                          isError: _feedbackIsError,
                        ),
                      ),
              ),
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimaryColor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _HomeFeatureCard(
                title: 'Produtos',
                subtitle: 'Cadastre e organize itens do mercado',
                icon: Icons.shopping_basket_outlined,
                onTap: widget.onProductsTap ?? () {},
              ),
              const SizedBox(height: 12),
              _HomeFeatureCard(
                title: 'Compras',
                subtitle: 'Registre sua feira mensal',
                icon: Icons.receipt_long_outlined,
                onTap: widget.onPurchasesTap ?? () {},
              ),
              const SizedBox(height: 12),
              _HomeFeatureCard(
                title: 'Relatórios',
                subtitle: 'Acompanhe gastos e evolução',
                icon: Icons.bar_chart_rounded,
                onTap: widget.onReportsTap ?? () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _syncNow() async {
    if (_isSyncingNow) {
      return;
    }

    final authState = ref.read(authProvider);

    if (authState.isOfflineMode) {
      _showFeedback(
        message: 'Conecte-se à internet para sincronizar os dados.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSyncingNow = true;
    });

    try {
      await ref.read(productsProvider.notifier).syncNow();
      await ref.read(purchasesProvider.notifier).syncNow();

      if (!mounted) {
        return;
      }

      final productsState = ref.read(productsProvider);
      final purchasesState = ref.read(purchasesProvider);
      final pendingCount =
          productsState.pendingSyncCount + purchasesState.pendingSyncCount;

      if (pendingCount == 0) {
        _showFeedback(
          message: 'Sincronização concluída com sucesso.',
          isError: false,
        );
      } else {
        _showFeedback(
          message:
              'Ainda existem alterações pendentes. Verifique sua conexão e tente novamente.',
          isError: true,
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showFeedback(
        message: 'Não foi possível sincronizar agora. Tente novamente.',
        isError: true,
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSyncingNow = false;
      });
    }
  }

  void _showFeedback({required String message, required bool isError}) {
    _feedbackTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _feedbackMessage = message;
      _feedbackIsError = isError;
    });

    _feedbackTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _feedbackMessage = null;
        _feedbackIsError = false;
      });
    });
  }

  Widget _buildHeader(
    BuildContext context, {
    required String? firstName,
    required double currentMonthTotal,
    required int inProgressPurchases,
  }) {
    final primaryColor = AppColors.primaryColor(context);
    final primaryDarkColor = AppColors.primaryDarkColor(context);

    final welcomeMessage = firstName == null
        ? 'Seja bem-vindo!'
        : 'Seja bem-vindo, $firstName!';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryDarkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(
              alpha: AppColors.isDark(context) ? 0.18 : 0.25,
            ),
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

  Widget _buildConnectionStatusCard(
    BuildContext context, {
    required AuthState authState,
    required ProductsState productsState,
    required PurchasesState purchasesState,
    required bool isSyncingNow,
    required VoidCallback onSyncNow,
  }) {
    final session = authState.offlineSession;
    final isOfflineMode = authState.isOfflineMode;
    final pendingProductsCount = productsState.pendingSyncCount;
    final pendingPurchasesCount = purchasesState.pendingSyncCount;
    final pendingItemsCount = pendingProductsCount + pendingPurchasesCount;
    final hasPendingChanges = pendingItemsCount > 0;
    final lastSyncedAt = _latestSyncDate(productsState, purchasesState);

    final Color statusColor;
    final IconData statusIcon;
    final String title;
    final String subtitle;
    final String badgeLabel;

    if (isOfflineMode) {
      statusColor = AppColors.warning;
      statusIcon = Icons.wifi_off_rounded;
      title = 'Modo offline';
      subtitle = hasPendingChanges
          ? 'Você está offline e possui alterações aguardando sincronização.'
          : 'Você está usando os dados salvos neste dispositivo.';
      badgeLabel = 'Offline';
    } else if (hasPendingChanges) {
      statusColor = AppColors.warning;
      statusIcon = Icons.sync_problem_rounded;
      title = 'Alterações pendentes';
      subtitle = 'Existem dados locais aguardando sincronização com a nuvem.';
      badgeLabel = 'Pendente';
    } else {
      statusColor = AppColors.success;
      statusIcon = Icons.cloud_done_outlined;
      title = 'Tudo sincronizado';
      subtitle = 'Sua conta está online e os dados estão atualizados na nuvem.';
      badgeLabel = 'Sincronizado';
    }

    final pendingText = pendingItemsCount == 1
        ? '1 alteração pendente'
        : '$pendingItemsCount alterações pendentes';

    final lastSyncText = lastSyncedAt == null
        ? 'Última sincronização: ainda não registrada'
        : 'Última sincronização: ${_homeDateTimeFormatter.format(lastSyncedAt)}';

    final lastAccessText = session == null
        ? 'Último acesso: agora'
        : 'Último acesso: ${_homeDateTimeFormatter.format(session.lastAccessAt)}';

    final lastOnlineLoginText = session == null
        ? 'Último login online: não registrado'
        : 'Último login online: ${_homeDateTimeFormatter.format(session.lastOnlineLoginAt)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: statusColor.withValues(
          alpha: AppColors.isDark(context) ? 0.14 : 0.08,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: statusColor.withValues(
            alpha: AppColors.isDark(context) ? 0.30 : 0.18,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(
                alpha: AppColors.isDark(context) ? 0.18 : 0.10,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: AppColors.isDark(context) ? 0.18 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  softWrap: true,
                  style: TextStyle(
                    color: AppColors.textSecondaryColor(context),
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasPendingChanges
                      ? pendingText
                      : 'Nenhuma alteração pendente',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lastSyncText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondaryColor(context),
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lastAccessText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondaryColor(context),
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lastOnlineLoginText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondaryColor(context),
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isOfflineMode || isSyncingNow ? null : onSyncNow,
                    icon: isSyncingNow
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                    label: Text(
                      isSyncingNow ? 'Sincronizando...' : 'Sincronizar agora',
                    ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Row(
        children: [
          _summaryItem(
            context,
            title: 'Mês atual',
            value: _homeCurrencyFormatter.format(currentMonthTotal),
          ),
          _divider(context),
          _summaryItem(
            context,
            title: 'Produtos',
            value: productsCount.toString(),
          ),
          _divider(context),
          _summaryItem(
            context,
            title: 'Categorias',
            value: categoriesCount.toString(),
          ),
        ],
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
    final primaryColor = AppColors.primaryColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo geral',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimaryColor(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _DashboardCard(
                icon: Icons.receipt_long_outlined,
                title: 'Compras',
                value: purchasesCount.toString(),
                subtitle: 'Registradas',
                color: primaryColor,
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
                color: AppColors.secondary,
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      height: 38,
      width: 1,
      color: AppColors.borderColor(context),
    );
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

  DateTime? _latestSyncDate(
    ProductsState productsState,
    PurchasesState purchasesState,
  ) {
    final syncDates = [
      productsState.lastSyncedAt,
      purchasesState.lastSyncedAt,
    ].whereType<DateTime>().toList();

    if (syncDates.isEmpty) {
      return null;
    }

    syncDates.sort((first, second) {
      return second.compareTo(first);
    });

    return syncDates.first;
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

class _HomeFeedback extends StatelessWidget {
  final String message;
  final bool isError;

  const _HomeFeedback({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(
            alpha: AppColors.isDark(context) ? 0.34 : 0.25,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
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
        color: AppColors.surfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: AppColors.isDark(context) ? 0.18 : 0.10,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondaryColor(context),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
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
            style: TextStyle(
              color: AppColors.textSecondaryColor(context),
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
    final primaryColor = AppColors.primaryColor(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
      decoration: BoxDecoration(
        color: primaryColor.withValues(
          alpha: AppColors.isDark(context) ? 0.13 : 0.08,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: primaryColor.withValues(
            alpha: AppColors.isDark(context) ? 0.28 : 0.18,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: primaryColor.withValues(
                alpha: AppColors.isDark(context) ? 0.18 : 0.12,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.history_rounded, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: hasPurchase
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Última compra',
                        style: TextStyle(
                          color: AppColors.textSecondaryColor(context),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        purchase!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimaryColor(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${purchase!.market} • ${_homeCurrencyFormatter.format(purchase!.total)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondaryColor(context),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Última compra',
                        style: TextStyle(
                          color: AppColors.textSecondaryColor(context),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Nenhuma compra registrada',
                        style: TextStyle(
                          color: AppColors.textPrimaryColor(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Cadastre sua primeira compra para visualizar aqui.',
                        style: TextStyle(
                          color: AppColors.textSecondaryColor(context),
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

class _HomeFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primaryColor(context);

    return Material(
      color: AppColors.surfaceColor(context),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderColor(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primarySoftBackground(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimaryColor(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondaryColor(context),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondaryColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryHighlight {
  final String name;
  final double total;

  const _CategoryHighlight({required this.name, required this.total});
}
