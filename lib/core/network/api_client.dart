import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Client HTTP centralisé pour tous les microservices via l'API Gateway Spring Cloud
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  // URL de base vers l'API Gateway Spring Cloud (port 8090 avec préfixe /api)
  static const String gatewayBaseUrl = 'http://127.0.0.1:8090/api';

  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyFirstName = 'first_name';
  static const String keyLastName = 'last_name';
  static const String keyTelephone = 'telephone';
  static const String keyEmail = 'email';
  static const String keyGenre = 'genre';

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: gatewayBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Injection automatique du JWT
          final token = await _storage.read(key: keyAccessToken);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Gestion de l'expiration du token (401)
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: keyAccessToken);
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Helpers pour le stockage sécurisé
  Future<void> saveToken(String token) async {
    await _storage.write(key: keyAccessToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: keyAccessToken);
  }

  Future<void> saveUserData({
    required String userId,
    required String role,
    String? firstName,
    String? lastName,
    String? telephone,
    String? email,
    String? genre,
  }) async {
    await _storage.write(key: keyUserId, value: userId);
    await _storage.write(key: keyUserRole, value: role);
    if (firstName != null) await _storage.write(key: keyFirstName, value: firstName);
    if (lastName != null) await _storage.write(key: keyLastName, value: lastName);
    if (telephone != null) await _storage.write(key: keyTelephone, value: telephone);
    if (email != null) await _storage.write(key: keyEmail, value: email);
    if (genre != null) await _storage.write(key: keyGenre, value: genre);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: keyUserId);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: keyUserRole);
  }

  Future<String?> getFirstName() async {
    return await _storage.read(key: keyFirstName);
  }

  Future<String?> getLastName() async {
    return await _storage.read(key: keyLastName);
  }

  Future<String?> getTelephone() async {
    return await _storage.read(key: keyTelephone);
  }

  Future<String?> getEmail() async {
    return await _storage.read(key: keyEmail);
  }

  Future<String?> getGenre() async {
    return await _storage.read(key: keyGenre);
  }

  Future<void> setProfileCompleted(String userId, bool completed) async {
    await _storage.write(key: 'profile_completed_$userId', value: completed ? 'true' : 'false');
  }

  Future<bool> isProfileCompleted(String userId) async {
    if (userId.isEmpty) return false;
    final val = await _storage.read(key: 'profile_completed_$userId');
    return val == 'true';
  }

  Future<void> clearAuth() async {
    await _storage.deleteAll();
  }
}
