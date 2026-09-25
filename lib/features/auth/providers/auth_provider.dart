import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/role_model.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';
import '../../../core/services/websocket_service.dart';

/// État global d'authentification
class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final UserModel? user;
  final List<RoleModel> roles;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.user,
    this.roles = const [],
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    UserModel? user,
    List<RoleModel>? roles,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      roles: roles ?? this.roles,
    );
  }
}

/// Contrôleur d'état Auth
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _apiService;
  final WebSocketService _wsService = WebSocketService();

  AuthNotifier(this._apiService) : super(const AuthState()) {
    init();
  }

  Dio get dio => _apiService.dio;

  Future<void> init() async {
    await loadRoles();
    await checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    final user = await _apiService.getProfile();
    if (user != null) {
      state = state.copyWith(isAuthenticated: true, user: user);
    }
  }

  Future<void> loadRoles() async {
    try {
      final roles = await _apiService.getRoles();
      state = state.copyWith(roles: roles);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _apiService.login(identifiant: email, password: password);
    if (res.success) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: res.user,
      );
      // Connexion WebSocket pour recevoir notifications et mises à jour en temps réel
      if (res.user != null && res.user!.id.isNotEmpty) {
        _wsService.connect(userId: res.user!.id);
      }
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: res.message ?? 'Échec de connexion',
      );
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String telephone,
    required String password,
    required String roleId,
    required String genre,
    String? password2,
    XFile? photo,
    DateTime? dateNaissance,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _apiService.register(
      firstName: firstName,
      lastName: lastName,
      telephone: telephone,
      email: email,
      password: password,
      roleId: roleId,
      genre: genre,
      dateNaissance: dateNaissance?.toIso8601String().split('T')[0],
      photo: photo,
    );
    if (res.success) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: res.user,
      );
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        error: res.message ?? 'Échec d\'inscription',
      );
      return false;
    }
  }

  Future<bool> sendEmailOtp({required String email}) async {
    state = state.copyWith(isLoading: true, error: null);
    final ok = await _apiService.sendOtp(telephoneOuEmail: email);
    state = state.copyWith(isLoading: false);
    return ok;
  }

  Future<bool> verifyEmailOtp({required String email, required String code}) async {
    state = state.copyWith(isLoading: true, error: null);
    final ok = await _apiService.verifyOtp(telephoneOuEmail: email, code: code);
    state = state.copyWith(isLoading: false);
    return ok;
  }

  Future<Map<String, dynamic>?> sendIdentity({
    required String pieceNumber,
    required Uint8List idBytes,
    required String firstName,
    required String lastName,
    required String dateNaissance,
  }) async {
    try {
      final form = FormData.fromMap({
        "piece_identite_numero": pieceNumber,
        "first_name": firstName,
        "last_name": lastName,
        "date_naissance": dateNaissance,
        "document_piece_identite": MultipartFile.fromBytes(
          idBytes,
          filename: "id.jpg",
        ),
      });
      final res = await dio.post("/auth/verify-id", data: form);
      return res.data;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    // Déconnexion WebSocket propre
    _wsService.disconnect();
    state = const AuthState();
  }
}

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService();
});

final authServiceProvider = authApiServiceProvider;

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(authApiServiceProvider);
  return AuthNotifier(api);
});

