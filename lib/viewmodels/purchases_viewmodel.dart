import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/purchase_item_model.dart';
import '../models/purchase_model.dart';
import '../services/local_storage_service.dart';

final purchasesProvider =
    StateNotifierProvider<PurchasesViewModel, PurchasesState>((ref) {
      return PurchasesViewModel();
    });

final productIdsLinkedToPurchasesProvider = Provider<Set<String>>((ref) {
  final purchases = ref.watch(purchasesProvider).purchases;

  return purchases
      .expand((purchase) => purchase.items)
      .map((item) => item.productId)
      .toSet();
});

class PurchasesState {
  final List<PurchaseModel> purchases;

  const PurchasesState({required this.purchases});

  PurchasesState copyWith({List<PurchaseModel>? purchases}) {
    return PurchasesState(purchases: purchases ?? this.purchases);
  }
}

class PurchasesViewModel extends StateNotifier<PurchasesState> {
  PurchasesViewModel() : super(const PurchasesState(purchases: [])) {
    _loadSavedPurchases();
  }

  final Uuid _uuid = const Uuid();

  List<PurchaseModel> get sortedPurchases {
    final purchases = [...state.purchases];

    purchases.sort((first, second) {
      return second.date.compareTo(first.date);
    });

    return purchases;
  }

  PurchaseModel? findPurchaseById(String purchaseId) {
    for (final purchase in state.purchases) {
      if (purchase.id == purchaseId) {
        return purchase;
      }
    }

    return null;
  }

  bool purchaseAlreadyExists({
    required String name,
    required String market,
    required DateTime date,
    String? ignorePurchaseId,
  }) {
    final normalizedName = _normalize(name);
    final normalizedMarket = _normalize(market);

    return state.purchases.any((purchase) {
      final sameName = _normalize(purchase.name) == normalizedName;
      final sameMarket = _normalize(purchase.market) == normalizedMarket;
      final sameDate = _isSameDay(purchase.date, date);

      final isPurchaseBeingEdited =
          ignorePurchaseId != null && purchase.id == ignorePurchaseId;

      return sameName && sameMarket && sameDate && !isPurchaseBeingEdited;
    });
  }

  void addPurchase({
    required String name,
    required String market,
    required DateTime date,
    required PurchaseType type,
    String? notes,
  }) {
    final purchase = PurchaseModel(
      id: _uuid.v4(),
      name: name.trim(),
      market: market.trim(),
      date: date,
      type: type,
      notes: _nullableText(notes),
      status: PurchaseStatus.inProgress,
      items: const [],
    );

    _emitPurchases([...state.purchases, purchase]);
  }

  void updatePurchase({
    required String id,
    required String name,
    required String market,
    required DateTime date,
    required PurchaseType type,
    String? notes,
  }) {
    final updatedPurchases = state.purchases.map((purchase) {
      if (purchase.id != id) {
        return purchase;
      }

      return purchase.copyWith(
        name: name.trim(),
        market: market.trim(),
        date: date,
        type: type,
        notes: _nullableText(notes),
        clearNotes: notes == null || notes.trim().isEmpty,
      );
    }).toList();

    _emitPurchases(updatedPurchases);
  }

  bool canDeletePurchase(String purchaseId) {
    final purchase = findPurchaseById(purchaseId);

    if (purchase == null) {
      return false;
    }

    return purchase.items.isEmpty;
  }

  void deletePurchase(String purchaseId) {
    final updatedPurchases = state.purchases
        .where((purchase) => purchase.id != purchaseId)
        .toList();

    _emitPurchases(updatedPurchases);
  }

  void completePurchase(String purchaseId) {
    _updatePurchaseStatus(
      purchaseId: purchaseId,
      status: PurchaseStatus.completed,
    );
  }

  void reopenPurchase(String purchaseId) {
    _updatePurchaseStatus(
      purchaseId: purchaseId,
      status: PurchaseStatus.inProgress,
    );
  }

