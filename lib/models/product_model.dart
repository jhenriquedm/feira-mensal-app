import 'sync_status.dart';

class ProductModel {
  final String id;
  final String name;
  final String categoryId;
  final String unit;
  final String? brand;
  final double? lastPrice;
  final bool isActive;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSyncedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const ProductModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.unit,
    this.brand,
    this.lastPrice,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.lastSyncedAt,
    this.syncStatus = SyncStatus.pendingCreate,
    this.isDeleted = false,
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? unit,
    String? brand,
    bool clearBrand = false,
    double? lastPrice,
    bool clearLastPrice = false,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    SyncStatus? syncStatus,
    bool? isDeleted,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      unit: unit ?? this.unit,
      brand: clearBrand ? null : brand ?? this.brand,
      lastPrice: clearLastPrice ? null : lastPrice ?? this.lastPrice,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : lastSyncedAt ?? this.lastSyncedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'unit': unit,
      'brand': brand,
      'lastPrice': lastPrice,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncStatus': syncStatus.name,
      'isDeleted': isDeleted,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? '',
      unit: map['unit'] as String? ?? '',
      brand: map['brand'] as String?,
      lastPrice: (map['lastPrice'] as num?)?.toDouble(),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
      lastSyncedAt: DateTime.tryParse(map['lastSyncedAt'] as String? ?? ''),
      syncStatus: parseSyncStatus(map['syncStatus'] as String?),
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }
}
