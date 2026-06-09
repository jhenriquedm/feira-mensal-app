class PurchaseItemModel {
  final String id;

  // Referência ao cadastro original.
  final String productId;

  // Snapshot dos dados no momento da compra.
  final String productName;
  final String productBrand;
  final String categoryId;
  final String categoryName;
  final String unit;

  final double quantity;
  final double unitPrice;

  const PurchaseItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productBrand,
    required this.categoryId,
    required this.categoryName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  PurchaseItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productBrand,
    String? categoryId,
    String? categoryName,
    String? unit,
    double? quantity,
    double? unitPrice,
  }) {
    return PurchaseItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productBrand: productBrand ?? this.productBrand,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}
