import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/sync_status.dart';
import '../services/firestore_sync_service.dart';
import '../services/local_storage_service.dart';
import 'auth_viewmodel.dart';

const List<CategoryModel> defaultCategories = [
  CategoryModel(id: 'bebidas', name: 'Bebidas', iconName: 'bebidas'),
  CategoryModel(id: 'carnes', name: 'Carnes', iconName: 'carnes'),
  CategoryModel(id: 'cereais', name: 'Cereais', iconName: 'cereais'),
  CategoryModel(id: 'higiene', name: 'Higiene pessoal', iconName: 'higiene'),
  CategoryModel(
    id: 'limpeza',
    name: 'Produtos de limpeza',
    iconName: 'limpeza',
  ),
  CategoryModel(id: 'outros', name: 'Outros', iconName: 'outros'),
];

final productsProvider =
    StateNotifierProvider<ProductsViewModel, ProductsState>((ref) {
      final currentUserId = ref.watch(
        authProvider.select((state) {
          return state.currentUser?.id;
        }),
      );

      return ProductsViewModel(userId: currentUserId ?? 'no_user');
    });

class ProductsState {
  final List<CategoryModel> categories;
  final List<ProductModel> products;

  final List<CategoryModel> deletedCategories;
  final List<ProductModel> deletedProducts;

  const ProductsState({
    required this.categories,
    required this.products,
    this.deletedCategories = const [],
    this.deletedProducts = const [],
  });

  List<CategoryModel> get allCategoriesForStorage {
    return [...categories, ...deletedCategories];
  }

  List<ProductModel> get allProductsForStorage {
    return [...products, ...deletedProducts];
  }

  ProductsState copyWith({
    List<CategoryModel>? categories,
    List<ProductModel>? products,
    List<CategoryModel>? deletedCategories,
    List<ProductModel>? deletedProducts,
  }) {
    return ProductsState(
      categories: categories ?? this.categories,
      products: products ?? this.products,
      deletedCategories: deletedCategories ?? this.deletedCategories,
      deletedProducts: deletedProducts ?? this.deletedProducts,
    );
  }
}

class ProductsViewModel extends StateNotifier<ProductsState> {
  final String userId;

  ProductsViewModel({required this.userId})
    : super(const ProductsState(categories: defaultCategories, products: [])) {
    _loadSavedProductsData();
  }

  final Uuid _uuid = const Uuid();

  bool _isSyncing = false;
  bool _syncAgainRequested = false;

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
    final now = DateTime.now();

    final category = CategoryModel(
      id: _uuid.v4(),
      name: name.trim(),
      iconName: 'custom',
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
      lastSyncedAt: null,
      syncStatus: SyncStatus.pendingCreate,
      isDeleted: false,
    );

