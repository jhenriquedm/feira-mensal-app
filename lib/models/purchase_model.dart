import 'purchase_item_model.dart';
import 'sync_status.dart';

enum PurchaseType { monthly, weekly, emergency, butcher, pharmacy, other }

extension PurchaseTypeExtension on PurchaseType {
  String get label {
    switch (this) {
      case PurchaseType.monthly:
        return 'Mensal';
      case PurchaseType.weekly:
        return 'Semanal';
      case PurchaseType.emergency:
        return 'Emergencial';
      case PurchaseType.butcher:
        return 'Açougue';
      case PurchaseType.pharmacy:
        return 'Farmácia';
      case PurchaseType.other:
        return 'Outros';
    }
  }
}

enum PurchaseStatus { inProgress, completed }

extension PurchaseStatusExtension on PurchaseStatus {
  String get label {
    switch (this) {
      case PurchaseStatus.inProgress:
        return 'Em andamento';
      case PurchaseStatus.completed:
        return 'Finalizada';
    }
  }
}

class PurchaseModel {
  final String id;
  final String name;
  final String market;
  final DateTime date;
  final PurchaseType type;
  final String? notes;
  final PurchaseStatus status;
  final List<PurchaseItemModel> items;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSyncedAt;
  final SyncStatus syncStatus;
  final bool isDeleted;

  const PurchaseModel({
    required this.id,
    required this.name,
    required this.market,
    required this.date,
    required this.type,
    required this.status,
    required this.items,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.lastSyncedAt,
    this.syncStatus = SyncStatus.pendingCreate,
    this.isDeleted = false,
  });

  double get total {
    return items.fold(0, (sum, item) => sum + item.total);
  }

  int get distinctItemsCount => items.length;

  double get totalQuantity {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get isCompleted => status == PurchaseStatus.completed;

  PurchaseModel copyWith({
    String? id,
    String? name,
    String? market,
    DateTime? date,
    PurchaseType? type,
    String? notes,
    bool clearNotes = false,
    PurchaseStatus? status,
    List<PurchaseItemModel>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
    bool clearLastSyncedAt = false,
    SyncStatus? syncStatus,
    bool? isDeleted,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      market: market ?? this.market,
      date: date ?? this.date,
      type: type ?? this.type,
      notes: clearNotes ? null : notes ?? this.notes,
      status: status ?? this.status,
      items: items ?? this.items,
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
      'market': market,
      'date': date.toIso8601String(),
      'type': type.name,
      'notes': notes,
      'status': status.name,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'syncStatus': syncStatus.name,
      'isDeleted': isDeleted,
    };
  }

  factory PurchaseModel.fromMap(Map<String, dynamic> map) {
    return PurchaseModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      market: map['market'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      type: _parsePurchaseType(map['type'] as String?),
      notes: map['notes'] as String?,
      status: _parsePurchaseStatus(map['status'] as String?),
      items: ((map['items'] as List?) ?? []).map((item) {
        return PurchaseItemModel.fromMap(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
      lastSyncedAt: DateTime.tryParse(map['lastSyncedAt'] as String? ?? ''),
      syncStatus: parseSyncStatus(map['syncStatus'] as String?),
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  static PurchaseType _parsePurchaseType(String? value) {
    return PurchaseType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => PurchaseType.monthly,
    );
  }

  static PurchaseStatus _parsePurchaseStatus(String? value) {
    return PurchaseStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PurchaseStatus.inProgress,
    );
  }
}
