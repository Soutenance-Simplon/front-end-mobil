class PatientModel {
  final String id;
  final String userId;
  final String nom;
  final String prenom;
  final String? telephone;
  final String? email;
  final String? dateNaissance;
  final String? adresse;
  final String? personneContact;
  final String? telephoneContact;
  final String? lienParenteContact;
  final String? qrUrgenceToken;

  PatientModel({
    required this.id,
    required this.userId,
    required this.nom,
    required this.prenom,
    this.telephone,
    this.email,
    this.dateNaissance,
    this.adresse,
    this.personneContact,
    this.telephoneContact,
    this.lienParenteContact,
    this.qrUrgenceToken,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      nom: json['nom'] ?? json['last_name'] ?? json['lastName'] ?? '',
      prenom: json['prenom'] ?? json['first_name'] ?? json['firstName'] ?? '',
      telephone: json['telephone'],
      email: json['email'],
      dateNaissance: json['date_naissance'] ?? json['dateNaissance'],
      adresse: json['adresse'],
      personneContact: json['personne_contact'] ?? json['personneContact'],
      telephoneContact: json['telephone_contact'] ?? json['telephoneContact'],
      lienParenteContact: json['lien_parente_contact'] ?? json['lienParenteContact'],
      qrUrgenceToken: json['qr_urgence_token'] ?? json['qrUrgenceToken'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'date_naissance': dateNaissance,
      'adresse': adresse,
      'personne_contact': personneContact,
      'telephone_contact': telephoneContact,
      'lien_parente_contact': lienParenteContact,
      'qr_urgence_token': qrUrgenceToken,
    };
  }

  String get nomComplet => "$prenom $nom";
}
