import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user_model.dart';
import '../services/local_storage_service.dart';

final authProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel();
});

class AuthState {
  final List<AppUserModel> users;
  final AppUserModel? currentUser;
  final bool isLoading;

  const AuthState({
    required this.users,
    required this.currentUser,
    required this.isLoading,
  });

  bool get isAuthenticated => currentUser != null;

  AuthState copyWith({
    List<AppUserModel>? users,
    AppUserModel? currentUser,
    bool clearCurrentUser = false,
    bool? isLoading,
  }) {
    return AuthState(
      users: users ?? this.users,
      currentUser: clearCurrentUser ? null : currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel()
    : super(const AuthState(users: [], currentUser: null, isLoading: true)) {
    _loadSession();
  }

  final Uuid _uuid = const Uuid();

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final cleanedName = name.trim();
    final cleanedEmail = email.trim().toLowerCase();
    final cleanedPassword = password.trim();
    final cleanedConfirmPassword = confirmPassword.trim();

    final validationMessage = _validateRegisterFields(
      name: cleanedName,
      email: cleanedEmail,
      password: cleanedPassword,
      confirmPassword: cleanedConfirmPassword,
    );

    if (validationMessage != null) {
      return validationMessage;
    }

    final emailAlreadyExists = state.users.any((user) {
      return user.email.trim().toLowerCase() == cleanedEmail;
    });

    if (emailAlreadyExists) {
      return 'Este e-mail já está cadastrado.';
    }

    final user = AppUserModel(
      id: _uuid.v4(),
      name: cleanedName,
      email: cleanedEmail,
      password: cleanedPassword,
      createdAt: DateTime.now(),
    );

    final updatedUsers = [...state.users, user];

    state = state.copyWith(
      users: List.unmodifiable(updatedUsers),
      clearCurrentUser: true,
    );

    await LocalStorageService.saveUsers(updatedUsers);

    return null;
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final cleanedEmail = email.trim().toLowerCase();
    final cleanedPassword = password.trim();

    final validationMessage = _validateLoginFields(
      email: cleanedEmail,
      password: cleanedPassword,
    );

    if (validationMessage != null) {
      return validationMessage;
    }

    AppUserModel? foundUser;

    for (final user in state.users) {
      final sameEmail = user.email.trim().toLowerCase() == cleanedEmail;
      final samePassword = user.password == cleanedPassword;

      if (sameEmail && samePassword) {
        foundUser = user;
        break;
      }
    }

    if (foundUser == null) {
      return 'E-mail ou senha inválidos.';
    }

    state = state.copyWith(currentUser: foundUser);

    await LocalStorageService.saveCurrentUserId(foundUser.id);

    return null;
  }

  Future<void> logout() async {
    await LocalStorageService.clearCurrentUserSession();

    if (!mounted) {
      return;
    }

    state = state.copyWith(clearCurrentUser: true);
  }

  Future<void> _loadSession() async {
    final users = await LocalStorageService.loadUsers();
    final currentUserId = await LocalStorageService.loadCurrentUserId();

    AppUserModel? currentUser;

    if (currentUserId != null) {
      for (final user in users) {
        if (user.id == currentUserId) {
          currentUser = user;
          break;
        }
      }
    }

    if (!mounted) {
      return;
    }

    state = AuthState(
      users: List.unmodifiable(users),
      currentUser: currentUser,
      isLoading: false,
    );
  }

  String? _validateRegisterFields({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    if (name.isEmpty) {
      return 'Informe seu nome.';
    }

    if (name.length < 2) {
      return 'O nome deve ter pelo menos 2 caracteres.';
    }

    if (name.length > 40) {
      return 'O nome deve ter no máximo 40 caracteres.';
    }

    if (!_isValidEmail(email)) {
      return 'Informe um e-mail válido.';
    }

    if (password.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }

    if (password.length > 20) {
      return 'A senha deve ter no máximo 20 caracteres.';
    }

    if (password != confirmPassword) {
      return 'As senhas não conferem.';
    }

    return null;
  }

  String? _validateLoginFields({
    required String email,
    required String password,
  }) {
    if (!_isValidEmail(email)) {
      return 'Informe um e-mail válido.';
    }

    if (password.isEmpty) {
      return 'Informe sua senha.';
    }

    return null;
  }

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    return emailRegex.hasMatch(value);
  }
}