  bool productAlreadyAdded({
    required String purchaseId,
    required String productId,
    String? ignoreItemId,
  }) {
    final purchase = findPurchaseById(purchaseId);

    if (purchase == null) {
      return false;
    }

    return purchase.items.any((item) {
      final sameProduct = item.productId == productId;
      final isItemBeingEdited = ignoreItemId != null && item.id == ignoreItemId;

      return sameProduct && !isItemBeingEdited;
    });
  }

  bool addItem({
    required String purchaseId,
    required String productId,
    required String productName,
    required String productBrand,
    required String categoryId,
    required String categoryName,
    required String unit,
    required double quantity,
    required double unitPrice,
  }) {
    final purchase = findPurchaseById(purchaseId);

    if (purchase == null || purchase.isCompleted) {
      return false;
    }

    if (productAlreadyAdded(purchaseId: purchaseId, productId: productId)) {
      return false;
    }

    final item = PurchaseItemModel(
      id: _uuid.v4(),
      productId: productId,
      productName: productName.trim(),
      productBrand: productBrand.trim(),
      categoryId: categoryId,
      categoryName: categoryName.trim(),
      unit: unit,
      quantity: quantity,
      unitPrice: unitPrice,
    );

    final updatedPurchases = state.purchases.map((currentPurchase) {
      if (currentPurchase.id != purchaseId) {
        return currentPurchase;
      }

      return currentPurchase.copyWith(items: [...currentPurchase.items, item]);
    }).toList();

    _emitPurchases(updatedPurchases);

    return true;
  }

  bool updateItem({
    required String purchaseId,
    required String itemId,
    required String productId,
    required String productName,
    required String productBrand,
    required String categoryId,
    required String categoryName,
    required String unit,
    required double quantity,
    required double unitPrice,
  }) {
    final purchase = findPurchaseById(purchaseId);

    if (purchase == null || purchase.isCompleted) {
      return false;
    }

    if (productAlreadyAdded(
      purchaseId: purchaseId,
      productId: productId,
      ignoreItemId: itemId,
    )) {
      return false;
    }

    final updatedItems = purchase.items.map((item) {
      if (item.id != itemId) {
        return item;
      }

      return item.copyWith(
        productId: productId,
        productName: productName.trim(),
        productBrand: productBrand.trim(),
        categoryId: categoryId,
        categoryName: categoryName.trim(),
        unit: unit,
        quantity: quantity,
        unitPrice: unitPrice,
      );
    }).toList();

    _replacePurchase(purchase.copyWith(items: updatedItems));

    return true;
  }

  bool deleteItem({required String purchaseId, required String itemId}) {
    final purchase = findPurchaseById(purchaseId);

    if (purchase == null || purchase.isCompleted) {
      return false;
    }

    final updatedItems = purchase.items
        .where((item) => item.id != itemId)
        .toList();

    _replacePurchase(purchase.copyWith(items: updatedItems));

    return true;
  }

  bool isProductLinked(String productId) {
    return state.purchases.any((purchase) {
      return purchase.items.any((item) {
        return item.productId == productId;
      });
    });
  }

  Future<void> _loadSavedPurchases() async {
    final savedPurchases = await LocalStorageService.loadPurchases();

    if (!mounted || savedPurchases == null) {
      return;
    }

    state = state.copyWith(purchases: List.unmodifiable(savedPurchases));
  }

  void _updatePurchaseStatus({
    required String purchaseId,
    required PurchaseStatus status,
  }) {
    final updatedPurchases = state.purchases.map((purchase) {
      if (purchase.id != purchaseId) {
        return purchase;
      }

      return purchase.copyWith(status: status);
    }).toList();

    _emitPurchases(updatedPurchases);
  }

  void _replacePurchase(PurchaseModel updatedPurchase) {
    final updatedPurchases = state.purchases.map((purchase) {
      if (purchase.id == updatedPurchase.id) {
        return updatedPurchase;
      }

      return purchase;
    }).toList();

    _emitPurchases(updatedPurchases);
  }

  void _emitPurchases(List<PurchaseModel> purchases) {
    if (!mounted) {
      return;
    }

    state = state.copyWith(purchases: List.unmodifiable(purchases));

    _saveLocalData();
  }

  void _saveLocalData() {
    LocalStorageService.savePurchases(state.purchases);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  String? _nullableText(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}
