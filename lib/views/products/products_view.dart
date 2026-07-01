import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../viewmodels/products_viewmodel.dart';
import '../../viewmodels/purchases_viewmodel.dart';

typedef ProductsFeedbackCallback =
    void Function(String message, {bool isError});

class _ProductsMessages {
  static const productCreated = 'Produto cadastrado com sucesso.';
  static const productUpdated = 'Produto atualizado com sucesso.';
  static const productDeleted = 'Produto excluído com sucesso.';
  static const productDuplicate =
      'Já existe um produto cadastrado com esse nome e marca.';
  static const productDeleteBlocked =
      'Este produto não pode ser excluído porque já foi usado em uma compra.';
  static const productLinkedInfo =
      'Este produto já foi usado em uma compra. Para preservar o histórico, altere apenas Ativo/Inativo.';
  static const productRequiredFields =
      'Preencha todos os campos obrigatórios do produto.';

  static const categoryCreated = 'Categoria cadastrada com sucesso.';
  static const categoryUpdated = 'Categoria atualizada com sucesso.';
  static const categoryDeleted = 'Categoria excluída com sucesso.';
  static const categoryDuplicate =
      'Já existe uma categoria cadastrada com esse nome.';
  static const categoryDeleteBlocked =
      'Esta categoria não pode ser excluída porque possui produtos vinculados.';
}

class ProductsView extends ConsumerStatefulWidget {
  const ProductsView({super.key});

