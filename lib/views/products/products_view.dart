import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
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
          const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Produtos'),
              Tab(text: 'Categorias'),
            ],
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

  const _ProductsTab({
    required this.state,
    required this.viewModel,
  });

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
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = products[index];

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F7EE),
                      child: Icon(
                        Icons.shopping_basket_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(product.name),
                    subtitle: Text(
                      '${viewModel.getCategoryName(product.categoryId)} • ${product.unit} • ${product.brand ?? ''}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showProductDialog(context, state, viewModel, product: product);
                        }

                        if (value == 'delete') {
                          viewModel.deleteProduct(product.id);
                          _showSuccess(context, 'Produto excluído com sucesso.');
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Excluir'),
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

    final categories = [...state.categories]
      ..sort((a, b) => a.name.compareTo(b.name));

    final units = [
      'Caixa',
      'g',
      'Kg',
      'Litro',
      'ml',
      'Pacote',
      'Unidade',
    ];

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
                          value: selectedCategoryId,
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
                          value: selectedUnit,
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

                if (product == null) {
                  viewModel.addProduct(
                    name: nameController.text,
                    brand: brandController.text,
                    categoryId: selectedCategoryId!,
                    unit: selectedUnit!,
                  );
                  _showSuccess(context, 'Produto cadastrado com sucesso.');
                } else {
                  viewModel.updateProduct(
                    id: product.id,
                    name: nameController.text,
                    brand: brandController.text,
                    categoryId: selectedCategoryId!,
                    unit: selectedUnit!,
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

  const _CategoriesTab({
    required this.state,
    required this.viewModel,
  });

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
          childAspectRatio: 1.45,
        ),
        itemBuilder: (context, index) {
          final category = categories[index];

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.category_outlined,
                    color: AppColors.primary,
                    size: 30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context, viewModel),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategoryDialog(
    BuildContext context,
    ProductsViewModel viewModel,
  ) {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova categoria'),
          content: Form(
            key: formKey,
            child: _premiumTextField(
              controller: controller,
              label: 'Nome da categoria',
              hint: 'Ex: Hortifruti',
              maxLength: 30,
              requiredMessage: 'Informe o nome da categoria',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                viewModel.addCategory(controller.text);
                Navigator.pop(context);
                _showSuccess(context, 'Categoria cadastrada com sucesso.');
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
      FilteringTextInputFormatter.allow(
        RegExp(r'[a-zA-ZÀ-ÿ0-9 ]'),
      ),
    ],
    decoration: _inputDecoration(label).copyWith(
      hintText: hint,
      counterText: '',
    ),
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
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: AppColors.primary,
        width: 1.6,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: AppColors.danger,
        width: 1.4,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: AppColors.danger,
        width: 1.6,
      ),
    ),
  );
}

void _showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: AppColors.success,
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