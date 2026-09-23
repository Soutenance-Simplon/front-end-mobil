import 'onms_reference_model.dart';

class MedecinModel {
  final String id;
  final String userId;
  final String nom;
  final String prenom;
  final String specialite;
  final String? telephone;
  final String? email;
  final String? photoUrl;
  final String? biographie;
  final String? adresse;
  final String? ville;
  final String? region;
  final double tarifConsultation;
  final double note;
  final int nombreAvis;
  final int anneesExperience;
  final bool isVerified;
  final bool teleconsultationActive;
  final int dureeConsultationMinutes;
  final OnmsReferenceModel? onmsReference;

  MedecinModel({
    required this.id,
    required this.userId,
    required this.nom,
    required this.prenom,
    required this.specialite,
    this.telephone,
    this.email,
    this.photoUrl,
    this.biographie,
    this.adresse,
    this.ville,
    this.region,
    this.tarifConsultation = 15000,
    this.note = 4.8,
    this.nombreAvis = 24,
    this.anneesExperience = 8,
    this.isVerified = true,
    this.teleconsultationActive = true,
    this.dureeConsultationMinutes = 30,
    this.onmsReference,
  });

  factory MedecinModel.fromJson(Map<String, dynamic> json) {
    final onms = json['onms_reference'] != null || json['onmsReference'] != null
        ? OnmsReferenceModel.fromJson(json['onms_reference'] ?? json['onmsReference'])
        : null;

    String nomComplet = json['nomComplet'] ?? json['nom_complet'] ?? '';
    String nom = json['nom'] ?? json['last_name'] ?? json['lastName'] ?? onms?.nom ?? '';
    String prenom = json['prenom'] ?? json['first_name'] ?? json['firstName'] ?? onms?.prenom ?? '';

    if (nom.isEmpty && prenom.isEmpty && nomComplet.isNotEmpty) {
      String clean = nomComplet.replaceAll('Dr.', '').replaceAll('Dr', '').trim();
      final parts = clean.split(' ');
      if (parts.length >= 2) {
        prenom = parts.first;
        nom = parts.sublist(1).join(' ');
      } else {
        nom = clean;
      }
    }

    return MedecinModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      nom: nom.isNotEmpty ? nom : 'Médecin',
      prenom: prenom,
      specialite: json['specialite'] ?? onms?.specialite ?? 'Médecine Générale',
      telephone: json['telephone'] ?? onms?.telephone ?? '+221770000000',
      email: json['email'],
      photoUrl: json['photoProfessionnelle'] ?? json['photo_professionnelle'] ?? json['photo_url'] ?? json['photoUrl'],
      biographie: json['biographie'] ?? json['bio'] ?? 'Médecin praticien agréé par l\'Ordre National des Médecins du Sénégal (ONMS).',
      adresse: json['etablissement'] ?? json['adresse'] ?? onms?.etablissement ?? 'Centre Hospitalier',
      ville: json['ville'] ?? (json['region'] ?? onms?.region ?? 'Dakar'),
      region: json['region'] ?? onms?.region ?? 'Dakar',
      tarifConsultation: (json['tarifConsultation'] ?? json['tarif_consultation'] ?? 15000).toDouble(),
      note: (json['note'] ?? 4.9).toDouble(),
      nombreAvis: json['nombre_avis'] ?? json['nombreAvis'] ?? 28,
      anneesExperience: json['annees_experience'] ?? json['anneesExperience'] ?? json['experience'] ?? 8,
      isVerified: json['isVerified'] ?? json['is_verified'] ?? true,
      teleconsultationActive: json['teleconsultationActive'] ?? json['teleconsultation_active'] ?? true,
      dureeConsultationMinutes: json['dureeConsultationMinutes'] ?? json['duree_consultation_minutes'] ?? 30,
      onmsReference: onms,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'userId': userId,
      'nom': nom,
      'prenom': prenom,
      'name': nomComplet,
      'nomComplet': nomComplet,
      'specialite': specialite,
      'specialty': specialite,
      'telephone': telephone,
      'phone': telephone,
      'email': email,
      'photo_url': photoUrl,
      'photoUrl': photoUrl,
      'image': photoUrl,
      'biographie': biographie,
      'adresse': adresse,
      'ville': ville,
      'region': region,
      'tarif_consultation': tarifConsultation,
      'tarifConsultation': tarifConsultation,
      'note': note,
      'nombre_avis': nombreAvis,
      'nombreAvis': nombreAvis,
      'annees_experience': anneesExperience,
      'anneesExperience': anneesExperience,
      'experience': anneesExperience,
      'is_verified': isVerified,
      'isVerified': isVerified,
      'teleconsultation_active': teleconsultationActive,
      'teleconsultationActive': teleconsultationActive,
      'duree_consultation_minutes': dureeConsultationMinutes,
      'dureeConsultationMinutes': dureeConsultationMinutes,
    };
  }

  String get nomComplet => "Dr. $prenom $nom";
}
