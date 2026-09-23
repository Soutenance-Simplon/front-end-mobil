import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/features/auth/models/specialite_model.dart';


class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://127.0.0.1:8000/api',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },

        onError: (DioException e, handler) async {
          // 🔴 Token expiré
          if (e.response?.statusCode == 401) {
            await _storage.deleteAll();
          }
          handler.next(e);
        },
      ),
    );
  }

  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // =============================
  // 🔐 AUTH
  // =============================

  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return _dio.post(
      '/users/token/',
      data: {
        'username': email,
        'password': password,
      },
    );
  }

  Future<Response> register(Map<String, dynamic> data) async {
    return _dio.post('/utilisateurs/register/', data: data);
  }



  // =============================
  // 📧 EMAIL OTP 
  // =============================

  Future<Response> sendEmailOtp(String email) async {
    return _dio.post(
      '/send-otp/',
      data: {'email': email},
    );
  }

  Future<Response> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    return _dio.post(
      '/verify-otp/',
      data: {
        'email': email,
        'code': code,
      },
    );
  }

  // =============================
  // 🔥 FIREBASE LOGIN
  // =============================

  // Future<Response> firebaseLogin(String idToken) async {
  //   return _dio.post(
  //     '/users/firebase-login/',
  //     data: {'idToken': idToken},
  //   );
  // }

  // =============================
  // 🪪 UPLOAD PIÈCE D’IDENTITÉ
  // =============================

  Future<Response> uploadIdentity(FormData formData) async {
    return _dio.post(
      '/users/verify-id/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  // =============================
  // 👤 PROFIL
  // =============================

  Future<Response> getProfile() async {
    return _dio.get('/users/profile/');
  }
   // ===============================
  // SPECIALITES
  // ===============================
  Future<List<Specialite>> getSpecialites() async {
    final response = await _dio.get('/centres/specialites/');

    final List data = response.data;

    return data.map((e) => Specialite.fromJson(e)).toList();
  }

  // ===============================
  // TOP DOCTORS
  // ===============================
  Future<List<dynamic>> getTopDoctors() async {
    final response = await _dio.get('/medecins/top/');
    return response.data;
  }

  
}
