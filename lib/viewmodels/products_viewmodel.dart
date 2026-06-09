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

  const ProductsState({
    required this.categories,
    required this.products,
  });

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
              CategoryModel(id: 'higiene', name: 'Higiene pessoal', iconName: 'higiene'),
              CategoryModel(id: 'limpeza', name: 'Produtos de limpeza', iconName: 'limpeza'),
              CategoryModel(id: 'outros', name: 'Outros', iconName: 'outros'),
            ],
            products: [],
          ),
        );

  final _uuid = const Uuid();

  List<CategoryModel> get sortedCategories {
    final list = [...state.categories];
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  List<ProductModel> get sortedProducts {
    final list = [...state.products];
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  void addCategory(String name) {
    final category = CategoryModel(
      id: _uuid.v4(),
      name: name.trim(),
      iconName: 'custom',
    );

    state = state.copyWith(categories: [...state.categories, category]);
  }

  void addProduct({
    required String name,
    required String categoryId,
    required String unit,
    required String brand,
  }) {
    final product = ProductModel(
      id: _uuid.v4(),
      name: name.trim(),
      categoryId: categoryId,
      unit: unit,
      brand: brand.trim(),
    );

    state = state.copyWith(products: [...state.products, product]);
  }

  void updateProduct({
    required String id,
    required String name,
    required String categoryId,
    required String unit,
    required String brand,
  }) {
    final updatedProducts = state.products.map((product) {
      if (product.id != id) return product;

      return ProductModel(
        id: id,
        name: name.trim(),
        categoryId: categoryId,
        unit: unit,
        brand: brand.trim(),
        lastPrice: product.lastPrice,
      );
    }).toList();

    state = state.copyWith(products: updatedProducts);
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
}