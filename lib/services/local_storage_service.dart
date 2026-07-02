import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user_model.dart';
import '../models/category_model.dart';
import '../models/offline_session_model.dart';
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

  static const String _usersKey = 'feira_mensal_users_v1';
  static const String _currentUserIdKey = 'feira_mensal_current_user_id_v1';
  static const String _offlineSessionKey = 'feira_mensal_offline_session_v1';
  static const String _themeModeKey = 'feira_mensal_theme_mode_v1';
  static const String _themeColorKey = 'feira_mensal_theme_color_v1';

  static String _userScopedKey({
    required String baseKey,
    required String userId,
  }) {
    return '${baseKey}_user_$userId';
  }

  static Future<ProductsStorageData?> loadProductsDataForUser({
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final categoriesJson = prefs.getString(
        _userScopedKey(baseKey: _categoriesKey, userId: userId),
      );

      final productsJson = prefs.getString(
        _userScopedKey(baseKey: _productsKey, userId: userId),
      );

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

  static Future<void> saveProductsDataForUser({
    required String userId,
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

      await prefs.setString(
        _userScopedKey(baseKey: _categoriesKey, userId: userId),
        categoriesJson,
      );

      await prefs.setString(
        _userScopedKey(baseKey: _productsKey, userId: userId),
        productsJson,
      );
    } catch (_) {
      // Evita quebrar testes ou execução caso o storage falhe.
    }
  }

  static Future<List<PurchaseModel>?> loadPurchasesForUser({
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final purchasesJson = prefs.getString(
        _userScopedKey(baseKey: _purchasesKey, userId: userId),
      );

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

  static Future<void> savePurchasesForUser({
    required String userId,
    required List<PurchaseModel> purchases,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final purchasesJson = jsonEncode(
        purchases.map((purchase) => purchase.toMap()).toList(),
      );

      await prefs.setString(
        _userScopedKey(baseKey: _purchasesKey, userId: userId),
        purchasesJson,
      );
    } catch (_) {
      // Evita quebrar testes ou execução caso o storage falhe.
    }
  }

  static Future<void> clearUserLocalData({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(
        _userScopedKey(baseKey: _categoriesKey, userId: userId),
      );

      await prefs.remove(_userScopedKey(baseKey: _productsKey, userId: userId));

      await prefs.remove(
        _userScopedKey(baseKey: _purchasesKey, userId: userId),
      );
    } catch (_) {
      // Evita quebrar testes ou execução caso o storage falhe.
    }
  }

  static Future<List<AppUserModel>> loadUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);

      if (usersJson == null) {
        return [];
      }

      return (jsonDecode(usersJson) as List).map((item) {
        return AppUserModel.fromMap(Map<String, dynamic>.from(item as Map));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveUsers(List<AppUserModel> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final usersJson = jsonEncode(users.map((user) => user.toMap()).toList());

      await prefs.setString(_usersKey, usersJson);
    } catch (_) {
      // Evita quebrar testes ou execução caso o storage falhe.
    }
  }

  static Future<String?> loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return prefs.getString(_currentUserIdKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveCurrentUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_currentUserIdKey, userId);
    } catch (_) {
      // Evita quebrar testes ou execução caso o storage falhe.
    }
  }

  static Future<void> clearCurrentUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_currentUserIdKey);
    } catch (_) {
      // Evita quebrar testes ou execução caso o storage falhe.
    }
  }

  static Future<OfflineSessionModel?> loadOfflineSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_offlineSessionKey);

      if (sessionJson == null) {
        return null;
      }

      return OfflineSessionModel.fromMap(
        Map<String, dynamic>.from(jsonDecode(sessionJson) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveOfflineSession(OfflineSessionModel session) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_offlineSessionKey, jsonEncode(session.toMap()));
      await prefs.setString(_currentUserIdKey, session.userId);
    } catch (_) {
      // Evita quebrar testes ou execução caso o storage falhe.
    }
  }

  static Future<void> clearOfflineSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_offlineSessionKey);
      await prefs.remove(_currentUserIdKey);
    } catch (_) {
      // Evita quebrar testes ou execução caso o storage falhe.
    }
  }

  static Future<String?> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return prefs.getString(_themeModeKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveThemeMode(String themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_themeModeKey, themeMode);
    } catch (_) {
      // Evita quebrar testes ou execução caso o storage falhe.
    }
  }

  static Future<String?> loadThemeColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return prefs.getString(_themeColorKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveThemeColor(String themeColor) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_themeColorKey, themeColor);
    } catch (_) {
      // Evita quebrar testes ou execução caso o storage falhe.
    }
  }
}
