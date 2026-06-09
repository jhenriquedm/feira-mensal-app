import 'purchase_item_model.dart';

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

  const PurchaseModel({
    required this.id,
    required this.name,
    required this.market,
    required this.date,
    required this.type,
    required this.status,
    required this.items,
    this.notes,
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
    );
  }
}
