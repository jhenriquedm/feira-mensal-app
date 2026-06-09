class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    this.isActive = true,
  });
}
