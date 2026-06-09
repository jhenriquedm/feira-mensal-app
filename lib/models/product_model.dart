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
}
