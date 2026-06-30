import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';

final productsProvider =
    StateNotifierProvider<ProductsViewModel, ProductsState>((ref) {
      return ProductsViewModel();
    });

class ProductsState {
  final List<CategoryModel> categories;
  final List<ProductModel> products;

  const ProductsState({required this.categories, required this.products});

  ProductsState copyWith({
    List<CategoryModel>? categories,
    List<ProductModel>? products,
  }) {
    return ProductsState(
      categories: categories ?? this.categories,
      products: products ?? this.products,
    );
  }
}

class ProductsViewModel extends StateNotifier<ProductsState> {
  ProductsViewModel()
    : super(
        const ProductsState(
          categories: [
            CategoryModel(id: 'bebidas', name: 'Bebidas', iconName: 'bebidas'),
            CategoryModel(id: 'carnes', name: 'Carnes', iconName: 'carnes'),
            CategoryModel(id: 'cereais', name: 'Cereais', iconName: 'cereais'),
            CategoryModel(
              id: 'higiene',
              name: 'Higiene pessoal',
              iconName: 'higiene',
            ),
            CategoryModel(
              id: 'limpeza',
              name: 'Produtos de limpeza',
              iconName: 'limpeza',
            ),
            CategoryModel(id: 'outros', name: 'Outros', iconName: 'outros'),
          ],
          products: [],
        ),
      );

  final Uuid _uuid = const Uuid();

  List<CategoryModel> get sortedCategories {
    final list = [...state.categories];

    list.sort((first, second) {
      return first.name.compareTo(second.name);
    });

    return list;
  }

  List<CategoryModel> get activeCategories {
    final list = state.categories
        .where((category) => category.isActive)
        .toList();

    list.sort((first, second) {
      return first.name.compareTo(second.name);
    });

    return list;
  }

  List<ProductModel> get sortedProducts {
    final list = [...state.products];

    list.sort((first, second) {
      final firstName = '${first.name} ${first.brand ?? ''}'.toLowerCase();
      final secondName = '${second.name} ${second.brand ?? ''}'.toLowerCase();

      return firstName.compareTo(secondName);
    });

    return list;
  }

  bool productAlreadyExists({
    required String name,
    required String brand,
    String? ignoreProductId,
  }) {
    final normalizedName = _normalize(name);
    final normalizedBrand = _normalize(brand);

    return state.products.any((product) {
      final sameName = _normalize(product.name) == normalizedName;
      final sameBrand = _normalize(product.brand ?? '') == normalizedBrand;
      final isSameEditingProduct =
          ignoreProductId != null && product.id == ignoreProductId;

      return sameName && sameBrand && !isSameEditingProduct;
    });
  }

  void addCategory({required String name, required bool isActive}) {
    final category = CategoryModel(
      id: _uuid.v4(),
      name: name.trim(),
      iconName: 'custom',
      isActive: isActive,
    );

    state = state.copyWith(categories: [...state.categories, category]);
  }

  void updateCategory({
    required String id,
    required String name,
    required bool isActive,
  }) {
    final updatedCategories = state.categories.map((category) {
      if (category.id != id) {
        return category;
      }

      return CategoryModel(
        id: category.id,
        name: name.trim(),
        iconName: category.iconName,
        isActive: isActive,
      );
    }).toList();

    state = state.copyWith(categories: updatedCategories);
  }

  bool canDeleteCategory(String categoryId) {
    return !state.products.any((product) {
      return product.categoryId == categoryId;
    });
  }

  void deleteCategory(String categoryId) {
    state = state.copyWith(
      categories: state.categories
          .where((category) => category.id != categoryId)
          .toList(),
    );
  }

  void addProduct({
    required String name,
    required String categoryId,
    required String unit,
    required String brand,
    required bool isActive,
  }) {
    final product = ProductModel(
      id: _uuid.v4(),
      name: name.trim(),
      categoryId: categoryId,
      unit: unit,
      brand: brand.trim(),
      isActive: isActive,
    );

    state = state.copyWith(products: [...state.products, product]);
  }

  void updateProduct({
    required String id,
    required String name,
    required String categoryId,
    required String unit,
    required String brand,
    required bool isActive,
  }) {
    final updatedProducts = state.products.map((product) {
      if (product.id != id) {
        return product;
      }

      return ProductModel(
        id: id,
        name: name.trim(),
        categoryId: categoryId,
        unit: unit,
        brand: brand.trim(),
        lastPrice: product.lastPrice,
        isActive: isActive,
      );
    }).toList();

    state = state.copyWith(products: updatedProducts);
  }

  bool canDeleteProduct(
    String productId, {
    required Set<String> linkedProductIds,
  }) {
    return !linkedProductIds.contains(productId);
  }

  bool canEditProductCriticalData({
    required ProductModel product,
    required Set<String> linkedProductIds,
    required String name,
    required String brand,
    required String categoryId,
    required String unit,
  }) {
    final isLinked = linkedProductIds.contains(product.id);

    if (!isLinked) {
      return true;
    }

    final changedName = _normalize(product.name) != _normalize(name);
    final changedBrand = _normalize(product.brand ?? '') != _normalize(brand);
    final changedCategory = product.categoryId != categoryId;
    final changedUnit = product.unit != unit;

    return !changedName && !changedBrand && !changedCategory && !changedUnit;
  }

  void deleteProduct(String id) {
    state = state.copyWith(
      products: state.products.where((product) => product.id != id).toList(),
    );
  }

  String getCategoryName(String categoryId) {
    return state.categories
        .firstWhere(
          (category) => category.id == categoryId,
          orElse: () => const CategoryModel(
            id: 'outros',
            name: 'Outros',
            iconName: 'outros',
          ),
        )
        .name;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}
