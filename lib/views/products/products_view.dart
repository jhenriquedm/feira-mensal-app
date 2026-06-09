import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../viewmodels/products_viewmodel.dart';

class ProductsView extends ConsumerWidget {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsProvider);
    final viewModel = ref.read(productsProvider.notifier);

    return DefaultTabController(
      length: 2,
      child: Column(
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
                Container(
                  height: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    tabs: [
                      Tab(text: 'Produtos'),
                      Tab(text: 'Categorias'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ProductsTab(state: state, viewModel: viewModel),
                _CategoriesTab(state: state, viewModel: viewModel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  final ProductsState state;
  final ProductsViewModel viewModel;

  const _ProductsTab({required this.state, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final products = viewModel.sortedProducts;

    return Scaffold(
      body: products.isEmpty
          ? const _EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'Nenhum produto cadastrado',
              subtitle: 'Cadastre produtos para montar suas feiras mensais.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = products[index];

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
                    title: Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: product.isActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    subtitle: Text(
                      '${viewModel.getCategoryName(product.categoryId)} • ${product.unit} • ${product.brand ?? ''}\n'
                      '${product.isActive ? 'Ativo' : 'Inativo'}',
                    ),
                    isThreeLine: true,
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
                            product: product,
                          );
                        }

                        if (value == 'delete') {
                          if (!viewModel.canDeleteProduct(product.id)) {
                            _showSuccess(
                              context,
                              'Produto não pode ser excluído, pois está vinculado a uma compra.',
                              isError: true,
                            );
                            return;
                          }

                          viewModel.deleteProduct(product.id);
                          _showSuccess(
                            context,
                            'Produto excluído com sucesso.',
                          );
                        }
                      },
                      itemBuilder: (context) => const [
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
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(context, state, viewModel),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showProductDialog(
    BuildContext context,
    ProductsState state,
    ProductsViewModel viewModel, {
    ProductModel? product,
  }) {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: product?.name ?? '');
    final brandController = TextEditingController(text: product?.brand ?? '');

    String? selectedCategoryId = product?.categoryId;
    String? selectedUnit = product?.unit;
    bool isActive = product?.isActive ?? true;

    final categories = viewModel.activeCategories;
    final units = ['Caixa', 'g', 'Kg', 'Litro', 'ml', 'Pacote', 'Unidade'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? 'Novo produto' : 'Editar produto'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 360,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _premiumTextField(
                          controller: nameController,
                          label: 'Nome do produto',
                          hint: 'Ex: Café',
                          maxLength: 30,
                          requiredMessage: 'Informe o nome do produto',
                        ),
                        const SizedBox(height: 12),
                        _premiumTextField(
                          controller: brandController,
                          label: 'Marca',
                          hint: 'Ex: Pilão',
                          maxLength: 30,
                          requiredMessage: 'Informe a marca',
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
                            return DropdownMenuItem(
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
                          onChanged: (value) {
                            setState(() => selectedCategoryId = value);
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
                            return DropdownMenuItem(
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
                          onChanged: (value) {
                            setState(() => selectedUnit = value);
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
                          title: Text(isActive ? 'Ativo' : 'Inativo'),
                          onChanged: (value) {
                            setState(() => isActive = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final exists = viewModel.productAlreadyExists(
                  name: nameController.text,
                  brand: brandController.text,
                  ignoreProductId: product?.id,
                );

                if (exists) {
                  _showSuccess(
                    context,
                    'Já existe um produto com esse nome e marca.',
                    isError: true,
                  );
                  return;
                }

                if (product == null) {
                  viewModel.addProduct(
                    name: nameController.text,
                    brand: brandController.text,
                    categoryId: selectedCategoryId!,
                    unit: selectedUnit!,
                    isActive: isActive,
                  );
                  _showSuccess(context, 'Produto cadastrado com sucesso.');
                } else {
                  viewModel.updateProduct(
                    id: product.id,
                    name: nameController.text,
                    brand: brandController.text,
                    categoryId: selectedCategoryId!,
                    unit: selectedUnit!,
                    isActive: isActive,
                  );
                  _showSuccess(context, 'Produto atualizado com sucesso.');
                }

                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  final ProductsState state;
  final ProductsViewModel viewModel;

  const _CategoriesTab({required this.state, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final categories = viewModel.sortedCategories;

    return Scaffold(
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];

          return Card(
            child: Stack(
              children: [
                Positioned(
                  top: 6,
                  right: 6,
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
                          viewModel,
                          category: category,
                        );
                      }

                      if (value == 'delete') {
                        if (!viewModel.canDeleteCategory(category.id)) {
                          _showSuccess(
                            context,
                            'Categoria não pode ser excluída, pois possui produtos vinculados.',
                            isError: true,
                          );
                          return;
                        }

                        viewModel.deleteCategory(category.id);
                        _showSuccess(
                          context,
                          'Categoria excluída com sucesso.',
                        );
                      }
                    },
                    itemBuilder: (context) => const [
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
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    _showCategoryDialog(context, viewModel, category: category);
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
                              style: Theme.of(context).textTheme.titleMedium
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
        onPressed: () => _showCategoryDialog(context, viewModel),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    ProductsViewModel viewModel, {
    CategoryModel? category,
  }) {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: category?.name ?? '');
    bool isActive = category?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(category == null ? 'Nova categoria' : 'Editar categoria'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      title: Text(isActive ? 'Ativo' : 'Inativo'),
                      onChanged: (value) {
                        setState(() => isActive = value);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                if (category == null) {
                  viewModel.addCategory(
                    name: controller.text,
                    isActive: isActive,
                  );
                  _showSuccess(context, 'Categoria cadastrada com sucesso.');
                } else {
                  viewModel.updateCategory(
                    id: category.id,
                    name: controller.text,
                    isActive: isActive,
                  );
                  _showSuccess(context, 'Categoria atualizada com sucesso.');
                }

                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}

Widget _premiumTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required int maxLength,
  required String requiredMessage,
}) {
  return TextFormField(
    controller: controller,
    maxLength: maxLength,
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ0-9 ]')),
    ],
    decoration: _inputDecoration(
      label,
    ).copyWith(hintText: hint, counterText: ''),
    validator: (value) {
      if (value == null || value.trim().isEmpty) {
        return requiredMessage;
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

void _showSuccess(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Center(
        heightFactor: 1,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(28, 0, 28, 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      duration: const Duration(seconds: 2),
    ),
  );
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
