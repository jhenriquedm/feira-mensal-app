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

  final List<Widget> _pages = const [
    HomeView(),
    ProductsView(),
    PurchasesView(),
    ReportsView(),
    SettingsView(),
  ];

  final List<String> _titles = const [
    'Feira Mensal',
    'Produtos',
    'Compras',
    'Relatórios',
    'Configurações',
  ];

  void _onTap(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  bool get _shouldHideAppBar {
    return _selectedIndex == 0 || _selectedIndex == 1 || _selectedIndex == 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _shouldHideAppBar
          ? null
          : AppBar(title: Text(_titles[_selectedIndex])),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
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

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 23,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
