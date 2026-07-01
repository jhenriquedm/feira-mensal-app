import 'app_user_model.dart';

class OfflineSessionModel {
  final String userId;
  final String name;
  final String email;
  final DateTime firstOnlineLoginAt;
  final DateTime lastOnlineLoginAt;
  final DateTime lastAccessAt;
  final bool canUseOffline;

  const OfflineSessionModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.firstOnlineLoginAt,
    required this.lastOnlineLoginAt,
    required this.lastAccessAt,
    required this.canUseOffline,
  });

  OfflineSessionModel copyWith({
    String? userId,
    String? name,
    String? email,
    DateTime? firstOnlineLoginAt,
    DateTime? lastOnlineLoginAt,
    DateTime? lastAccessAt,
    bool? canUseOffline,
  }) {
    return OfflineSessionModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      firstOnlineLoginAt: firstOnlineLoginAt ?? this.firstOnlineLoginAt,
      lastOnlineLoginAt: lastOnlineLoginAt ?? this.lastOnlineLoginAt,
      lastAccessAt: lastAccessAt ?? this.lastAccessAt,
      canUseOffline: canUseOffline ?? this.canUseOffline,
    );
  }

  AppUserModel toAppUser() {
    return AppUserModel(
      id: userId,
      name: name,
      email: email,
      createdAt: firstOnlineLoginAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'firstOnlineLoginAt': firstOnlineLoginAt.toIso8601String(),
      'lastOnlineLoginAt': lastOnlineLoginAt.toIso8601String(),
      'lastAccessAt': lastAccessAt.toIso8601String(),
      'canUseOffline': canUseOffline,
    };
  }

  factory OfflineSessionModel.fromMap(Map<String, dynamic> map) {
    return OfflineSessionModel(
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      firstOnlineLoginAt:
          DateTime.tryParse(map['firstOnlineLoginAt'] as String? ?? '') ??
          DateTime.now(),
      lastOnlineLoginAt:
          DateTime.tryParse(map['lastOnlineLoginAt'] as String? ?? '') ??
          DateTime.now(),
      lastAccessAt:
          DateTime.tryParse(map['lastAccessAt'] as String? ?? '') ??
          DateTime.now(),
      canUseOffline: map['canUseOffline'] as bool? ?? false,
    );
  }
}
