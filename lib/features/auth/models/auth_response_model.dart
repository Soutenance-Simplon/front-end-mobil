import 'user_model.dart';

class AuthResponseModel {
  final bool success;
  final String? message;
  final String? accessToken;
  final String? refreshToken;
  final UserModel? user;

  AuthResponseModel({
    required this.success,
    this.message,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null;
    final token = data?['accessToken'] ?? data?['token'] ?? data?['access_token'] ?? json['accessToken'] ?? json['token'] ?? json['access_token'];
    final refresh = data?['refreshToken'] ?? data?['refresh_token'] ?? json['refreshToken'] ?? json['refresh_token'];

    UserModel? user;
    if (data?['user'] != null && data!['user'] is Map<String, dynamic>) {
      user = UserModel.fromJson(data['user']);
    } else if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      user = UserModel.fromJson(json['user']);
    } else if (data != null && (data['userId'] != null || data['role'] != null || data['firstName'] != null)) {
      user = UserModel(
        id: (data['userId'] ?? data['id'] ?? '').toString(),
        firstName: (data['firstName'] ?? data['first_name'] ?? '').toString(),
        lastName: (data['lastName'] ?? data['last_name'] ?? '').toString(),
        email: (data['email'] ?? '').toString(),
        telephone: (data['telephone'] ?? '').toString(),
        role: (data['role'] ?? '').toString(),
        genre: (data['genre'] ?? 'M').toString(),
        dateNaissance: data['dateNaissance'] ?? data['date_naissance'],
        photoProfil: data['photoProfil'] ?? data['photo_profil'],
        accountStatus: (data['accountStatus'] ?? data['account_status'] ?? 'ACTIF').toString(),
        emailVerified: data['emailVerified'] ?? data['email_verified'] ?? false,
        phoneVerified: data['phoneVerified'] ?? data['phone_verified'] ?? true,
      );
    } else if (json['userId'] != null || json['role'] != null || json['firstName'] != null) {
      user = UserModel(
        id: (json['userId'] ?? json['id'] ?? '').toString(),
        firstName: (json['firstName'] ?? json['first_name'] ?? '').toString(),
        lastName: (json['lastName'] ?? json['last_name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        telephone: (json['telephone'] ?? '').toString(),
        role: (json['role'] ?? '').toString(),
        genre: (json['genre'] ?? 'M').toString(),
        dateNaissance: json['dateNaissance'] ?? json['date_naissance'],
        photoProfil: json['photoProfil'] ?? json['photo_profil'],
        accountStatus: (json['accountStatus'] ?? json['account_status'] ?? 'ACTIF').toString(),
        emailVerified: json['emailVerified'] ?? json['email_verified'] ?? false,
        phoneVerified: json['phoneVerified'] ?? json['phone_verified'] ?? true,
      );
    }

    return AuthResponseModel(
      success: json['success'] == true || token != null,
      message: json['message'],
      accessToken: token?.toString(),
      refreshToken: refresh?.toString(),
      user: user,
    );
  }
}
