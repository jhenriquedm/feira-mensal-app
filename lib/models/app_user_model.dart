class AppUserModel {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  const AppUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  AppUserModel copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
  }) {
    return AppUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
