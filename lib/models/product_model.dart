class ProductModel {
  final String id;
  final String name;
  final String categoryId;
  final String unit;
  final String? brand;
  final double? lastPrice;
  final bool isActive;

  const ProductModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.unit,
    this.brand,
    this.lastPrice,
    this.isActive = true,
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
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      unit: unit ?? this.unit,
      brand: clearBrand ? null : brand ?? this.brand,
      lastPrice: clearLastPrice ? null : lastPrice ?? this.lastPrice,
      isActive: isActive ?? this.isActive,
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
    );
  }
}
