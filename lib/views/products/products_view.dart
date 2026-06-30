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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gerenciamento',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ManualSegmentedTabs(
                    selectedIndex: _selectedTabIndex,
                    onChanged: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                  ),
                ],
              ),
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
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
        color: selected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
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
      backgroundColor: AppColors.background,
      body: products.isEmpty
          ? const _EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'Nenhum produto cadastrado',
              subtitle: 'Cadastre produtos para montar suas feiras mensais.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 10);
              },
              itemBuilder: (context, index) {
                final product = products[index];
                final isLinked = linkedProductIds.contains(product.id);

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: product.isActive
                          ? const Color(0xFFE8F7EE)
                          : const Color(0xFFF3F4F6),
                      child: Icon(
                        Icons.shopping_basket_outlined,
                        color: product.isActive
                            ? AppColors.primary
                            : AppColors.textSecondary,
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
                              fontWeight: FontWeight.w700,
                              color: product.isActive
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (isLinked) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
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
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '${viewModel.getCategoryName(product.categoryId)} • '
                      '${product.unit} • ${product.brand ?? 'Sem marca'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showProductDialog(
                            context,
                            state,
                            viewModel,
                            linkedProductIds,
                            product: product,
                          );
                        }

                        if (value == 'delete') {
                          if (!viewModel.canDeleteProduct(
                            product.id,
                            linkedProductIds: linkedProductIds,
                          )) {
                            onFeedback(
                              'Produto não pode ser excluído, pois está vinculado a uma compra.',
                              isError: true,
                            );
                            return;
                          }

                          Future<void>.delayed(
                            const Duration(milliseconds: 160),
                            () {
                              viewModel.deleteProduct(product.id);
                              onFeedback('Produto excluído com sucesso.');
                            },
                          );
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
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
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
                title: Text(
                  product == null ? 'Novo produto' : 'Editar produto',
                ),
                content: SizedBox(
                  width: 360,
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
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.09,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.22,
                                  ),
                                ),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 19,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Este produto já foi usado em uma compra. Para preservar o histórico, altere apenas o campo Ativo/Inativo.',
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
                            ),
                            const SizedBox(height: 12),
                          ],
                          _premiumTextField(
                            controller: nameController,
                            label: 'Nome do produto',
                            hint: 'Ex: Café',
                            maxLength: 30,
                            requiredMessage: 'Informe o nome do produto',
                            enabled: !isLinked,
                          ),
                          const SizedBox(height: 12),
                          _premiumTextField(
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
                            dropdownColor: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            decoration: _inputDecoration('Categoria'),
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
                            dropdownColor: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            decoration: _inputDecoration('Unidade de medida'),
                            items: units.map((unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(unit),
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
                            title: const Text('Ativo/Inativo'),
                            subtitle: Text(
                              isActive
                                  ? 'Produto disponível para novas compras.'
                                  : 'Produto oculto para novas compras.',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
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
                        showDialogMessage(
                          'Já existe um produto com esse nome e marca.',
                        );
                        return;
                      }

                      if (categoryId == null || unit == null) {
                        showDialogMessage(
                          'Preencha todos os campos obrigatórios.',
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
                        showDialogMessage(
                          'Este produto já foi usado em uma compra. Para preservar o histórico, altere apenas o campo Ativo/Inativo.',
                        );
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

        onFeedback('Produto cadastrado com sucesso.');
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

        onFeedback('Produto atualizado com sucesso.');
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
      backgroundColor: AppColors.background,
      body: categories.isEmpty
          ? const _EmptyState(
              icon: Icons.category_outlined,
              title: 'Nenhuma categoria cadastrada',
              subtitle: 'Cadastre categorias para organizar seus produtos.',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];

                return Card(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 6,
                        left: 6,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showCategoryDialog(
                                context,
                                state,
                                viewModel,
                                category: category,
                              );
                            }

                            if (value == 'delete') {
                              _deleteCategory(
                                viewModel: viewModel,
                                category: category,
                              );
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
                        onTap: () {
                          _showCategoryDialog(
                            context,
                            state,
                            viewModel,
                            category: category,
                          );
                        },
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 22, 12, 12),
                            child: Opacity(
                              opacity: category.isActive ? 1 : 0.45,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    color: category.isActive
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    category.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: category.isActive
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
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
              },
            ),
      floatingActionButton: FloatingActionButton(
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
                title: Text(
                  category == null ? 'Nova categoria' : 'Editar categoria',
                ),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dialogMessage != null) ...[
                        _DialogFeedback(message: dialogMessage!, isError: true),
                        const SizedBox(height: 12),
                      ],
                      _premiumTextField(
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
                        title: const Text('Ativo/Inativo'),
                        subtitle: Text(
                          isActive
                              ? 'Categoria disponível para novos produtos.'
                              : 'Categoria ocultada para novos produtos.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
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
                              side: const BorderSide(color: AppColors.danger),
                            ),
                            onPressed: () {
                              if (!viewModel.canDeleteCategory(category.id)) {
                                showDialogMessage(
                                  'Categoria não pode ser excluída, pois possui produtos vinculados.',
                                );
                                return;
                              }

                              Navigator.pop(
                                dialogContext,
                                _CategoryDialogResult.delete(id: category.id),
                              );
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Excluir categoria'),
                          ),
                        ),
                      ],
                    ],
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
                        showDialogMessage(
                          'Já existe uma categoria com esse nome.',
                        );
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

          onFeedback('Categoria cadastrada com sucesso.');
          break;

        case _CategoryDialogAction.update:
          viewModel.updateCategory(
            id: result.id!,
            name: result.name!,
            isActive: result.isActive!,
          );

          onFeedback('Categoria atualizada com sucesso.');
          break;

        case _CategoryDialogAction.delete:
          viewModel.deleteCategory(result.id!);

          onFeedback('Categoria excluída com sucesso.');
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
      onFeedback(
        'Categoria não pode ser excluída, pois possui produtos vinculados.',
        isError: true,
      );
      return;
    }

    Future<void>.delayed(const Duration(milliseconds: 160), () {
      viewModel.deleteCategory(category.id);
      onFeedback('Categoria excluída com sucesso.');
    });
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

Widget _premiumTextField({
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
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ0-9 ]')),
      LengthLimitingTextInputFormatter(maxLength),
    ],
    decoration: _inputDecoration(
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

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.background,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.70)),
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
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
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
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
