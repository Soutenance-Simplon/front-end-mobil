class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String telephone;
  final String role;
  final String genre;
  final String? dateNaissance;
  final String? photoProfil;
  final String? accountStatus;
  final bool emailVerified;
  final bool phoneVerified;

  bool get isMedecin => role == 'MEDECIN';

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.telephone,
    required this.role,
    required this.genre,
    this.dateNaissance,
    this.photoProfil,
    this.accountStatus,
    required this.emailVerified,
    required this.phoneVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
      role: json['role'] is Map ? (json['role']['nom_role'] ?? json['role']['nomRole'] ?? '') : (json['role']?.toString() ?? ''),
      genre: json['genre']?.toString() ?? 'M',
      dateNaissance: json['date_naissance'] ?? json['dateNaissance'],
      photoProfil: json['photo_profil'] ?? json['photoProfil'],
      accountStatus: json['account_status'] ?? json['accountStatus'] ?? 'ACTIF',
      emailVerified: json['email_verified'] ?? json['emailVerified'] ?? false,
      phoneVerified: json['phone_verified'] ?? json['phoneVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'telephone': telephone,
      'role': role,
      'genre': genre,
      'date_naissance': dateNaissance,
      'photo_profil': photoProfil,
      'account_status': accountStatus,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
    };
  }

  String get prenom => firstName;
  String get nom => lastName;
  String get roleNom => role;
  String get fullName => "$firstName $lastName";
}
