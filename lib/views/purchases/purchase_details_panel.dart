import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/product_model.dart';
import '../../models/purchase_item_model.dart';
import '../../models/purchase_model.dart';
import '../../viewmodels/products_viewmodel.dart';
import '../../viewmodels/purchases_viewmodel.dart';

final NumberFormat _detailsCurrencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
);

final DateFormat _detailsDateFormatter = DateFormat('dd/MM/yyyy');

class PurchaseDetailsPanel extends ConsumerStatefulWidget {
  final String purchaseId;
  final VoidCallback onClose;

  const PurchaseDetailsPanel({
    super.key,
    required this.purchaseId,
    required this.onClose,
  });

  @override
  ConsumerState<PurchaseDetailsPanel> createState() =>
      _PurchaseDetailsPanelState();
}

class _PurchaseDetailsPanelState extends ConsumerState<PurchaseDetailsPanel> {
  String? _feedbackMessage;
  bool _feedbackIsError = false;
  Timer? _feedbackTimer;
  final ScrollController _itemsScrollController = ScrollController();

  bool _isItemFormVisible = false;
  PurchaseItemModel? _itemBeingEdited;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _itemsScrollController.dispose();
    super.dispose();
  }

  PurchaseModel? _findPurchase(List<PurchaseModel> purchases) {
    for (final purchase in purchases) {
      if (purchase.id == widget.purchaseId) {
        return purchase;
      }
    }

    return null;
  }

  void _showLocalMessage(String message, {bool isError = false}) {
    _feedbackTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _feedbackMessage = message;
      _feedbackIsError = isError;
    });

    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _feedbackMessage = null;
        _feedbackIsError = false;
      });
    });
  }

  void _openCreateItemForm() {
    setState(() {
      _isItemFormVisible = true;
      _itemBeingEdited = null;
    });
  }

  void _openEditItemForm(PurchaseItemModel item) {
    setState(() {
      _isItemFormVisible = true;
      _itemBeingEdited = item;
    });
  }

  void _closeItemForm() {
    setState(() {
      _isItemFormVisible = false;
      _itemBeingEdited = null;
    });
  }

  void _deleteItem(PurchaseModel purchase, PurchaseItemModel item) {
    final success = ref
        .read(purchasesProvider.notifier)
        .deleteItem(purchaseId: purchase.id, itemId: item.id);

    if (!success) {
      _showLocalMessage(
        'Não foi possível remover o item desta compra.',
        isError: true,
      );
      return;
    }

    _showLocalMessage('Item removido com sucesso.');
  }

  void _togglePurchaseStatus(PurchaseModel purchase) {
    final viewModel = ref.read(purchasesProvider.notifier);

    if (purchase.isCompleted) {
      viewModel.reopenPurchase(purchase.id);
      _showLocalMessage('Compra reaberta com sucesso.');
      return;
    }

    viewModel.completePurchase(purchase.id);
    _showLocalMessage('Compra finalizada com sucesso.');
  }

  @override
  Widget build(BuildContext context) {
    final purchasesState = ref.watch(purchasesProvider);
    final productsState = ref.watch(productsProvider);

    final purchase = _findPurchase(purchasesState.purchases);

    if (purchase == null) {
      return const _DetailsShell(child: _PurchaseNotFoundState());
    }

    final sortedItems = [...purchase.items]
      ..sort((first, second) {
        final firstName = '${first.productName} ${first.productBrand}'
            .toLowerCase();
        final secondName = '${second.productName} ${second.productBrand}'
            .toLowerCase();

        return firstName.compareTo(secondName);
      });

    final activeProducts =
        productsState.products.where((product) => product.isActive).toList()
          ..sort((first, second) {
            final firstName = '${first.name} ${_productBrandLabel(first)}'
                .toLowerCase();
            final secondName = '${second.name} ${_productBrandLabel(second)}'
                .toLowerCase();

            return firstName.compareTo(secondName);
          });

    return _DetailsShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PurchaseDetailsHeader(purchase: purchase, onClose: widget.onClose),
          const SizedBox(height: 14),
          _PurchaseDetailsSummary(purchase: purchase),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _feedbackMessage == null
                ? const SizedBox.shrink()
                : _DetailsFeedbackMessage(
                    key: ValueKey<String>(_feedbackMessage!),
                    message: _feedbackMessage!,
                    isError: _feedbackIsError,
                  ),
          ),
          if (_isItemFormVisible) ...[
            const SizedBox(height: 12),
            _PurchaseItemForm(
              purchase: purchase,
              item: _itemBeingEdited,
              products: activeProducts,
              onCancel: _closeItemForm,
              onSaved: (message) {
                _closeItemForm();
                _showLocalMessage(message);
              },
              onError: (message) {
                _showLocalMessage(message, isError: true);
              },
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Itens da compra',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!purchase.isCompleted && !_isItemFormVisible)
                ElevatedButton.icon(
                  onPressed: activeProducts.isEmpty
                      ? null
                      : _openCreateItemForm,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Item'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (activeProducts.isEmpty && !purchase.isCompleted)
            const _NoProductsWarning()
          else if (sortedItems.isEmpty)
            const _EmptyItemsState()
          else
            _ScrollableItemsList(
              items: sortedItems,
              scrollController: _itemsScrollController,
              isPurchaseCompleted: purchase.isCompleted,
              onEdit: _openEditItemForm,
              onDelete: (item) {
                _deleteItem(purchase, item);
              },
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _togglePurchaseStatus(purchase);
              },
              icon: Icon(
                purchase.isCompleted
                    ? Icons.lock_open_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              label: Text(
                purchase.isCompleted ? 'Reabrir compra' : 'Finalizar compra',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsShell extends StatelessWidget {
  final Widget child;

  const _DetailsShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 372),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: SingleChildScrollView(child: child),
      ),
    );
  }
}

class _PurchaseDetailsHeader extends StatelessWidget {
  final PurchaseModel purchase;
  final VoidCallback onClose;

  const _PurchaseDetailsHeader({required this.purchase, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: purchase.isCompleted
                ? AppColors.success.withValues(alpha: 0.12)
                : AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            purchase.isCompleted
                ? Icons.check_circle_outline_rounded
                : Icons.shopping_cart_checkout_rounded,
            color: purchase.isCompleted ? AppColors.success : AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detalhes da compra',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                purchase.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Fechar',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _PurchaseDetailsSummary extends StatelessWidget {
  final PurchaseModel purchase;

  const _PurchaseDetailsSummary({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final statusColor = purchase.isCompleted
        ? AppColors.success
        : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryInfo(
                  icon: Icons.storefront_outlined,
                  label: 'Mercado',
                  value: purchase.market,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryInfo(
                  icon: Icons.calendar_today_outlined,
                  label: 'Data',
                  value: _detailsDateFormatter.format(purchase.date),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryInfo(
                  icon: Icons.category_outlined,
                  label: 'Tipo',
                  value: purchase.type.label,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryInfo(
                  icon: Icons.inventory_2_outlined,
                  label: 'Itens',
                  value: purchase.distinctItemsCount.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  purchase.status.label,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total da compra',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    _detailsCurrencyFormatter.format(purchase.total),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailsFeedbackMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const _DetailsFeedbackMessage({
    super.key,
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseItemForm extends ConsumerStatefulWidget {
  final PurchaseModel purchase;
  final PurchaseItemModel? item;
  final List<ProductModel> products;
  final VoidCallback onCancel;
  final ValueChanged<String> onSaved;
  final ValueChanged<String> onError;

  const _PurchaseItemForm({
    required this.purchase,
    required this.item,
    required this.products,
    required this.onCancel,
    required this.onSaved,
    required this.onError,
  });

  @override
  ConsumerState<_PurchaseItemForm> createState() => _PurchaseItemFormState();
}

class _PurchaseItemFormState extends ConsumerState<_PurchaseItemForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _productSearchController =
      TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();

  ProductModel? _selectedProduct;
  String? _formError;
  bool _showProductSuggestions = false;

  @override
  void initState() {
    super.initState();

    if (widget.item != null) {
      _quantityController.text = _formatNumber(widget.item!.quantity);
      _unitPriceController.text = _formatCurrencyInput(widget.item!.unitPrice);

      _selectedProduct = _findProductById(widget.item!.productId);

      if (_selectedProduct != null) {
        _productSearchController.text = _productOptionLabel(_selectedProduct!);
      }
    }
  }

  @override
  void dispose() {
    _productSearchController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  ProductModel? _findProductById(String productId) {
    for (final product in widget.products) {
      if (product.id == productId) {
        return product;
      }
    }

    return null;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  double? _parseNumber(String value) {
    final normalized = value.trim().replaceAll(',', '.');

    return double.tryParse(normalized);
  }

  double? _parseCurrency(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return null;
    }

    return int.parse(digits) / 100;
  }

  String _formatCurrencyInput(double value) {
    final cents = (value * 100).round().toString();
    return _formatCurrencyDigits(cents);
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    final query = _normalizeText(_productSearchController.text);

    if (query.isEmpty) {
      return products.take(8).toList();
    }

    return products
        .where((product) {
          final searchableText = _normalizeText(
            '${product.name} ${_productBrandLabel(product)}',
          );

          return searchableText.contains(query);
        })
        .take(8)
        .toList();
  }

  void _selectProduct(ProductModel product) {
    FocusScope.of(context).unfocus();

    setState(() {
      _selectedProduct = product;
      _productSearchController.text = _productOptionLabel(product);
      _showProductSuggestions = false;
      _formError = null;
    });
  }

  double get _currentTotal {
    final quantity = _parseNumber(_quantityController.text) ?? 0;
    final unitPrice = _parseCurrency(_unitPriceController.text) ?? 0;

    return quantity * unitPrice;
  }

  void _clearFormError() {
    if (_formError == null) {
      return;
    }

    setState(() {
      _formError = null;
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedProduct = _selectedProduct;

    if (selectedProduct == null) {
      setState(() {
        _formError = 'Selecione um produto para adicionar à compra.';
      });
      return;
    }

    final quantity = _parseNumber(_quantityController.text);
    final unitPrice = _parseCurrency(_unitPriceController.text);

    if (quantity == null || quantity <= 0) {
      setState(() {
        _formError = 'Informe uma quantidade maior que zero.';
      });
      return;
    }

    if (unitPrice == null || unitPrice < 0) {
      setState(() {
        _formError = 'Informe um preço unitário válido.';
      });
      return;
    }

    final productsViewModel = ref.read(productsProvider.notifier);
    final categoryName = productsViewModel.getCategoryName(
      selectedProduct.categoryId,
    );

    final productBrand = selectedProduct.brand?.trim().isNotEmpty == true
        ? selectedProduct.brand!.trim()
        : 'Sem marca';

    final purchasesViewModel = ref.read(purchasesProvider.notifier);

    final isEditing = widget.item != null;

    final success = isEditing
        ? purchasesViewModel.updateItem(
            purchaseId: widget.purchase.id,
            itemId: widget.item!.id,
            productId: selectedProduct.id,
            productName: selectedProduct.name,
            productBrand: productBrand,
            categoryId: selectedProduct.categoryId,
            categoryName: categoryName,
            unit: selectedProduct.unit,
            quantity: quantity,
            unitPrice: unitPrice,
          )
        : purchasesViewModel.addItem(
            purchaseId: widget.purchase.id,
            productId: selectedProduct.id,
            productName: selectedProduct.name,
            productBrand: productBrand,
            categoryId: selectedProduct.categoryId,
            categoryName: categoryName,
            unit: selectedProduct.unit,
            quantity: quantity,
            unitPrice: unitPrice,
          );

    if (!success) {
      widget.onError(
        isEditing
            ? 'Não foi possível atualizar o item.'
            : 'Este produto já foi adicionado nesta compra.',
      );
      return;
    }

    widget.onSaved(
      isEditing
          ? 'Item atualizado com sucesso.'
          : 'Item adicionado com sucesso.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableProducts = widget.products.where((product) {
      if (widget.item != null && product.id == widget.item!.productId) {
        return true;
      }

      return !widget.purchase.items.any((item) {
        return item.productId == product.id;
      });
    }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item == null ? 'Adicionar item' : 'Editar item',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FormField<ProductModel>(
              initialValue: _selectedProduct,
              validator: (value) {
                if (_selectedProduct == null) {
                  return 'Selecione um produto';
                }

                return null;
              },
              builder: (field) {
                final filteredProducts = _filterProducts(availableProducts);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _productSearchController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _detailsInputDecoration('Produto *').copyWith(
                        hintText: 'Digite para buscar',
                        suffixIcon: Icon(
                          _showProductSuggestions
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.search_rounded,
                        ),
                        errorText: field.errorText,
                      ),
                      onTap: () {
                        setState(() {
                          _showProductSuggestions = true;
                        });
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedProduct = null;
                          _showProductSuggestions = true;
                          _formError = null;
                        });

                        field.didChange(null);
                      },
                    ),
                    if (_showProductSuggestions) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 190),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: filteredProducts.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: Text(
                                  'Nenhum produto encontrado.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                itemCount: filteredProducts.length,
                                separatorBuilder: (context, index) {
                                  return const Divider(height: 1);
                                },
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];

                                  return ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    leading: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.shopping_basket_outlined,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                    ),
                                    title: Text(
                                      product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _productBrandLabel(product),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    onTap: () {
                                      _selectProduct(product);
                                      field.didChange(product);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                      LengthLimitingTextInputFormatter(5),
                    ],
                    decoration: _detailsInputDecoration('Quantidade *'),
                    onChanged: (_) {
                      _clearFormError();
                      setState(() {});
                    },
                    validator: (value) {
                      final parsed = _parseNumber(value ?? '');

                      if (parsed == null || parsed <= 0) {
                        return 'Inválida';
                      }

                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _unitPriceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _CurrencyInputFormatter(),
                    ],
                    decoration: _detailsInputDecoration(
                      'Preço un. *',
                    ).copyWith(prefixText: 'R\$ '),
                    onChanged: (_) {
                      _clearFormError();
                      setState(() {});
                    },
                    validator: (value) {
                      final parsed = _parseCurrency(value ?? '');

                      if (parsed == null || parsed < 0) {
                        return 'Inválido';
                      }

                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text(
                    'Total do item',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _detailsCurrencyFormatter.format(_currentTotal),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  _formError!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: availableProducts.isEmpty ? null : _submit,
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrollableItemsList extends StatelessWidget {
  final List<PurchaseItemModel> items;
  final ScrollController scrollController;
  final bool isPurchaseCompleted;
  final ValueChanged<PurchaseItemModel> onEdit;
  final ValueChanged<PurchaseItemModel> onDelete;

  const _ScrollableItemsList({
    required this.items,
    required this.scrollController,
    required this.isPurchaseCompleted,
    required this.onEdit,
    required this.onDelete,
  });

  double get _listHeight {
    if (items.length <= 1) {
      return 96;
    }

    if (items.length == 2) {
      return 202;
    }

    return 312;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _listHeight,
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: items.length > 3,
        radius: const Radius.circular(20),
        thickness: 4,
        child: ListView.separated(
          controller: scrollController,
          primary: false,
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (context, index) {
            return const SizedBox(height: 10);
          },
          itemBuilder: (context, index) {
            final item = items[index];

            return _PurchaseItemCard(
              item: item,
              isPurchaseCompleted: isPurchaseCompleted,
              onEdit: () {
                onEdit(item);
              },
              onDelete: () {
                onDelete(item);
              },
            );
          },
        ),
      ),
    );
  }
}

class _PurchaseItemCard extends StatelessWidget {
  final PurchaseItemModel item;
  final bool isPurchaseCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PurchaseItemCard({
    required this.item,
    required this.isPurchaseCompleted,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 8, 13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
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
              Icons.shopping_basket_outlined,
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
                  item.productName,
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
                  '${item.productBrand} • ${item.quantity} ${item.unit} • ${_detailsCurrencyFormatter.format(item.unitPrice)}',
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
                  _detailsCurrencyFormatter.format(item.total),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (!isPurchaseCompleted)
            PopupMenuButton<String>(
              tooltip: 'Opções do item',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                }

                if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) {
                return const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 10),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.danger,
                        ),
                        SizedBox(width: 10),
                        Text('Excluir'),
                      ],
                    ),
                  ),
                ];
              },
            ),
        ],
      ),
    );
  }
}

class _NoProductsWarning extends StatelessWidget {
  const _NoProductsWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
      ),
      child: const Text(
        'Cadastre produtos ativos antes de adicionar itens à compra.',
        style: TextStyle(
          color: AppColors.warning,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  const _EmptyItemsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 34,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nenhum item adicionado',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Adicione produtos para calcular o total da compra.',
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

class _PurchaseNotFoundState extends StatelessWidget {
  const _PurchaseNotFoundState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(22),
      child: Text(
        'Compra não encontrada.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _productBrandLabel(ProductModel product) {
  final brand = product.brand?.trim();

  if (brand == null || brand.isEmpty) {
    return 'Sem marca';
  }

  return brand;
}

String _productOptionLabel(ProductModel product) {
  return '${product.name} - ${_productBrandLabel(product)}';
}

String _normalizeText(String value) {
  return value.trim().toLowerCase();
}

String _formatCurrencyDigits(String digits) {
  if (digits.isEmpty) {
    return '';
  }

  final value = int.parse(digits) / 100;

  return NumberFormat.currency(
    locale: 'pt_BR',
    symbol: '',
    decimalDigits: 2,
  ).format(value).trim();
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formattedValue = _formatCurrencyDigits(digits);

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}

InputDecoration _detailsInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    isDense: true,
    fillColor: AppColors.surface,
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
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
    ),
  );
}
