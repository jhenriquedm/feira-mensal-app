import 'sync_status.dart';

class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final bool isActive;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSyncedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.lastSyncedAt,
    this.syncStatus = SyncStatus.pendingCreate,
    this.isDeleted = false,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? iconName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    SyncStatus? syncStatus,
    bool? isDeleted,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
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
      'iconName': iconName,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncStatus': syncStatus.name,
      'isDeleted': isDeleted,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'custom',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
      lastSyncedAt: DateTime.tryParse(map['lastSyncedAt'] as String? ?? ''),
      syncStatus: parseSyncStatus(map['syncStatus'] as String?),
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }
}
