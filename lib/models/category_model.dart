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

  CategoryModel copyWith({
    String? id,
    String? name,
    String? iconName,
    bool? isActive,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'iconName': iconName, 'isActive': isActive};
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'custom',
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}
