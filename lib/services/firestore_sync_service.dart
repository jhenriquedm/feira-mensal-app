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

  static bool _isInvalidUser(String userId) {
    return userId.trim().isEmpty || userId == 'no_user';
  }

  static Future<ProductsSyncResult> syncProductsDataForUser({
    required String userId,
    required List<CategoryModel> categories,
    required List<ProductModel> products,
  }) async {
    if (_isInvalidUser(userId)) {
      return ProductsSyncResult(categories: categories, products: products);
    }

    final syncedCategories = <CategoryModel>[];
    final syncedProducts = <ProductModel>[];

    for (final category in categories) {
      final syncedCategory = await _syncCategory(
        userId: userId,
        category: category,
      );

      syncedCategories.add(syncedCategory);
    }

    for (final product in products) {
      final syncedProduct = await _syncProduct(
        userId: userId,
        product: product,
      );

      syncedProducts.add(syncedProduct);
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
    if (_isInvalidUser(userId)) {
      return PurchasesSyncResult(purchases: purchases);
    }

    final syncedPurchases = <PurchaseModel>[];

    for (final purchase in purchases) {
      final syncedPurchase = await _syncPurchase(
        userId: userId,
        purchase: purchase,
      );

      syncedPurchases.add(syncedPurchase);
    }

    return PurchasesSyncResult(purchases: syncedPurchases);
  }

  static Future<ProductsSyncResult> downloadProductsDataForUser({
    required String userId,
  }) async {
    if (_isInvalidUser(userId)) {
      return const ProductsSyncResult(categories: [], products: []);
    }

    final categoriesSnapshot = await _userCategoriesRef(userId).get();
    final productsSnapshot = await _userProductsRef(userId).get();

    final categories = categoriesSnapshot.docs.map((document) {
      final data = _documentDataWithId(document);

      return _normalizeDownloadedCategory(CategoryModel.fromMap(data));
    }).toList();

    final products = productsSnapshot.docs.map((document) {
      final data = _documentDataWithId(document);

      return _normalizeDownloadedProduct(ProductModel.fromMap(data));
    }).toList();

    return ProductsSyncResult(categories: categories, products: products);
  }

  static Future<PurchasesSyncResult> downloadPurchasesForUser({
    required String userId,
  }) async {
    if (_isInvalidUser(userId)) {
      return const PurchasesSyncResult(purchases: []);
    }

    final purchasesSnapshot = await _userPurchasesRef(userId).get();

    final purchases = purchasesSnapshot.docs.map((document) {
      final data = _documentDataWithId(document);

      return _normalizeDownloadedPurchase(PurchaseModel.fromMap(data));
    }).toList();

    return PurchasesSyncResult(purchases: purchases);
  }

  static Future<CategoryModel> _syncCategory({
    required String userId,
    required CategoryModel category,
  }) async {
    final document = _userCategoriesRef(userId).doc(category.id);

    if (category.syncStatus == SyncStatus.synced) {
      return category;
    }

    final now = DateTime.now();

    if (category.syncStatus == SyncStatus.pendingDelete || category.isDeleted) {
      final deletedCategory = category.copyWith(
        createdAt: category.createdAt ?? now,
        updatedAt: category.updatedAt ?? now,
        lastSyncedAt: now,
        syncStatus: SyncStatus.synced,
        isDeleted: true,
      );

      await document.set(deletedCategory.toMap(), SetOptions(merge: true));

      return deletedCategory;
    }

    final syncedCategory = category.copyWith(
      createdAt: category.createdAt ?? now,
      updatedAt: category.updatedAt ?? now,
      lastSyncedAt: now,
      syncStatus: SyncStatus.synced,
      isDeleted: false,
    );

    await document.set(syncedCategory.toMap(), SetOptions(merge: true));

    return syncedCategory;
  }

  static Future<ProductModel> _syncProduct({
    required String userId,
    required ProductModel product,
  }) async {
    final document = _userProductsRef(userId).doc(product.id);

    if (product.syncStatus == SyncStatus.synced) {
      return product;
    }

    final now = DateTime.now();

    if (product.syncStatus == SyncStatus.pendingDelete || product.isDeleted) {
      final deletedProduct = product.copyWith(
        createdAt: product.createdAt ?? now,
        updatedAt: product.updatedAt ?? now,
        lastSyncedAt: now,
        syncStatus: SyncStatus.synced,
        isDeleted: true,
      );

      await document.set(deletedProduct.toMap(), SetOptions(merge: true));

      return deletedProduct;
    }

    final syncedProduct = product.copyWith(
      createdAt: product.createdAt ?? now,
      updatedAt: product.updatedAt ?? now,
      lastSyncedAt: now,
      syncStatus: SyncStatus.synced,
      isDeleted: false,
    );

    await document.set(syncedProduct.toMap(), SetOptions(merge: true));

    return syncedProduct;
  }

  static Future<PurchaseModel> _syncPurchase({
    required String userId,
    required PurchaseModel purchase,
  }) async {
    final document = _userPurchasesRef(userId).doc(purchase.id);

    if (purchase.syncStatus == SyncStatus.synced) {
      return purchase;
    }

    final now = DateTime.now();

    if (purchase.syncStatus == SyncStatus.pendingDelete || purchase.isDeleted) {
      final deletedPurchase = purchase.copyWith(
        createdAt: purchase.createdAt ?? now,
        updatedAt: purchase.updatedAt ?? now,
        lastSyncedAt: now,
        syncStatus: SyncStatus.synced,
        isDeleted: true,
      );

      await document.set(deletedPurchase.toMap(), SetOptions(merge: true));

      return deletedPurchase;
    }

    final syncedPurchase = purchase.copyWith(
      createdAt: purchase.createdAt ?? now,
      updatedAt: purchase.updatedAt ?? now,
      lastSyncedAt: now,
      syncStatus: SyncStatus.synced,
      isDeleted: false,
    );

    await document.set(syncedPurchase.toMap(), SetOptions(merge: true));

    return syncedPurchase;
  }

  static CategoryModel _normalizeDownloadedCategory(CategoryModel category) {
    return category.copyWith(syncStatus: SyncStatus.synced);
  }

  static ProductModel _normalizeDownloadedProduct(ProductModel product) {
    return product.copyWith(syncStatus: SyncStatus.synced);
  }

  static PurchaseModel _normalizeDownloadedPurchase(PurchaseModel purchase) {
    return purchase.copyWith(syncStatus: SyncStatus.synced);
  }

  static Map<String, dynamic> _documentDataWithId(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = Map<String, dynamic>.from(document.data());

    data['id'] = data['id'] as String? ?? document.id;

    return data;
  }
}
