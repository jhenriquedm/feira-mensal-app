import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/purchase_model.dart';

class ProductsStorageData {
  final List<CategoryModel> categories;
  final List<ProductModel> products;

  const ProductsStorageData({required this.categories, required this.products});
}

class LocalStorageService {
  static const String _categoriesKey = 'feira_mensal_categories_v1';
  static const String _productsKey = 'feira_mensal_products_v1';
  static const String _purchasesKey = 'feira_mensal_purchases_v1';

  static Future<ProductsStorageData?> loadProductsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final categoriesJson = prefs.getString(_categoriesKey);
      final productsJson = prefs.getString(_productsKey);

      if (categoriesJson == null && productsJson == null) {
        return null;
      }

      final categories = categoriesJson == null
          ? <CategoryModel>[]
          : (jsonDecode(categoriesJson) as List).map((item) {
              return CategoryModel.fromMap(
                Map<String, dynamic>.from(item as Map),
              );
            }).toList();

      final products = productsJson == null
          ? <ProductModel>[]
          : (jsonDecode(productsJson) as List).map((item) {
              return ProductModel.fromMap(
                Map<String, dynamic>.from(item as Map),
              );
            }).toList();

      return ProductsStorageData(categories: categories, products: products);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProductsData({
    required List<CategoryModel> categories,
    required List<ProductModel> products,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final categoriesJson = jsonEncode(
        categories.map((category) => category.toMap()).toList(),
      );

      final productsJson = jsonEncode(
        products.map((product) => product.toMap()).toList(),
      );

      await prefs.setString(_categoriesKey, categoriesJson);
      await prefs.setString(_productsKey, productsJson);
    } catch (_) {
      // Evita quebrar testes ou execução caso o storage local falhe.
    }
  }

  static Future<List<PurchaseModel>?> loadPurchases() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final purchasesJson = prefs.getString(_purchasesKey);

      if (purchasesJson == null) {
        return null;
      }

      return (jsonDecode(purchasesJson) as List).map((item) {
        return PurchaseModel.fromMap(Map<String, dynamic>.from(item as Map));
      }).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> savePurchases(List<PurchaseModel> purchases) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final purchasesJson = jsonEncode(
        purchases.map((purchase) => purchase.toMap()).toList(),
      );

      await prefs.setString(_purchasesKey, purchasesJson);
    } catch (_) {
      // Evita quebrar testes ou execução caso o storage local falhe.
    }
  }
}
