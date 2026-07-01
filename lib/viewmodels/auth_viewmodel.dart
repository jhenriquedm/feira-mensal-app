import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user_model.dart';
import '../models/offline_session_model.dart';
import '../services/local_storage_service.dart';

final authProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel();
});

class AuthState {
  final List<AppUserModel> users;
  final AppUserModel? currentUser;
  final bool isLoading;
  final bool isOfflineMode;
  final OfflineSessionModel? offlineSession;

  const AuthState({
    required this.users,
    required this.currentUser,
    required this.isLoading,
    this.isOfflineMode = false,
    this.offlineSession,
  });

  bool get isAuthenticated => currentUser != null;

  AuthState copyWith({
    List<AppUserModel>? users,
    AppUserModel? currentUser,
    bool clearCurrentUser = false,
    bool? isLoading,
    bool? isOfflineMode,
    OfflineSessionModel? offlineSession,
    bool clearOfflineSession = false,
  }) {
    return AuthState(
      users: users ?? this.users,
      currentUser: clearCurrentUser ? null : currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      isOfflineMode: clearCurrentUser
          ? false
          : isOfflineMode ?? this.isOfflineMode,
      offlineSession: clearCurrentUser || clearOfflineSession
          ? null
          : offlineSession ?? this.offlineSession,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel()
    : super(const AuthState(users: [], currentUser: null, isLoading: true)) {
    _loadSession();
  }

  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

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

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: cleanedEmail,
        password: cleanedPassword,
      );

      await credential.user?.updateDisplayName(cleanedName);
      await credential.user?.reload();

      // O Firebase faz login automaticamente após criar a conta.
      // Mantemos o fluxo atual do app: cadastro concluído e retorno para tela de login.
      await _firebaseAuth.signOut();

      if (!mounted) {
        return null;
      }

      state = state.copyWith(
        users: const [],
        clearCurrentUser: true,
        clearOfflineSession: true,
        isLoading: false,
      );

      return null;
    } on FirebaseAuthException catch (error) {
      return _mapFirebaseAuthError(error);
    } catch (_) {
      return 'Não foi possível criar a conta. Verifique sua conexão e tente novamente.';
    }
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

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: cleanedEmail,
        password: cleanedPassword,
      );

      final user = credential.user;

      if (user == null) {
        return 'Não foi possível acessar a conta. Tente novamente.';
      }

      await user.reload();

      final refreshedUser = _firebaseAuth.currentUser ?? user;
      final appUser = _mapFirebaseUser(refreshedUser);
      final offlineSession = await _buildOfflineSession(appUser);

      await LocalStorageService.saveOfflineSession(offlineSession);

      if (!mounted) {
        return null;
      }

      state = state.copyWith(
        users: const [],
        currentUser: appUser,
        isLoading: false,
        isOfflineMode: false,
        offlineSession: offlineSession,
      );

      return null;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'network-request-failed') {
        return _loginWithOfflineSession(cleanedEmail);
      }

      return _mapFirebaseAuthError(error);
    } catch (_) {
      return _loginWithOfflineSession(cleanedEmail);
    }
  }

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (_) {
      // Mesmo sem conexão, encerramos a sessão offline do app.
    }

    await LocalStorageService.clearOfflineSession();

    if (!mounted) {
      return;
    }

    state = state.copyWith(
      users: const [],
      clearCurrentUser: true,
      clearOfflineSession: true,
      isLoading: false,
      isOfflineMode: false,
    );
  }

  Future<void> _loadSession() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser != null) {
        await firebaseUser.reload();

        final refreshedUser = _firebaseAuth.currentUser ?? firebaseUser;
        final appUser = _mapFirebaseUser(refreshedUser);
        final offlineSession = await _buildOfflineSession(appUser);

        await LocalStorageService.saveOfflineSession(offlineSession);

        if (!mounted) {
          return;
        }

        state = AuthState(
          users: const [],
          currentUser: appUser,
          isLoading: false,
          isOfflineMode: false,
          offlineSession: offlineSession,
        );

        return;
      }

      final loadedOffline = await _loadOfflineSessionIntoState();

      if (!loadedOffline && mounted) {
        state = const AuthState(users: [], currentUser: null, isLoading: false);
      }
    } catch (_) {
      final loadedOffline = await _loadOfflineSessionIntoState();

      if (!loadedOffline && mounted) {
        state = const AuthState(users: [], currentUser: null, isLoading: false);
      }
    }
  }

  Future<String?> _loginWithOfflineSession(String email) async {
    final offlineSession = await LocalStorageService.loadOfflineSession();

    if (offlineSession == null ||
        !offlineSession.canUseOffline ||
        offlineSession.userId.trim().isEmpty) {
      return 'Sem conexão. Faça o primeiro login online antes de usar o app offline.';
    }

    if (offlineSession.email.trim().toLowerCase() != email) {
      return 'Sem conexão. Esta conta ainda não está liberada para acesso offline neste dispositivo.';
    }

    final updatedSession = offlineSession.copyWith(
      lastAccessAt: DateTime.now(),
    );

    await LocalStorageService.saveOfflineSession(updatedSession);

    if (!mounted) {
      return null;
    }

    state = state.copyWith(
      users: const [],
      currentUser: updatedSession.toAppUser(),
      isLoading: false,
      isOfflineMode: true,
      offlineSession: updatedSession,
    );

    return null;
  }

  Future<bool> _loadOfflineSessionIntoState() async {
    final offlineSession = await LocalStorageService.loadOfflineSession();

    if (offlineSession == null ||
        !offlineSession.canUseOffline ||
        offlineSession.userId.trim().isEmpty) {
      return false;
    }

    final updatedSession = offlineSession.copyWith(
      lastAccessAt: DateTime.now(),
    );

    await LocalStorageService.saveOfflineSession(updatedSession);

    if (!mounted) {
      return true;
    }

    state = AuthState(
      users: const [],
      currentUser: updatedSession.toAppUser(),
      isLoading: false,
      isOfflineMode: true,
      offlineSession: updatedSession,
    );

    return true;
  }

  Future<OfflineSessionModel> _buildOfflineSession(AppUserModel appUser) async {
    final existingSession = await LocalStorageService.loadOfflineSession();
    final now = DateTime.now();

    final firstOnlineLoginAt =
        existingSession != null && existingSession.userId == appUser.id
        ? existingSession.firstOnlineLoginAt
        : now;

    return OfflineSessionModel(
      userId: appUser.id,
      name: appUser.name,
      email: appUser.email,
      firstOnlineLoginAt: firstOnlineLoginAt,
      lastOnlineLoginAt: now,
      lastAccessAt: now,
      canUseOffline: true,
    );
  }

  AppUserModel _mapFirebaseUser(User user) {
    final email = user.email?.trim().toLowerCase() ?? '';

    final fallbackName = email.contains('@')
        ? email.split('@').first
        : 'Usuário';

    final displayName = user.displayName?.trim();

    final name = displayName != null && displayName.isNotEmpty
        ? displayName
        : fallbackName;

    return AppUserModel(
      id: user.uid,
      name: name,
      email: email,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
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

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'invalid-email':
        return 'Informe um e-mail válido.';
      case 'weak-password':
        return 'A senha informada é muito fraca.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha inválidos.';
      case 'operation-not-allowed':
        return 'O login por e-mail e senha ainda não está ativado no Firebase.';
      case 'too-many-requests':
        return 'Muitas tentativas realizadas. Aguarde um momento e tente novamente.';
      case 'network-request-failed':
        return 'Sem conexão. Faça o primeiro login online antes de usar o app offline.';
      default:
        return 'Não foi possível concluir a autenticação. Tente novamente.';
    }
  }

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    return emailRegex.hasMatch(value);
  }
}
