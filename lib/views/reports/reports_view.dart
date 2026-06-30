import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/purchase_item_model.dart';
import '../../models/purchase_model.dart';
import '../../viewmodels/purchases_viewmodel.dart';

const String _allFilterValue = '__all__';

final NumberFormat _reportCurrencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
);

final DateFormat _reportDateFormatter = DateFormat('dd/MM/yyyy');
final DateFormat _reportPeriodKeyFormatter = DateFormat('yyyy-MM');

class ReportsView extends ConsumerStatefulWidget {
  const ReportsView({super.key});

  @override
  ConsumerState<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends ConsumerState<ReportsView> {
  String _selectedPeriod = _allFilterValue;
  String _selectedCategoryId = _allFilterValue;
  String _selectedProductId = _allFilterValue;
  _ReportGroupType _selectedGroupType = _ReportGroupType.categories;

  @override
  Widget build(BuildContext context) {
    final purchasesState = ref.watch(purchasesProvider);

    final allRecords = _buildRecords(purchasesState.purchases);
    final filteredRecords = _filterRecords(allRecords);
    final periodOptions = _buildPeriodOptions(purchasesState.purchases);
    final categoryOptions = _buildCategoryOptions(allRecords);
    final productOptions = _buildProductOptions(allRecords);
    final groupResults = _buildGroups(filteredRecords);

    final hasAnyFilter =
        _selectedPeriod != _allFilterValue ||
        _selectedCategoryId != _allFilterValue ||
        _selectedProductId != _allFilterValue;

    return Column(
      children: [
        _ReportsHeader(
          totalPurchases: purchasesState.purchases.length,
          totalRecords: allRecords.length,
        ),
        Expanded(
          child: allRecords.isEmpty
              ? const _EmptyReportsState()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  children: [
                    _ReportsFilterPanel(
                      selectedPeriod: _selectedPeriod,
                      selectedCategoryId: _selectedCategoryId,
                      selectedProductId: _selectedProductId,
                      periodOptions: periodOptions,
                      categoryOptions: categoryOptions,
                      productOptions: productOptions,
                      hasAnyFilter: hasAnyFilter,
                      onPeriodChanged: (value) {
                        setState(() {
                          _selectedPeriod = value;
                        });
                      },
                      onCategoryChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      onProductChanged: (value) {
                        setState(() {
                          _selectedProductId = value;
                        });
                      },
                      onClearFilters: () {
                        setState(() {
                          _selectedPeriod = _allFilterValue;
                          _selectedCategoryId = _allFilterValue;
                          _selectedProductId = _allFilterValue;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    if (filteredRecords.isEmpty)
                      const _NoFilteredResultsState()
                    else ...[
                      _MetricsGrid(records: filteredRecords),
                      const SizedBox(height: 18),
                      _GroupSelector(
                        selectedGroupType: _selectedGroupType,
                        onChanged: (value) {
                          setState(() {
                            _selectedGroupType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _GroupedReportList(
                        groupType: _selectedGroupType,
                        groups: groupResults,
                      ),
                      const SizedBox(height: 18),
                      _ReportItemsList(records: filteredRecords),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  List<_ReportRecord> _buildRecords(List<PurchaseModel> purchases) {
    final records = <_ReportRecord>[];

    for (final purchase in purchases) {
      for (final item in purchase.items) {
        records.add(
          _ReportRecord(
            purchaseId: purchase.id,
            purchaseName: purchase.name,
            market: purchase.market,
            purchaseDate: purchase.date,
            item: item,
          ),
        );
      }
    }

    records.sort((first, second) {
      final dateComparison = second.purchaseDate.compareTo(first.purchaseDate);

      if (dateComparison != 0) {
        return dateComparison;
      }

      return first.item.productName.compareTo(second.item.productName);
    });

    return records;
  }

  List<_ReportRecord> _filterRecords(List<_ReportRecord> records) {
    return records.where((record) {
      final periodMatches =
          _selectedPeriod == _allFilterValue ||
          _periodKey(record.purchaseDate) == _selectedPeriod;

      final categoryMatches =
          _selectedCategoryId == _allFilterValue ||
          record.item.categoryId == _selectedCategoryId;

      final productMatches =
          _selectedProductId == _allFilterValue ||
          record.item.productId == _selectedProductId;

      return periodMatches && categoryMatches && productMatches;
    }).toList();
  }

  List<_FilterOption> _buildPeriodOptions(List<PurchaseModel> purchases) {
    final periodMap = <String, String>{};

    for (final purchase in purchases) {
      if (purchase.items.isEmpty) {
        continue;
      }

      periodMap[_periodKey(purchase.date)] = _periodLabel(purchase.date);
    }

    final periodEntries = periodMap.entries.toList()
      ..sort((first, second) {
        return second.key.compareTo(first.key);
      });

    return [
      const _FilterOption(value: _allFilterValue, label: 'Todos os períodos'),
      ...periodEntries.map((entry) {
        return _FilterOption(value: entry.key, label: entry.value);
      }),
    ];
  }

  List<_FilterOption> _buildCategoryOptions(List<_ReportRecord> records) {
    final categoryMap = <String, String>{};

    for (final record in records) {
      categoryMap[record.item.categoryId] = record.item.categoryName;
    }

    final categoryEntries = categoryMap.entries.toList()
      ..sort((first, second) {
        return first.value.compareTo(second.value);
      });

    return [
      const _FilterOption(value: _allFilterValue, label: 'Todas as categorias'),
      ...categoryEntries.map((entry) {
        return _FilterOption(value: entry.key, label: entry.value);
      }),
    ];
  }

  List<_FilterOption> _buildProductOptions(List<_ReportRecord> records) {
    final productMap = <String, String>{};

    for (final record in records) {
      productMap[record.item.productId] = record.productLabel;
    }

    final productEntries = productMap.entries.toList()
      ..sort((first, second) {
        return first.value.compareTo(second.value);
      });

    return [
      const _FilterOption(value: _allFilterValue, label: 'Todos os produtos'),
      ...productEntries.map((entry) {
        return _FilterOption(value: entry.key, label: entry.value);
      }),
    ];
  }

  List<_ReportGroupResult> _buildGroups(List<_ReportRecord> records) {
    final groups = <String, _ReportGroupAccumulator>{};

    for (final record in records) {
      late final String key;
      late final String title;
      late final String subtitle;

      switch (_selectedGroupType) {
        case _ReportGroupType.purchases:
          key = record.purchaseId;
          title = record.purchaseName;
          subtitle =
              '${record.market} • ${_reportDateFormatter.format(record.purchaseDate)}';
          break;
        case _ReportGroupType.categories:
          key = record.item.categoryId;
          title = record.item.categoryName;
          subtitle = 'Categoria';
          break;
        case _ReportGroupType.products:
          key = record.item.productId;
          title = record.item.productName;
          subtitle =
              '${record.item.productBrand} • ${record.item.categoryName}';
          break;
      }

      final accumulator = groups.putIfAbsent(
        key,
        () => _ReportGroupAccumulator(title: title, subtitle: subtitle),
      );

      accumulator.add(record);
    }

    final result = groups.values.map((group) => group.toResult()).toList();

    result.sort((first, second) {
      return second.total.compareTo(first.total);
    });

    return result;
  }

  String _periodKey(DateTime date) {
    return _reportPeriodKeyFormatter.format(date);
  }

  String _periodLabel(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }
}

class _ReportsHeader extends StatelessWidget {
  final int totalPurchases;
  final int totalRecords;

  const _ReportsHeader({
    required this.totalPurchases,
    required this.totalRecords,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Relatórios',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Analise seus gastos por período, produto e categoria.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeaderInfoCard(
                  icon: Icons.receipt_long_rounded,
                  title: 'Compras',
                  value: totalPurchases.toString(),
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderInfoCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Itens lançados',
                  value: totalRecords.toString(),
                  foregroundColor: AppColors.success,
                  backgroundColor: AppColors.success.withValues(alpha: 0.10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color foregroundColor;
  final Color backgroundColor;

  const _HeaderInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(icon, color: foregroundColor, size: 22),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _ReportsFilterPanel extends StatelessWidget {
  final String selectedPeriod;
  final String selectedCategoryId;
  final String selectedProductId;
  final List<_FilterOption> periodOptions;
  final List<_FilterOption> categoryOptions;
  final List<_FilterOption> productOptions;
  final bool hasAnyFilter;
  final ValueChanged<String> onPeriodChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onProductChanged;
  final VoidCallback onClearFilters;

  const _ReportsFilterPanel({
    required this.selectedPeriod,
    required this.selectedCategoryId,
    required this.selectedProductId,
    required this.periodOptions,
    required this.categoryOptions,
    required this.productOptions,
    required this.hasAnyFilter,
    required this.onPeriodChanged,
    required this.onCategoryChanged,
    required this.onProductChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.filter_alt_outlined,
                  color: AppColors.primary,
                  size: 21,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filtros',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (hasAnyFilter)
                  TextButton(
                    onPressed: onClearFilters,
                    child: const Text('Limpar'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _ReportDropdownFilter(
              label: 'Período',
              value: selectedPeriod,
              options: periodOptions,
              onChanged: onPeriodChanged,
            ),
            const SizedBox(height: 10),
            _ReportDropdownFilter(
              label: 'Categoria',
              value: selectedCategoryId,
              options: categoryOptions,
              onChanged: onCategoryChanged,
            ),
            const SizedBox(height: 10),
            _ReportDropdownFilter(
              label: 'Produto',
              value: selectedProductId,
              options: productOptions,
              onChanged: onProductChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportDropdownFilter extends StatelessWidget {
  final String label;
  final String value;
  final List<_FilterOption> options;
  final ValueChanged<String> onChanged;

  const _ReportDropdownFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 260,
      borderRadius: BorderRadius.circular(18),
      dropdownColor: AppColors.surface,
      decoration: _reportInputDecoration(label),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option.value,
          child: Text(option.label, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (selectedValue) {
        if (selectedValue == null) {
          return;
        }

        onChanged(selectedValue);
      },
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final List<_ReportRecord> records;

  const _MetricsGrid({required this.records});

  @override
  Widget build(BuildContext context) {
    final total = records.fold<double>(
      0,
      (sum, record) => sum + record.item.total,
    );

    final purchasesCount = records
        .map((record) => record.purchaseId)
        .toSet()
        .length;

    final productsCount = records
        .map((record) => record.item.productId)
        .toSet()
        .length;

    final categoriesCount = records
        .map((record) => record.item.categoryId)
        .toSet()
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                icon: Icons.payments_outlined,
                label: 'Total gasto',
                value: _reportCurrencyFormatter.format(total),
                color: AppColors.primary,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                icon: Icons.receipt_long_outlined,
                label: 'Compras',
                value: purchasesCount.toString(),
                color: AppColors.success,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                icon: Icons.shopping_basket_outlined,
                label: 'Produtos',
                value: productsCount.toString(),
                color: AppColors.warning,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                icon: Icons.category_outlined,
                label: 'Categorias',
                value: categoriesCount.toString(),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
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
        ],
      ),
    );
  }
}

class _GroupSelector extends StatelessWidget {
  final _ReportGroupType selectedGroupType;
  final ValueChanged<_ReportGroupType> onChanged;

  const _GroupSelector({
    required this.selectedGroupType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: _ReportGroupType.values.map((type) {
            final isSelected = selectedGroupType == type;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    onChanged(type);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      type.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _GroupedReportList extends StatelessWidget {
  final _ReportGroupType groupType;
  final List<_ReportGroupResult> groups;

  const _GroupedReportList({required this.groupType, required this.groups});

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      title: groupType.sectionTitle,
      child: Column(
        children: groups.map((group) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _GroupReportCard(group: group),
          );
        }).toList(),
      ),
    );
  }
}

class _GroupReportCard extends StatelessWidget {
  final _ReportGroupResult group;

  const _GroupReportCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.bar_chart_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  group.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${group.itemsCount} itens • ${group.purchasesCount} compras',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _reportCurrencyFormatter.format(group.total),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportItemsList extends StatelessWidget {
  final List<_ReportRecord> records;

  const _ReportItemsList({required this.records});

  @override
  Widget build(BuildContext context) {
    return _ReportSection(
      title: 'Itens encontrados',
      child: Column(
        children: records.map((record) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ReportItemCard(record: record),
          );
        }).toList(),
      ),
    );
  }
}

class _ReportItemCard extends StatelessWidget {
  final _ReportRecord record;

  const _ReportItemCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shopping_basket_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  record.productLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _reportCurrencyFormatter.format(record.item.total),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${record.purchaseName} • ${record.market}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_reportDateFormatter.format(record.purchaseDate)} • '
            '${record.item.categoryName} • '
            '${_formatQuantity(record.item.quantity)} ${record.item.unit} x '
            '${_reportCurrencyFormatter.format(record.item.unitPrice)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReportSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _EmptyReportsState extends StatelessWidget {
  const _EmptyReportsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30, 30, 30, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(27),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhum dado para analisar',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Crie uma compra e adicione itens para visualizar os relatórios.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoFilteredResultsState extends StatelessWidget {
  const _NoFilteredResultsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 38,
            color: AppColors.textSecondary.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhum resultado encontrado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Altere os filtros para visualizar outros dados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRecord {
  final String purchaseId;
  final String purchaseName;
  final String market;
  final DateTime purchaseDate;
  final PurchaseItemModel item;

  const _ReportRecord({
    required this.purchaseId,
    required this.purchaseName,
    required this.market,
    required this.purchaseDate,
    required this.item,
  });

  String get productLabel {
    return '${item.productName} - ${item.productBrand}';
  }
}

class _ReportGroupAccumulator {
  final String title;
  final String subtitle;
  final Set<String> purchaseIds = {};
  double total = 0;
  int itemsCount = 0;

  _ReportGroupAccumulator({required this.title, required this.subtitle});

  void add(_ReportRecord record) {
    total += record.item.total;
    itemsCount++;
    purchaseIds.add(record.purchaseId);
  }

  _ReportGroupResult toResult() {
    return _ReportGroupResult(
      title: title,
      subtitle: subtitle,
      total: total,
      itemsCount: itemsCount,
      purchasesCount: purchaseIds.length,
    );
  }
}

class _ReportGroupResult {
  final String title;
  final String subtitle;
  final double total;
  final int itemsCount;
  final int purchasesCount;

  const _ReportGroupResult({
    required this.title,
    required this.subtitle,
    required this.total,
    required this.itemsCount,
    required this.purchasesCount,
  });
}

class _FilterOption {
  final String value;
  final String label;

  const _FilterOption({required this.value, required this.label});
}

enum _ReportGroupType { purchases, categories, products }

extension _ReportGroupTypeExtension on _ReportGroupType {
  String get label {
    switch (this) {
      case _ReportGroupType.purchases:
        return 'Compras';
      case _ReportGroupType.categories:
        return 'Categorias';
      case _ReportGroupType.products:
        return 'Produtos';
    }
  }

  String get sectionTitle {
    switch (this) {
      case _ReportGroupType.purchases:
        return 'Total por compra';
      case _ReportGroupType.categories:
        return 'Total por categoria';
      case _ReportGroupType.products:
        return 'Total por produto';
    }
  }
}

String _formatQuantity(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2).replaceAll('.', ',');
}

InputDecoration _reportInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    isDense: true,
    fillColor: AppColors.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
    ),
  );
}
