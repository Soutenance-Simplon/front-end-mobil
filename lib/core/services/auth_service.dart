import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

class AuthService {
  // Gateway URL principale pour le backend DIAM-YARAAM (port 8090)
  static const String baseUrl = 'http://127.0.0.1:8090/api';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio _dio;

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  // ==========================================
  // 🔐 AUTHENTIFICATION (DIAM-YARAAM BACKEND)
  // ==========================================

  /// Connexion par numéro de téléphone Sénégalais (+221...)
  Future<bool> loginWithPhone({
    required String telephone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'telephone': telephone,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        await _storage.write(key: 'access_token', value: data['accessToken']);
        await _storage.write(key: 'refresh_token', value: data['refreshToken']);
        await _storage.write(key: 'user_id', value: data['userId']);
        await _storage.write(key: 'user_role', value: data['role']);
        await _storage.write(key: 'user_phone', value: data['telephone']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Inscription d'un patient
  Future<bool> registerPatient({
    required String firstName,
    required String lastName,
    required String telephone,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register/patient',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'telephone': telephone,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
        },
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Envoi d'un code OTP SMS
  Future<bool> sendOtp({
    String? telephone,
    String? email,
    String type = "VERIFICATION_TELEPHONE",
  }) async {
    final targetPhone = telephone ?? email ?? '';
    try {
      final response = await _dio.post(
        '/auth/otp/send',
        queryParameters: {
          'telephone': targetPhone,
          'type': type,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Vérification d'un code OTP SMS
  Future<bool> verifyOtp({
    required String telephone,
    required String code,
    String type = "VERIFICATION_TELEPHONE",
  }) async {
    try {
      final response = await _dio.post(
        '/auth/otp/verify',
        queryParameters: {
          'telephone': telephone,
          'code': code,
          'type': type,
        },
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Mot de passe oublié
  Future<bool> forgotPassword({required String telephone}) async {
    try {
      final response = await _dio.post(
        '/auth/password/forgot',
        data: {'telephone': telephone},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Réinitialisation de mot de passe avec OTP
  Future<bool> resetPassword({
    required String telephone,
    required String code,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/password/reset',
        data: {
          'telephone': telephone,
          'code': code,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Rafraîchissement du token JWT
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        await _storage.write(key: 'access_token', value: data['accessToken']);
        await _storage.write(key: 'refresh_token', value: data['refreshToken']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // COMPATIBILITÉ ÉCRANS (AUTH LEGACY)
  // ==========================================

  Future<List<Map<String, dynamic>>> getRoles() async {
    return [
      {'id': 1, 'nom_role': 'PATIENT'},
      {'id': 2, 'nom_role': 'MEDECIN'},
    ];
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String telephone,
    required String password,
    required String password2,
    required String roleId,
    required String genre,
    dynamic photo,
    DateTime? dateNaissance,
  }) async {
    return registerPatient(
      firstName: firstName,
      lastName: lastName,
      telephone: telephone,
      email: email,
      password: password,
      confirmPassword: password2,
    );
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return loginWithPhone(telephone: email, password: password);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final userId = await _storage.read(key: 'user_id');
    return {
      'id': userId ?? 'usr_1',
      'first_name': 'Awa',
      'last_name': 'DIOP',
      'telephone': '+221776543210',
      'role': 'PATIENT',
    };
  }

  Future<Map<String, dynamic>?> uploadIdentity(dynamic imageFile) async {
    return {'status': 'approved', 'score': 40, 'errors': []};
  }

  /// Déconnexion
  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
