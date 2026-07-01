import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/purchase_model.dart';
import '../models/sync_status.dart';

class ProductsSyncResult {
  final List<CategoryModel> categories;
  final List<ProductModel> products;

  const ProductsSyncResult({required this.categories, required this.products});
}

class PurchasesSyncResult {
  final List<PurchaseModel> purchases;

  const PurchasesSyncResult({required this.purchases});
}

class FirestoreSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _userCategoriesRef(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('categories');
  }

  static CollectionReference<Map<String, dynamic>> _userProductsRef(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('products');
  }

  static CollectionReference<Map<String, dynamic>> _userPurchasesRef(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('purchases');
  }

  static Future<ProductsSyncResult> syncProductsDataForUser({
    required String userId,
    required List<CategoryModel> categories,
    required List<ProductModel> products,
  }) async {
    if (userId.trim().isEmpty || userId == 'no_user') {
      return ProductsSyncResult(categories: categories, products: products);
    }

    final syncedCategories = <CategoryModel>[];
    final syncedProducts = <ProductModel>[];

    for (final category in categories) {
      final syncedCategory = await _syncCategory(
        userId: userId,
        category: category,
      );

      if (syncedCategory != null) {
        syncedCategories.add(syncedCategory);
      }
    }

    for (final product in products) {
      final syncedProduct = await _syncProduct(
        userId: userId,
        product: product,
      );

      if (syncedProduct != null) {
        syncedProducts.add(syncedProduct);
      }
    }

    return ProductsSyncResult(
      categories: syncedCategories,
      products: syncedProducts,
    );
  }

  static Future<PurchasesSyncResult> syncPurchasesForUser({
    required String userId,
    required List<PurchaseModel> purchases,
  }) async {
    if (userId.trim().isEmpty || userId == 'no_user') {
      return PurchasesSyncResult(purchases: purchases);
    }

    final syncedPurchases = <PurchaseModel>[];

    for (final purchase in purchases) {
      final syncedPurchase = await _syncPurchase(
        userId: userId,
        purchase: purchase,
      );

      if (syncedPurchase != null) {
        syncedPurchases.add(syncedPurchase);
      }
    }

    return PurchasesSyncResult(purchases: syncedPurchases);
  }

  static Future<CategoryModel?> _syncCategory({
    required String userId,
    required CategoryModel category,
  }) async {
    final document = _userCategoriesRef(userId).doc(category.id);

    if (category.syncStatus == SyncStatus.synced && !category.isDeleted) {
      return category;
    }

    if (category.syncStatus == SyncStatus.pendingDelete || category.isDeleted) {
      await document.delete();
      return null;
    }

    final now = DateTime.now();

    final data = category
        .copyWith(
          createdAt: category.createdAt ?? now,
          updatedAt: category.updatedAt ?? now,
          lastSyncedAt: now,
          syncStatus: SyncStatus.synced,
          isDeleted: false,
        )
        .toMap();

    await document.set(data, SetOptions(merge: true));

    return CategoryModel.fromMap(data);
  }

  static Future<ProductModel?> _syncProduct({
    required String userId,
    required ProductModel product,
  }) async {
    final document = _userProductsRef(userId).doc(product.id);

    if (product.syncStatus == SyncStatus.synced && !product.isDeleted) {
      return product;
    }

    if (product.syncStatus == SyncStatus.pendingDelete || product.isDeleted) {
      await document.delete();
      return null;
    }

    final now = DateTime.now();

    final data = product
        .copyWith(
          createdAt: product.createdAt ?? now,
          updatedAt: product.updatedAt ?? now,
          lastSyncedAt: now,
          syncStatus: SyncStatus.synced,
          isDeleted: false,
        )
        .toMap();

    await document.set(data, SetOptions(merge: true));

    return ProductModel.fromMap(data);
  }

  static Future<PurchaseModel?> _syncPurchase({
    required String userId,
    required PurchaseModel purchase,
  }) async {
    final document = _userPurchasesRef(userId).doc(purchase.id);

    if (purchase.syncStatus == SyncStatus.synced && !purchase.isDeleted) {
      return purchase;
    }

    if (purchase.syncStatus == SyncStatus.pendingDelete || purchase.isDeleted) {
      await document.delete();
      return null;
    }

    final now = DateTime.now();

    final data = purchase
        .copyWith(
          createdAt: purchase.createdAt ?? now,
          updatedAt: purchase.updatedAt ?? now,
          lastSyncedAt: now,
          syncStatus: SyncStatus.synced,
          isDeleted: false,
        )
        .toMap();

    await document.set(data, SetOptions(merge: true));

    return PurchaseModel.fromMap(data);
  }
}
