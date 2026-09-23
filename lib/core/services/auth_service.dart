import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
// import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio _dio;

  AuthService() {
    _dio = Dio(BaseOptions(baseUrl: baseUrl));

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

  /// Getter pour accéder au Dio
  Dio get dio => _dio;

  /// Retourne le token stocké
  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  

  // =========================
  // EMAIL OTP
  // =========================
  Future<bool> sendOtp({required String email}) async {
    try {
      final response = await _dio.post(
        '/utilisateurs/send-otp/',
        data: {'email': email},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyOtp({required String email, required String code}) async {
    try {
      final response = await _dio.post(
        '/utilisateurs/verify-otp/',
        data: {'email': email, 'code': code},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // =========================
  Future<Map<String, dynamic>?> uploadIdentity(XFile imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;

      FormData formData = FormData.fromMap({
        "document_piece_identite": await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        "$baseUrl/upload-identity/",
        data: formData,
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
            // Si tu utilises token :
            // "Authorization": "Bearer $token",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        return null;
      }
    } catch (e) {
        print("Upload identity error: $e");
        return null;
    }
  }

  // -------------
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get("$baseUrl/profile");

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception("Erreur lors du chargement du profil");
      }
    } catch (e) {
      throw Exception("Erreur getProfile : $e");
    }
  }

  // =========================
  // REGISTER
  // =========================

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String telephone,
    required String password,
    required String password2,
    required String roleId,
    required String genre,
    XFile? photo,
    DateTime? dateNaissance,
  }) async {
    FormData formData = FormData.fromMap({
      'username': email.split('@')[0],
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'telephone': telephone,
      'password': password,
      'password2': password2,
      'role': int.parse(roleId),
      'genre': genre,
      if (dateNaissance != null)
        'date_naissance': dateNaissance.toIso8601String().split('T')[0],
    });

    if (photo != null) {
      if (kIsWeb) {
        final bytes = await photo.readAsBytes();
        formData.files.add(
          MapEntry(
            "photo_profil",
            MultipartFile.fromBytes(bytes, filename: photo.name),
          ),
        );
      } else {
        formData.files.add(
          MapEntry(
            "photo_profil",
            await MultipartFile.fromFile(photo.path, filename: photo.name),
          ),
        );
      }
    }

    final response = await _dio.post(
      '/utilisateurs/finalize-registration/',
      data: formData,
    );

    return response.statusCode == 201;
  }

  // =========================
  // LOGIN
  // =========================
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/utilisateurs/token/',
      data: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      await _storage.write(key: 'access_token', value: response.data['access']);
      await _storage.write(
        key: 'refresh_token',
        value: response.data['refresh'],
      );
      return true;
    }
    return false;
  }

  // =========================
  // GET ROLES
  // =========================
  Future<List<Map<String, dynamic>>> getRoles() async {
    try {
      final response = await _dio.get('/utilisateurs/roles/');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      return [];
    }
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
