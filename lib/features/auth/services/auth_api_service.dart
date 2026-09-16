import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/role_model.dart';
import '../models/user_model.dart';

class AuthApiService {
  final ApiClient _client = ApiClient();

  Dio get dio => _client.dio;

  /// Connexion par Téléphone + Mot de passe (Spécification Backend auth-service RM021)
  Future<AuthResponseModel> login({
    required String identifiant,
    required String password,
  }) async {
    try {
      // Nettoyage et formatage du numéro de téléphone au format +221XXXXXXXXX
      String telClean = identifiant.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
      while (telClean.startsWith('+221+221')) {
        telClean = telClean.substring(4);
      }
      if (telClean.startsWith('221') && !telClean.startsWith('+221')) {
        telClean = '+$telClean';
      }
      if (!telClean.startsWith('+221')) {
        if (telClean.startsWith('0')) {
          telClean = telClean.substring(1);
        }
        telClean = '+221$telClean';
      }

      final payload = {
        'telephone': telClean,
        'password': password,
      };

      final response = await dio.post('/auth/login', data: payload);
      final authResponse = AuthResponseModel.fromJson(response.data);

      if (authResponse.accessToken != null) {
        await _client.saveToken(authResponse.accessToken!);
        if (authResponse.user != null) {
          await _client.saveUserData(
            userId: authResponse.user!.id,
            role: authResponse.user!.role,
            firstName: authResponse.user!.firstName,
            lastName: authResponse.user!.lastName,
            telephone: authResponse.user!.telephone,
            email: authResponse.user!.email,
            genre: authResponse.user!.genre,
          );
        }
      }
      return authResponse;
    } on DioException catch (e) {
      String msg = 'Numéro de téléphone ou mot de passe incorrect.';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        msg = e.response!.data['message'].toString();
      } else if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        msg = 'Numéro de téléphone ou mot de passe incorrect.';
      } else if (e.response?.statusCode == 500) {
        msg = 'Erreur serveur lors de la connexion. Vérifiez vos identifiants.';
      } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
        msg = 'Impossible de joindre le serveur. Vérifiez votre connexion.';
      }
      return AuthResponseModel(
        success: false,
        message: msg,
      );
    } catch (e) {
      return AuthResponseModel(
        success: false,
        message: 'Erreur inattendue : $e',
      );
    }
  }

  /// Inscription d'un nouvel utilisateur
  Future<AuthResponseModel> register({
    required String firstName,
    required String lastName,
    required String telephone,
    required String email,
    required String password,
    required String roleId,
    required String genre,
    String? dateNaissance,
    XFile? photo,
  }) async {
    try {
      // Nettoyage et formatage du téléphone au format +22177XXXXXXX
      String telClean = telephone.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
      while (telClean.startsWith('+221+221')) {
        telClean = telClean.substring(4);
      }
      if (telClean.startsWith('221') && !telClean.startsWith('+221')) {
        telClean = '+$telClean';
      }
      if (!telClean.startsWith('+221')) {
        if (telClean.startsWith('0')) {
          telClean = telClean.substring(1);
        }
        telClean = '+221$telClean';
      }

      final payload = {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'telephone': telClean,
        'email': email.trim(),
        'password': password,
        'confirmPassword': password,
      };

      final response = await dio.post(
        '/auth/register/patient',
        data: payload,
      );

      final authResponse = AuthResponseModel.fromJson(response.data);
      if (authResponse.accessToken != null) {
        await _client.saveToken(authResponse.accessToken!);
        // Sauvegarder le genre choisi lors de l'inscription
        await _client.saveUserData(
          userId: authResponse.user?.id ?? '',
          role: authResponse.user?.role ?? roleId,
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          telephone: telClean,
          email: email.trim(),
          genre: genre,
        );
      }
      return authResponse;
    } on DioException catch (e) {
      return AuthResponseModel(
        success: false,
        message: e.response?.data?['message'] ?? 'Erreur d\'inscription',
      );
    } catch (e) {
      return AuthResponseModel(
        success: false,
        message: 'Erreur inattendue : $e',
      );
    }
  }

  /// Envoi de code OTP (Téléphone ou Email)
  Future<bool> sendOtp({required String telephoneOuEmail, String type = 'VERIFICATION_TELEPHONE'}) async {
    try {
      final response = await dio.post(
        '/auth/otp/send',
        queryParameters: {
          'telephone': telephoneOuEmail,
          'type': type,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Vérification de code OTP
  Future<bool> verifyOtp({
    required String telephoneOuEmail,
    required String code,
    String type = 'VERIFICATION_TELEPHONE',
  }) async {
    try {
      final params = {
        'telephone': telephoneOuEmail,
        'code': code,
        'type': type,
      };
      print('=== OTP VERIFY ===');
      print('URL: ${dio.options.baseUrl}/auth/otp/verify');
      print('Params: $params');

      final response = await dio.post(
        '/auth/otp/verify',
        queryParameters: params,
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.data}');
      return response.statusCode == 200;

    } on DioException catch (e) {
      print('=== OTP VERIFY ERROR ===');
      print('Type: ${e.type}');
      print('Status: ${e.response?.statusCode}');
      print('Body: ${e.response?.data}');
      print('Message: ${e.message}');
      return false;
    } catch (e) {
      print('=== OTP VERIFY EXCEPTION: $e');
      return false;
    }
  }

  /// Récupération des rôles disponibles
  Future<List<RoleModel>> getRoles() async {
    try {
      final response = await dio.get('/auth/roles');
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data is List ? response.data : response.data['data'] ?? [];
        return list.map((e) => RoleModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Profil de l'utilisateur connecté
  Future<UserModel?> getProfile() async {
    try {
      final token = await _client.getToken();
      if (token == null || token.isEmpty) return null;

      try {
        final response = await dio.get('/auth/me');
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data['data'] ?? response.data;
          return UserModel.fromJson(data);
        }
      } catch (_) {
        // En cas d'absence de l'endpoint /auth/me sur le backend, récupérer depuis le cache sécurisé
      }

      final userId = await _client.getUserId();
      final role = await _client.getUserRole();
      if (userId != null && role != null) {
        final firstName = await _client.getFirstName();
        final lastName = await _client.getLastName();
        final telephone = await _client.getTelephone();
        final email = await _client.getEmail();
        final genre = await _client.getGenre();

        return UserModel(
          id: userId,
          firstName: firstName ?? '',
          lastName: lastName ?? '',
          email: email ?? '',
          telephone: telephone ?? '',
          role: role,
          genre: genre ?? '',
          emailVerified: true,
          phoneVerified: true,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    await _client.clearAuth();
  }

  /// Upload et vérification de la pièce d'identité
  Future<Map<String, dynamic>?> uploadIdentity(XFile photo) async {
    try {
      final bytes = await photo.readAsBytes();
      final form = FormData.fromMap({
        'document_piece_identite': MultipartFile.fromBytes(
          bytes,
          filename: photo.name,
        ),
      });
      final response = await dio.post('/auth/verify-id', data: form);
      if (response.statusCode == 200 && response.data != null) {
        return response.data is Map<String, dynamic>
            ? response.data
            : {'status': 'approved', 'score': 100};
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