  @override
  ConsumerState<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends ConsumerState<ProductsView> {
  int _selectedTabIndex = 0;

  String? _feedbackMessage;
  bool _feedbackIsError = false;
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _showFeedback(String message, {bool isError = false}) {
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsProvider);
    final linkedProductIds = ref.watch(productIdsLinkedToPurchasesProvider);
    final viewModel = ref.read(productsProvider.notifier);

    return Stack(
      children: [
        Column(
          children: [
            _ProductsHeader(
              selectedTabIndex: _selectedTabIndex,
              productsCount: state.products.length,
              categoriesCount: state.categories.length,
              onTabChanged: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  _ProductsTab(
                    state: state,
                    viewModel: viewModel,
                    linkedProductIds: linkedProductIds,
                    onFeedback: _showFeedback,
                  ),
                  _CategoriesTab(
                    state: state,
                    viewModel: viewModel,
                    onFeedback: _showFeedback,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_feedbackMessage != null)
          Positioned(
            left: 18,
            right: 18,
            bottom: 88,
            child: IgnorePointer(
              child: _ProductsLocalFeedback(
                message: _feedbackMessage!,
                isError: _feedbackIsError,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductsHeader extends StatelessWidget {
  final int selectedTabIndex;
  final int productsCount;
  final int categoriesCount;
  final ValueChanged<int> onTabChanged;

  const _ProductsHeader({
    required this.selectedTabIndex,
    required this.productsCount,
    required this.categoriesCount,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor(context),
        border: Border(
          bottom: BorderSide(color: AppColors.borderColor(context)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produtos',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Cadastre produtos e organize suas categorias.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ProductsHeaderChip(
                  icon: Icons.shopping_basket_outlined,
                  label: 'Produtos',
                  value: productsCount,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProductsHeaderChip(
                  icon: Icons.category_outlined,
                  label: 'Categorias',
                  value: categoriesCount,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ManualSegmentedTabs(
            selectedIndex: selectedTabIndex,
            onChanged: onTabChanged,
          ),
        ],
      ),
    );
  }
}

class _ProductsHeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _ProductsHeaderChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(alpha: AppColors.isDark(context) ? 0.22 : 0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
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

class _ManualSegmentedTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _ManualSegmentedTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoftColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Row(
        children: [
          _ManualTabButton(
            label: 'Produtos',
            selected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
          _ManualTabButton(
            label: 'Categorias',
            selected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _ManualTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ManualTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.surfaceColor(context) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondaryColor(context),
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  final ProductsState state;
  final ProductsViewModel viewModel;
  final Set<String> linkedProductIds;
  final ProductsFeedbackCallback onFeedback;

  const _ProductsTab({
    required this.state,
    required this.viewModel,
    required this.linkedProductIds,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    final products = viewModel.sortedProducts;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: products.isEmpty
          ? const _EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'Nenhum produto cadastrado',
              subtitle:
                  'Cadastre produtos para montar suas compras mensais com mais rapidez.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              itemCount: products.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 10);
              },
              itemBuilder: (context, index) {
                final product = products[index];
                final isLinked = linkedProductIds.contains(product.id);

                return _ProductListCard(
                  product: product,
                  categoryName: viewModel.getCategoryName(product.categoryId),
                  isLinked: isLinked,
                  onEdit: () {
                    _showProductDialog(
                      context,
                      state,
                      viewModel,
                      linkedProductIds,
                      product: product,
                    );
                  },
                  onDelete: () {
                    if (!viewModel.canDeleteProduct(
                      product.id,
                      linkedProductIds: linkedProductIds,
                    )) {
                      onFeedback(
                        _ProductsMessages.productDeleteBlocked,
                        isError: true,
                      );
                      return;
                    }

                    Future<void>.delayed(const Duration(milliseconds: 160), () {
                      viewModel.deleteProduct(product.id);
                      onFeedback(_ProductsMessages.productDeleted);
                    });
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Adicionar produto',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          _showProductDialog(context, state, viewModel, linkedProductIds);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showProductDialog(
    BuildContext rootContext,
    ProductsState state,
    ProductsViewModel viewModel,
    Set<String> linkedProductIds, {
    ProductModel? product,
  }) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: product?.name ?? '');
    final brandController = TextEditingController(text: product?.brand ?? '');

    String? selectedCategoryId = product?.categoryId;
    String? selectedUnit = product?.unit;
    bool isActive = product?.isActive ?? true;

    String? dialogMessage;
    bool dialogMessageIsError = true;

    final isLinked = product != null && linkedProductIds.contains(product.id);

    final categories = _availableCategoriesForProduct(
      state: state,
      viewModel: viewModel,
      selectedCategoryId: selectedCategoryId,
    );

    final units = ['Caixa', 'g', 'Kg', 'Litro', 'ml', 'Pacote', 'Unidade']
      ..sort();

    try {
      final result = await showDialog<_ProductDialogResult>(
        context: rootContext,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              void showDialogMessage(String message, {bool isError = true}) {
                setState(() {
                  dialogMessage = message;
                  dialogMessageIsError = isError;
                });
              }

              return AlertDialog(
                backgroundColor: AppColors.surfaceColor(context),
                surfaceTintColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: AppColors.borderColor(context)),
                ),
                title: Text(
                  product == null ? 'Novo produto' : 'Editar produto',
                  style: TextStyle(
                    color: AppColors.textPrimaryColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                content: SizedBox(
                  width: 300,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (dialogMessage != null) ...[
                            _DialogFeedback(
                              message: dialogMessage!,
                              isError: dialogMessageIsError,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (isLinked) ...[
                            const _LinkedProductWarning(),
                            const SizedBox(height: 12),
                          ],
                          _premiumTextField(
                            context,
                            controller: nameController,
                            label: 'Nome do produto',
                            hint: 'Ex: Café',
                            maxLength: 30,
                            requiredMessage: 'Informe o nome do produto',
                            enabled: !isLinked,
                          ),
                          const SizedBox(height: 12),
                          _premiumTextField(
                            context,
                            controller: brandController,
                            label: 'Marca',
                            hint: 'Ex: Pilão',
                            maxLength: 30,
                            requiredMessage: 'Informe a marca',
                            enabled: !isLinked,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: selectedCategoryId,
                            isExpanded: true,
                            menuMaxHeight: 260,
                            dropdownColor: AppColors.surfaceColor(context),
                            borderRadius: BorderRadius.circular(18),
                            style: TextStyle(
                              color: AppColors.textPrimaryColor(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _inputDecoration(context, 'Categoria'),
                            items: categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category.id,
                                child: Text(
                                  category.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selecione uma categoria';
                              }

                              return null;
                            },
                            onChanged: isLinked
                                ? null
                                : (value) {
                                    setState(() {
                                      selectedCategoryId = value;
                                    });
                                  },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: selectedUnit,
                            isExpanded: true,
                            menuMaxHeight: 260,
                            dropdownColor: AppColors.surfaceColor(context),
                            borderRadius: BorderRadius.circular(18),
                            style: TextStyle(
                              color: AppColors.textPrimaryColor(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _inputDecoration(
                              context,
                              'Unidade de medida',
                            ),
                            items: units.map((unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(
                                  unit,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selecione uma unidade de medida';
                              }

                              return null;
                            },
                            onChanged: isLinked
                                ? null
                                : (value) {
                                    setState(() {
                                      selectedUnit = value;
                                    });
                                  },
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            value: isActive,
                            activeThumbColor: AppColors.primary,
                            activeTrackColor: AppColors.primary.withValues(
                              alpha: 0.35,
                            ),
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Ativo/Inativo',
                              style: TextStyle(
                                color: AppColors.textPrimaryColor(context),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              isActive
                                  ? 'Disponível para novas compras.'
                                  : 'Oculto para novas compras.',
                              style: TextStyle(
                                color: AppColors.textSecondaryColor(context),
                                fontSize: 12,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                isActive = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final name = nameController.text;
                      final brand = brandController.text;
                      final categoryId = selectedCategoryId;
                      final unit = selectedUnit;
                      final active = isActive;

                      final exists = viewModel.productAlreadyExists(
                        name: name,
                        brand: brand,
                        ignoreProductId: product?.id,
                      );

                      if (exists) {
                        showDialogMessage(_ProductsMessages.productDuplicate);
                        return;
                      }

                      if (categoryId == null || unit == null) {
                        showDialogMessage(
                          _ProductsMessages.productRequiredFields,
                        );
                        return;
                      }

                      if (product == null) {
                        Navigator.pop(
                          dialogContext,
                          _ProductDialogResult.create(
                            name: name,
                            brand: brand,
                            categoryId: categoryId,
                            unit: unit,
                            isActive: active,
                          ),
                        );

                        return;
                      }

                      final canEditCriticalData = viewModel
                          .canEditProductCriticalData(
                            product: product,
                            linkedProductIds: linkedProductIds,
                            name: name,
                            brand: brand,
                            categoryId: categoryId,
                            unit: unit,
                          );

                      if (!canEditCriticalData) {
                        showDialogMessage(_ProductsMessages.productLinkedInfo);
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                        _ProductDialogResult.update(
                          id: product.id,
                          name: name,
                          brand: brand,
                          categoryId: categoryId,
                          unit: unit,
                          isActive: active,
                        ),
                      );
                    },
                    child: const Text('Salvar'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == null) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 220));

      if (result.action == _ProductDialogAction.create) {
        viewModel.addProduct(
          name: result.name,
          brand: result.brand,
          categoryId: result.categoryId,
          unit: result.unit,
          isActive: result.isActive,
        );

        onFeedback(_ProductsMessages.productCreated);
        return;
      }

      if (result.action == _ProductDialogAction.update && result.id != null) {
        viewModel.updateProduct(
          id: result.id!,
          name: result.name,
          brand: result.brand,
          categoryId: result.categoryId,
          unit: result.unit,
          isActive: result.isActive,
        );

        onFeedback(_ProductsMessages.productUpdated);
      }
    } finally {
      nameController.dispose();
      brandController.dispose();
    }
  }

  List<CategoryModel> _availableCategoriesForProduct({
    required ProductsState state,
    required ProductsViewModel viewModel,
    required String? selectedCategoryId,
  }) {
    final categories = [...viewModel.activeCategories];

    if (selectedCategoryId == null) {
      return categories;
    }

    final alreadyIncluded = categories.any((category) {
      return category.id == selectedCategoryId;
    });

    if (alreadyIncluded) {
      return categories;
    }

    for (final category in state.categories) {
      if (category.id == selectedCategoryId) {
        categories.add(category);
        break;
      }
    }

    categories.sort((first, second) {
      return first.name.compareTo(second.name);
    });

    return categories;
  }
}

class _ProductListCard extends StatelessWidget {
  final ProductModel product;
  final String categoryName;
  final bool isLinked;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductListCard({
    required this.product,
    required this.categoryName,
    required this.isLinked,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final productColor = product.isActive
        ? AppColors.textPrimaryColor(context)
        : AppColors.textSecondaryColor(context);

    return Card(
      color: AppColors.surfaceColor(context),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        leading: CircleAvatar(
          backgroundColor: product.isActive
              ? AppColors.primarySoftBackground(context)
              : AppColors.surfaceSoftColor(context),
          child: Icon(
            Icons.shopping_basket_outlined,
            color: product.isActive
                ? AppColors.primary
                : AppColors.textSecondaryColor(context),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: productColor,
                ),
              ),
            ),
            if (isLinked) ...[const SizedBox(width: 8), const _LinkedBadge()],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '$categoryName • ${product.unit} • ${product.brand ?? 'Sem marca'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondaryColor(context),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
        trailing: PopupMenuButton<String>(
          color: AppColors.surfaceColor(context),
          tooltip: 'Opções do produto',
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
            return [
              const PopupMenuItem(
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
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
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
      ),
    );
  }
}

class _LinkedBadge extends StatelessWidget {
  const _LinkedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: AppColors.isDark(context) ? 0.20 : 0.10,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Text(
        'Usado',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LinkedProductWarning extends StatelessWidget {
  const _LinkedProductWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: AppColors.isDark(context) ? 0.16 : 0.09,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: AppColors.isDark(context) ? 0.30 : 0.22,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 19, color: AppColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _ProductsMessages.productLinkedInfo,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  final ProductsState state;
  final ProductsViewModel viewModel;
  final ProductsFeedbackCallback onFeedback;

  const _CategoriesTab({
    required this.state,
    required this.viewModel,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    final categories = viewModel.sortedCategories;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: categories.isEmpty
          ? const _EmptyState(
              icon: Icons.category_outlined,
              title: 'Nenhuma categoria cadastrada',
              subtitle: 'Cadastre categorias para organizar seus produtos.',
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];

                return _CategoryGridCard(
                  category: category,
                  onEdit: () {
                    _showCategoryDialog(
                      context,
                      state,
                      viewModel,
                      category: category,
                    );
                  },
                  onDelete: () {
                    _deleteCategory(viewModel: viewModel, category: category);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Adicionar categoria',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          _showCategoryDialog(context, state, viewModel);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext rootContext,
    ProductsState state,
    ProductsViewModel viewModel, {
    CategoryModel? category,
  }) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: category?.name ?? '');

    bool isActive = category?.isActive ?? true;
    String? dialogMessage;

    try {
      final result = await showDialog<_CategoryDialogResult>(
        context: rootContext,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              void showDialogMessage(String message) {
                setState(() {
                  dialogMessage = message;
                });
              }

              return AlertDialog(
                backgroundColor: AppColors.surfaceColor(context),
                surfaceTintColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: AppColors.borderColor(context)),
                ),
                title: Text(
                  category == null ? 'Nova categoria' : 'Editar categoria',
                  style: TextStyle(
                    color: AppColors.textPrimaryColor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                content: SizedBox(
                  width: 300,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (dialogMessage != null) ...[
                            _DialogFeedback(
                              message: dialogMessage!,
                              isError: true,
                            ),
                            const SizedBox(height: 12),
                          ],
                          _premiumTextField(
                            context,
                            controller: controller,
                            label: 'Nome da categoria',
                            hint: 'Ex: Hortifruti',
                            maxLength: 30,
                            requiredMessage: 'Informe o nome da categoria',
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            value: isActive,
                            activeThumbColor: AppColors.primary,
                            activeTrackColor: AppColors.primary.withValues(
                              alpha: 0.35,
                            ),
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Ativo/Inativo',
                              style: TextStyle(
                                color: AppColors.textPrimaryColor(context),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              isActive
                                  ? 'Disponível para novos produtos.'
                                  : 'Oculta para novos produtos.',
                              style: TextStyle(
                                color: AppColors.textSecondaryColor(context),
                                fontSize: 12,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                isActive = value;
                              });
                            },
                          ),
                          if (category != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(
                                    color: AppColors.danger,
                                  ),
                                ),
                                onPressed: () {
                                  if (!viewModel.canDeleteCategory(
                                    category.id,
                                  )) {
                                    showDialogMessage(
                                      _ProductsMessages.categoryDeleteBlocked,
                                    );
                                    return;
                                  }

                                  Navigator.pop(
                                    dialogContext,
                                    _CategoryDialogResult.delete(
                                      id: category.id,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                label: const Text('Excluir categoria'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final name = controller.text;
                      final active = isActive;

                      final categoryExists = state.categories.any((item) {
                        final sameName =
                            item.name.trim().toLowerCase() ==
                            name.trim().toLowerCase();

                        final sameEditingCategory =
                            category != null && item.id == category.id;

                        return sameName && !sameEditingCategory;
                      });

                      if (categoryExists) {
                        showDialogMessage(_ProductsMessages.categoryDuplicate);
                        return;
                      }

                      if (category == null) {
                        Navigator.pop(
                          dialogContext,
                          _CategoryDialogResult.create(
                            name: name,
                            isActive: active,
                          ),
                        );

                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                        _CategoryDialogResult.update(
                          id: category.id,
                          name: name,
                          isActive: active,
                        ),
                      );
                    },
                    child: const Text('Salvar'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == null) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 220));

      switch (result.action) {
        case _CategoryDialogAction.create:
          viewModel.addCategory(name: result.name!, isActive: result.isActive!);

          onFeedback(_ProductsMessages.categoryCreated);
          break;

        case _CategoryDialogAction.update:
          viewModel.updateCategory(
            id: result.id!,
            name: result.name!,
            isActive: result.isActive!,
          );

          onFeedback(_ProductsMessages.categoryUpdated);
          break;

        case _CategoryDialogAction.delete:
          viewModel.deleteCategory(result.id!);

          onFeedback(_ProductsMessages.categoryDeleted);
          break;
      }
    } finally {
      controller.dispose();
    }
  }

  void _deleteCategory({
    required ProductsViewModel viewModel,
    required CategoryModel category,
  }) {
    if (!viewModel.canDeleteCategory(category.id)) {
      onFeedback(_ProductsMessages.categoryDeleteBlocked, isError: true);
      return;
    }

    Future<void>.delayed(const Duration(milliseconds: 160), () {
      viewModel.deleteCategory(category.id);
      onFeedback(_ProductsMessages.categoryDeleted);
    });
  }
}

class _CategoryGridCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryGridCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = category.isActive
        ? AppColors.textPrimaryColor(context)
        : AppColors.textSecondaryColor(context);

    return Card(
      color: AppColors.surfaceColor(context),
      child: Stack(
        children: [
          Positioned(
            top: 6,
            left: 6,
            child: PopupMenuButton<String>(
              color: AppColors.surfaceColor(context),
              tooltip: 'Opções da categoria',
              padding: EdgeInsets.zero,
              iconSize: 20,
              iconColor: AppColors.textSecondaryColor(context),
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
                          Icons.delete_outline,
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
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onEdit,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 22, 12, 12),
                child: Opacity(
                  opacity: category.isActive ? 1 : 0.55,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: category.isActive
                              ? AppColors.primarySoftBackground(context)
                              : AppColors.surfaceSoftColor(context),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.category_outlined,
                          color: category.isActive
                              ? AppColors.primary
                              : AppColors.textSecondaryColor(context),
                          size: 25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: categoryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductDialogResult {
  final _ProductDialogAction action;
  final String? id;
  final String name;
  final String brand;
  final String categoryId;
  final String unit;
  final bool isActive;

  const _ProductDialogResult._({
    required this.action,
    this.id,
    required this.name,
    required this.brand,
    required this.categoryId,
    required this.unit,
    required this.isActive,
  });

  factory _ProductDialogResult.create({
    required String name,
    required String brand,
    required String categoryId,
    required String unit,
    required bool isActive,
  }) {
    return _ProductDialogResult._(
      action: _ProductDialogAction.create,
      name: name,
      brand: brand,
      categoryId: categoryId,
      unit: unit,
      isActive: isActive,
    );
  }

  factory _ProductDialogResult.update({
    required String id,
    required String name,
    required String brand,
    required String categoryId,
    required String unit,
    required bool isActive,
  }) {
    return _ProductDialogResult._(
      action: _ProductDialogAction.update,
      id: id,
      name: name,
      brand: brand,
      categoryId: categoryId,
      unit: unit,
      isActive: isActive,
    );
  }
}

enum _ProductDialogAction { create, update }

class _CategoryDialogResult {
  final _CategoryDialogAction action;
  final String? id;
  final String? name;
  final bool? isActive;

  const _CategoryDialogResult._({
    required this.action,
    this.id,
    this.name,
    this.isActive,
  });

  factory _CategoryDialogResult.create({
    required String name,
    required bool isActive,
  }) {
    return _CategoryDialogResult._(
      action: _CategoryDialogAction.create,
      name: name,
      isActive: isActive,
    );
  }

  factory _CategoryDialogResult.update({
    required String id,
    required String name,
    required bool isActive,
  }) {
    return _CategoryDialogResult._(
      action: _CategoryDialogAction.update,
      id: id,
      name: name,
      isActive: isActive,
    );
  }

  factory _CategoryDialogResult.delete({required String id}) {
    return _CategoryDialogResult._(
      action: _CategoryDialogAction.delete,
      id: id,
    );
  }
}

enum _CategoryDialogAction { create, update, delete }

Widget _premiumTextField(
  BuildContext context, {
  required TextEditingController controller,
  required String label,
  required String hint,
  required int maxLength,
  required String requiredMessage,
  bool enabled = true,
}) {
  return TextFormField(
    controller: controller,
    enabled: enabled,
    maxLength: maxLength,
    style: TextStyle(
      color: AppColors.textPrimaryColor(context),
      fontWeight: FontWeight.w600,
    ),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ0-9 ]')),
      LengthLimitingTextInputFormatter(maxLength),
    ],
    decoration: _inputDecoration(
      context,
      label,
    ).copyWith(hintText: hint, counterText: ''),
    validator: (value) {
      if (value == null || value.trim().isEmpty) {
        return requiredMessage;
      }

      if (value.trim().length < 2) {
        return 'Informe pelo menos 2 caracteres';
      }

      return null;
    },
  );
}

InputDecoration _inputDecoration(BuildContext context, String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: AppColors.textSecondaryColor(context)),
    hintStyle: TextStyle(
      color: AppColors.textSecondaryColor(context).withValues(alpha: 0.75),
    ),
    filled: true,
    fillColor: AppColors.surfaceSoftColor(context),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.borderColor(context)),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: AppColors.borderColor(context).withValues(alpha: 0.70),
      ),
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

class _ProductsLocalFeedback extends StatelessWidget {
  final String message;
  final bool isError;

  const _ProductsLocalFeedback({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.success;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppColors.isDark(context) ? 0.28 : 0.16,
              ),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          softWrap: true,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class _DialogFeedback extends StatelessWidget {
  final String message;
  final bool isError;

  const _DialogFeedback({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(
            alpha: AppColors.isDark(context) ? 0.34 : 0.25,
          ),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        softWrap: true,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 110),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: AppColors.primarySoftBackground(context),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimaryColor(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: AppColors.textSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