    _emitState(state.copyWith(categories: [...state.categories, category]));
  }

  void updateCategory({
    required String id,
    required String name,
    required bool isActive,
  }) {
    final now = DateTime.now();

    final updatedCategories = state.categories.map((category) {
      if (category.id != id) {
        return category;
      }

      final updatedCategory = category.copyWith(
        name: name.trim(),
        isActive: isActive,
      );

      return _markCategoryAsUpdated(updatedCategory, now);
    }).toList();

    _emitState(state.copyWith(categories: updatedCategories));
  }

  bool canDeleteCategory(String categoryId) {
    return !state.products.any((product) {
      return product.categoryId == categoryId;
    });
  }

  void deleteCategory(String categoryId) {
    final category = _findCategoryById(categoryId);

    if (category == null) {
      return;
    }

    final visibleCategories = state.categories
        .where((currentCategory) => currentCategory.id != categoryId)
        .toList();

    if (category.syncStatus == SyncStatus.pendingCreate) {
      _emitState(state.copyWith(categories: visibleCategories));
      return;
    }

    final deletedCategory = _markCategoryAsDeleted(category, DateTime.now());

    final deletedCategories = [
      ...state.deletedCategories.where((item) => item.id != categoryId),
      deletedCategory,
    ];

    _emitState(
      state.copyWith(
        categories: visibleCategories,
        deletedCategories: deletedCategories,
      ),
    );
  }

  void addProduct({
    required String name,
    required String categoryId,
    required String unit,
    required String brand,
    required bool isActive,
  }) {
    final now = DateTime.now();

    final product = ProductModel(
      id: _uuid.v4(),
      name: name.trim(),
      categoryId: categoryId,
      unit: unit,
      brand: brand.trim(),
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
      lastSyncedAt: null,
      syncStatus: SyncStatus.pendingCreate,
      isDeleted: false,
    );

    _emitState(state.copyWith(products: [...state.products, product]));
  }

  void updateProduct({
    required String id,
    required String name,
    required String categoryId,
    required String unit,
    required String brand,
    required bool isActive,
  }) {
    final now = DateTime.now();

    final updatedProducts = state.products.map((product) {
      if (product.id != id) {
        return product;
      }

      final updatedProduct = product.copyWith(
        name: name.trim(),
        categoryId: categoryId,
        unit: unit,
        brand: brand.trim(),
        isActive: isActive,
      );

      return _markProductAsUpdated(updatedProduct, now);
    }).toList();

    _emitState(state.copyWith(products: updatedProducts));
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
    final product = _findProductById(id);

    if (product == null) {
      return;
    }

    final visibleProducts = state.products
        .where((currentProduct) => currentProduct.id != id)
        .toList();

    if (product.syncStatus == SyncStatus.pendingCreate) {
      _emitState(state.copyWith(products: visibleProducts));
      return;
    }

    final deletedProduct = _markProductAsDeleted(product, DateTime.now());

    final deletedProducts = [
      ...state.deletedProducts.where((item) => item.id != id),
      deletedProduct,
    ];

    _emitState(
      state.copyWith(
        products: visibleProducts,
        deletedProducts: deletedProducts,
      ),
    );
  }

  void resetProductsAndCategories() {
    final now = DateTime.now();
    final defaultCategoryIds = defaultCategories.map((item) => item.id).toSet();

    final deletedCategories = [
      ...state.deletedCategories.where((category) {
        return !defaultCategoryIds.contains(category.id);
      }),
      ...state.categories
          .where((category) {
            return !defaultCategoryIds.contains(category.id) &&
                category.syncStatus != SyncStatus.pendingCreate;
          })
          .map((category) {
            return _markCategoryAsDeleted(category, now);
          }),
    ];

    final deletedProducts = [
      ...state.deletedProducts,
      ...state.products
          .where((product) {
            return product.syncStatus != SyncStatus.pendingCreate;
          })
          .map((product) {
            return _markProductAsDeleted(product, now);
          }),
    ];

    final categories = defaultCategories.map((defaultCategory) {
      final existingCategory = _findCategoryById(defaultCategory.id);

      if (existingCategory == null) {
        return defaultCategory.copyWith(
          createdAt: now,
          updatedAt: now,
          clearLastSyncedAt: true,
          syncStatus: SyncStatus.pendingCreate,
          isDeleted: false,
        );
      }

      final restoredCategory = existingCategory.copyWith(
        name: defaultCategory.name,
        iconName: defaultCategory.iconName,
        isActive: true,
        isDeleted: false,
      );

      return _markCategoryAsUpdated(restoredCategory, now);
    }).toList();

    _emitState(
      ProductsState(
        categories: categories,
        products: const [],
        deletedCategories: deletedCategories,
        deletedProducts: deletedProducts,
      ),
    );
  }

  void restoreDefaultCategories() {
    final now = DateTime.now();

    final updatedCategories = [...state.categories];
    final deletedCategories = [...state.deletedCategories];

    for (final defaultCategory in defaultCategories) {
      final visibleIndex = updatedCategories.indexWhere((category) {
        return category.id == defaultCategory.id;
      });

      if (visibleIndex != -1) {
        final restoredCategory = updatedCategories[visibleIndex].copyWith(
          name: defaultCategory.name,
          iconName: defaultCategory.iconName,
          isActive: true,
        );

        updatedCategories[visibleIndex] = _markCategoryAsUpdated(
          restoredCategory,
          now,
        );

        continue;
      }

      final deletedIndex = deletedCategories.indexWhere((category) {
        return category.id == defaultCategory.id;
      });

      if (deletedIndex != -1) {
        final restoredCategory = deletedCategories[deletedIndex].copyWith(
          name: defaultCategory.name,
          iconName: defaultCategory.iconName,
          isActive: true,
          isDeleted: false,
        );

        deletedCategories.removeAt(deletedIndex);

        updatedCategories.add(_markCategoryAsUpdated(restoredCategory, now));

        continue;
      }

      updatedCategories.add(
        defaultCategory.copyWith(
          createdAt: now,
          updatedAt: now,
          clearLastSyncedAt: true,
          syncStatus: SyncStatus.pendingCreate,
          isDeleted: false,
        ),
      );
    }

    _emitState(
      state.copyWith(
        categories: updatedCategories,
        deletedCategories: deletedCategories,
      ),
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

  Future<void> _loadSavedProductsData() async {
    final savedData = await LocalStorageService.loadProductsDataForUser(
      userId: userId,
    );

    if (!mounted) {
      return;
    }

    if (savedData == null) {
      _emitState(
        ProductsState(
          categories: _preparedDefaultCategories(),
          products: const [],
        ),
      );
      return;
    }

    final visibleCategories = savedData.categories
        .where((category) => !category.isDeleted)
        .toList();

    final deletedCategories = savedData.categories
        .where((category) => category.isDeleted)
        .toList();

    final visibleProducts = savedData.products
        .where((product) => !product.isDeleted)
        .toList();

    final deletedProducts = savedData.products
        .where((product) => product.isDeleted)
        .toList();

    final categories = visibleCategories.isEmpty
        ? _preparedDefaultCategories()
        : visibleCategories;

    state = ProductsState(
      categories: List.unmodifiable(categories),
      products: List.unmodifiable(visibleProducts),
      deletedCategories: List.unmodifiable(deletedCategories),
      deletedProducts: List.unmodifiable(deletedProducts),
    );

    _trySyncProductsData();
  }

  void _emitState(ProductsState nextState) {
    if (!mounted) {
      return;
    }

    state = ProductsState(
      categories: List.unmodifiable(nextState.categories),
      products: List.unmodifiable(nextState.products),
      deletedCategories: List.unmodifiable(nextState.deletedCategories),
      deletedProducts: List.unmodifiable(nextState.deletedProducts),
    );

    _saveLocalData();
    _trySyncProductsData();
  }

  void _saveLocalData() {
    LocalStorageService.saveProductsDataForUser(
      userId: userId,
      categories: state.allCategoriesForStorage,
      products: state.allProductsForStorage,
    );
  }

  Future<void> _trySyncProductsData() async {
    if (userId.trim().isEmpty || userId == 'no_user') {
      return;
    }

    if (_isSyncing) {
      _syncAgainRequested = true;
      return;
    }

    _isSyncing = true;

    final categoriesSnapshot = state.allCategoriesForStorage;
    final productsSnapshot = state.allProductsForStorage;

    try {
      final result = await FirestoreSyncService.syncProductsDataForUser(
        userId: userId,
        categories: categoriesSnapshot,
        products: productsSnapshot,
      );

      if (!mounted) {
        return;
      }

      if (_syncAgainRequested) {
        return;
      }

      final visibleCategories = result.categories
          .where((category) => !category.isDeleted)
          .toList();

      final deletedCategories = result.categories
          .where((category) => category.isDeleted)
          .toList();

      final visibleProducts = result.products
          .where((product) => !product.isDeleted)
          .toList();

      final deletedProducts = result.products
          .where((product) => product.isDeleted)
          .toList();

      state = ProductsState(
        categories: List.unmodifiable(visibleCategories),
        products: List.unmodifiable(visibleProducts),
        deletedCategories: List.unmodifiable(deletedCategories),
        deletedProducts: List.unmodifiable(deletedProducts),
      );

      _saveLocalData();
    } catch (_) {
      // Se estiver offline ou o Firestore falhar, mantemos tudo pendente localmente.
    } finally {
      _isSyncing = false;

      if (_syncAgainRequested) {
        _syncAgainRequested = false;
        _trySyncProductsData();
      }
    }
  }

  CategoryModel? _findCategoryById(String id) {
    for (final category in state.categories) {
      if (category.id == id) {
        return category;
      }
    }

    return null;
  }

  ProductModel? _findProductById(String id) {
    for (final product in state.products) {
      if (product.id == id) {
        return product;
      }
    }

    return null;
  }

  List<CategoryModel> _preparedDefaultCategories() {
    final now = DateTime.now();

    return defaultCategories.map((category) {
      return category.copyWith(
        createdAt: category.createdAt ?? now,
        updatedAt: category.updatedAt ?? now,
        clearLastSyncedAt: true,
        syncStatus: SyncStatus.pendingCreate,
        isDeleted: false,
      );
    }).toList();
  }

  CategoryModel _markCategoryAsUpdated(CategoryModel category, DateTime now) {
    final nextSyncStatus = category.syncStatus == SyncStatus.pendingCreate
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    return category.copyWith(
      createdAt: category.createdAt ?? now,
      updatedAt: now,
      clearLastSyncedAt: true,
      syncStatus: nextSyncStatus,
      isDeleted: false,
    );
  }

  CategoryModel _markCategoryAsDeleted(CategoryModel category, DateTime now) {
    return category.copyWith(
      createdAt: category.createdAt ?? now,
      updatedAt: now,
      clearLastSyncedAt: true,
      syncStatus: SyncStatus.pendingDelete,
      isDeleted: true,
    );
  }

  ProductModel _markProductAsUpdated(ProductModel product, DateTime now) {
    final nextSyncStatus = product.syncStatus == SyncStatus.pendingCreate
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    return product.copyWith(
      createdAt: product.createdAt ?? now,
      updatedAt: now,
      clearLastSyncedAt: true,
      syncStatus: nextSyncStatus,
      isDeleted: false,
    );
  }

  ProductModel _markProductAsDeleted(ProductModel product, DateTime now) {
    return product.copyWith(
      createdAt: product.createdAt ?? now,
      updatedAt: now,
      clearLastSyncedAt: true,
      syncStatus: SyncStatus.pendingDelete,
      isDeleted: true,
    );
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}
