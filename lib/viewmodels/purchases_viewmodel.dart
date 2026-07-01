import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/purchase_item_model.dart';
import '../models/purchase_model.dart';
import '../models/sync_status.dart';
import '../services/firestore_sync_service.dart';
import '../services/local_storage_service.dart';
import 'auth_viewmodel.dart';

final purchasesProvider =
    StateNotifierProvider<PurchasesViewModel, PurchasesState>((ref) {
      final currentUserId = ref.watch(
        authProvider.select((state) {
          return state.currentUser?.id;
        }),
      );

      return PurchasesViewModel(userId: currentUserId ?? 'no_user');
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
  final List<PurchaseModel> deletedPurchases;

  const PurchasesState({
    required this.purchases,
    this.deletedPurchases = const [],
  });

  List<PurchaseModel> get allPurchasesForStorage {
    return [...purchases, ...deletedPurchases];
  }

  PurchasesState copyWith({
    List<PurchaseModel>? purchases,
    List<PurchaseModel>? deletedPurchases,
  }) {
    return PurchasesState(
      purchases: purchases ?? this.purchases,
      deletedPurchases: deletedPurchases ?? this.deletedPurchases,
    );
  }
}

class PurchasesViewModel extends StateNotifier<PurchasesState> {
  final String userId;

  PurchasesViewModel({required this.userId})
    : super(const PurchasesState(purchases: [])) {
    _loadSavedPurchases();
  }

  final Uuid _uuid = const Uuid();

  bool _isSyncing = false;
  bool _syncAgainRequested = false;

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
    final now = DateTime.now();

    final purchase = PurchaseModel(
      id: _uuid.v4(),
      name: name.trim(),
      market: market.trim(),
      date: date,
      type: type,
      notes: _nullableText(notes),
      status: PurchaseStatus.inProgress,
      items: const [],
      createdAt: now,
      updatedAt: now,
      lastSyncedAt: null,
      syncStatus: SyncStatus.pendingCreate,
      isDeleted: false,
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
    final now = DateTime.now();

    final updatedPurchases = state.purchases.map((purchase) {
      if (purchase.id != id) {
        return purchase;
      }

      final updatedPurchase = purchase.copyWith(
        name: name.trim(),
        market: market.trim(),
        date: date,
        type: type,
        notes: _nullableText(notes),
        clearNotes: notes == null || notes.trim().isEmpty,
      );

      return _markPurchaseAsUpdated(updatedPurchase, now);
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
    final purchase = findPurchaseById(purchaseId);

    if (purchase == null) {
      return;
    }

    final visiblePurchases = state.purchases
        .where((currentPurchase) => currentPurchase.id != purchaseId)
        .toList();

    if (purchase.syncStatus == SyncStatus.pendingCreate) {
      _emitPurchases(visiblePurchases);
      return;
    }

    final deletedPurchase = _markPurchaseAsDeleted(purchase, DateTime.now());

    final deletedPurchases = [
      ...state.deletedPurchases.where((item) => item.id != purchaseId),
      deletedPurchase,
    ];

    _emitPurchases(visiblePurchases, deletedPurchases: deletedPurchases);
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

    final now = DateTime.now();

    final updatedPurchases = state.purchases.map((currentPurchase) {
      if (currentPurchase.id != purchaseId) {
        return currentPurchase;
      }

      final updatedPurchase = currentPurchase.copyWith(
        items: [...currentPurchase.items, item],
      );

      return _markPurchaseAsUpdated(updatedPurchase, now);
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

    final updatedPurchase = purchase.copyWith(items: updatedItems);

    _replacePurchase(_markPurchaseAsUpdated(updatedPurchase, DateTime.now()));

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

    final updatedPurchase = purchase.copyWith(items: updatedItems);

    _replacePurchase(_markPurchaseAsUpdated(updatedPurchase, DateTime.now()));

    return true;
  }

  bool isProductLinked(String productId) {
    return state.purchases.any((purchase) {
      return purchase.items.any((item) {
        return item.productId == productId;
      });
    });
  }

  void clearAllPurchases() {
    final now = DateTime.now();

    final deletedPurchases = [
      ...state.deletedPurchases,
      ...state.purchases
          .where((purchase) {
            return purchase.syncStatus != SyncStatus.pendingCreate;
          })
          .map((purchase) {
            return _markPurchaseAsDeleted(purchase, now);
          }),
    ];

    _emitPurchases(const [], deletedPurchases: deletedPurchases);
  }

  Future<void> _loadSavedPurchases() async {
    final savedPurchases = await LocalStorageService.loadPurchasesForUser(
      userId: userId,
    );

    if (!mounted) {
      return;
    }

    if (savedPurchases == null) {
      state = const PurchasesState(purchases: []);
    } else {
      _applyPurchasesData(purchases: savedPurchases, saveAfterApply: false);
    }

    await _downloadPurchasesFromFirestore();

    if (!mounted) {
      return;
    }

    _saveLocalData();
    _trySyncPurchases();
  }

  Future<void> _downloadPurchasesFromFirestore() async {
    if (userId.trim().isEmpty || userId == 'no_user') {
      return;
    }

    try {
      final remoteData = await FirestoreSyncService.downloadPurchasesForUser(
        userId: userId,
      );

      if (!mounted) {
        return;
      }

      if (remoteData.purchases.isEmpty) {
        return;
      }

      final mergedPurchases = _mergePurchases(
        local: state.allPurchasesForStorage,
        remote: remoteData.purchases,
      );

      _applyPurchasesData(purchases: mergedPurchases);
    } catch (_) {
      // Se estiver offline, mantém apenas os dados locais.
    }
  }

  void _applyPurchasesData({
    required List<PurchaseModel> purchases,
    bool saveAfterApply = true,
  }) {
    if (!mounted) {
      return;
    }

    final visiblePurchases = purchases
        .where((purchase) => !purchase.isDeleted)
        .toList();

    final deletedPurchases = purchases
        .where((purchase) => purchase.isDeleted)
        .toList();

    state = PurchasesState(
      purchases: List.unmodifiable(visiblePurchases),
      deletedPurchases: List.unmodifiable(deletedPurchases),
    );

    if (saveAfterApply) {
      _saveLocalData();
    }
  }

  List<PurchaseModel> _mergePurchases({
    required List<PurchaseModel> local,
    required List<PurchaseModel> remote,
  }) {
    final merged = <String, PurchaseModel>{};

    for (final purchase in local) {
      merged[purchase.id] = purchase;
    }

    for (final remotePurchase in remote) {
      final localPurchase = merged[remotePurchase.id];

      if (localPurchase == null) {
        merged[remotePurchase.id] = remotePurchase;
        continue;
      }

      merged[remotePurchase.id] = _choosePurchaseVersion(
        local: localPurchase,
        remote: remotePurchase,
      );
    }

    return merged.values.toList();
  }

  PurchaseModel _choosePurchaseVersion({
    required PurchaseModel local,
    required PurchaseModel remote,
  }) {
    if (local.syncStatus.hasPendingChanges) {
      return local;
    }

    final localDate = _purchaseUpdatedAt(local);
    final remoteDate = _purchaseUpdatedAt(remote);

    if (remoteDate.isAfter(localDate)) {
      return remote;
    }

    return local;
  }

  DateTime _purchaseUpdatedAt(PurchaseModel purchase) {
    return purchase.updatedAt ??
        purchase.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _updatePurchaseStatus({
    required String purchaseId,
    required PurchaseStatus status,
  }) {
    final now = DateTime.now();

    final updatedPurchases = state.purchases.map((purchase) {
      if (purchase.id != purchaseId) {
        return purchase;
      }

      final updatedPurchase = purchase.copyWith(status: status);

      return _markPurchaseAsUpdated(updatedPurchase, now);
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

  void _emitPurchases(
    List<PurchaseModel> purchases, {
    List<PurchaseModel>? deletedPurchases,
  }) {
    if (!mounted) {
      return;
    }

    state = state.copyWith(
      purchases: List.unmodifiable(purchases),
      deletedPurchases: List.unmodifiable(
        deletedPurchases ?? state.deletedPurchases,
      ),
    );

    _saveLocalData();
    _trySyncPurchases();
  }

  void _saveLocalData() {
    LocalStorageService.savePurchasesForUser(
      userId: userId,
      purchases: state.allPurchasesForStorage,
    );
  }

  Future<void> _trySyncPurchases() async {
    if (userId.trim().isEmpty || userId == 'no_user') {
      return;
    }

    if (_isSyncing) {
      _syncAgainRequested = true;
      return;
    }

    _isSyncing = true;

    final purchasesSnapshot = state.allPurchasesForStorage;

    try {
      final result = await FirestoreSyncService.syncPurchasesForUser(
        userId: userId,
        purchases: purchasesSnapshot,
      );

      if (!mounted) {
        return;
      }

      if (_syncAgainRequested) {
        return;
      }

      final visiblePurchases = result.purchases
          .where((purchase) => !purchase.isDeleted)
          .toList();

      final deletedPurchases = result.purchases
          .where((purchase) => purchase.isDeleted)
          .toList();

      state = PurchasesState(
        purchases: List.unmodifiable(visiblePurchases),
        deletedPurchases: List.unmodifiable(deletedPurchases),
      );

      _saveLocalData();
    } catch (_) {
      // Se estiver offline ou o Firestore falhar, mantemos tudo pendente localmente.
    } finally {
      _isSyncing = false;

      if (_syncAgainRequested) {
        _syncAgainRequested = false;
        _trySyncPurchases();
      }
    }
  }

  PurchaseModel _markPurchaseAsUpdated(PurchaseModel purchase, DateTime now) {
    final nextSyncStatus = purchase.syncStatus == SyncStatus.pendingCreate
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    return purchase.copyWith(
      createdAt: purchase.createdAt ?? now,
      updatedAt: now,
      clearLastSyncedAt: true,
      syncStatus: nextSyncStatus,
      isDeleted: false,
    );
  }

  PurchaseModel _markPurchaseAsDeleted(PurchaseModel purchase, DateTime now) {
    return purchase.copyWith(
      createdAt: purchase.createdAt ?? now,
      updatedAt: now,
      clearLastSyncedAt: true,
      syncStatus: SyncStatus.pendingDelete,
      isDeleted: true,
    );
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
