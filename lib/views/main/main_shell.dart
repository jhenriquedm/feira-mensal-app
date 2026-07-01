import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../home/home_view.dart';
import '../products/products_view.dart';
import '../purchases/purchases_view.dart';
import '../reports/reports_view.dart';
import '../settings/settings_view.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  List<Widget> get _pages {
    return [
      HomeView(
        onProductsTap: () => _onTap(1),
        onPurchasesTap: () => _onTap(2),
        onReportsTap: () => _onTap(3),
      ),
      const ProductsView(),
      const PurchasesView(),
      const ReportsView(),
      const SettingsView(),
    ];
  }

  void _onTap(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      appBar: null,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor(context),
        border: Border(top: BorderSide(color: AppColors.borderColor(context))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navItem(index: 0, icon: Icons.home_rounded, label: 'Home'),
            _navItem(
              index: 1,
              icon: Icons.shopping_basket_rounded,
              label: 'Produtos',
            ),
            _navItem(
              index: 2,
              icon: Icons.receipt_long_rounded,
              label: 'Compras',
            ),
            _navItem(
              index: 3,
              icon: Icons.bar_chart_rounded,
              label: 'Relatórios',
            ),
            _navItem(index: 4, icon: Icons.settings_rounded, label: 'Ajustes'),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _selectedIndex == index;

    final unselectedColor = AppColors.textSecondaryColor(context);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.selectedPrimaryBackground(context)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 23,
                color: isSelected ? AppColors.primary : unselectedColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
