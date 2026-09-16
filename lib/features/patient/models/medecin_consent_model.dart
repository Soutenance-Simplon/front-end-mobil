/// Modèle représentant l'autorisation d'accès d'un médecin au dossier médical d'un patient
class MedecinConsentModel {
  final String id;
  final String nom;
  final String specialite;
  final String hopital;
  final String telephone;
  final bool estAutorise;
  final DateTime dateModification;
  final String? motif;

  const MedecinConsentModel({
    required this.id,
    required this.nom,
    required this.specialite,
    required this.hopital,
    required this.telephone,
    required this.estAutorise,
    required this.dateModification,
    this.motif,
  });

  MedecinConsentModel copyWith({
    String? id,
    String? nom,
    String? specialite,
    String? hopital,
    String? telephone,
    bool? estAutorise,
    DateTime? dateModification,
    String? motif,
  }) {
    return MedecinConsentModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      specialite: specialite ?? this.specialite,
      hopital: hopital ?? this.hopital,
      telephone: telephone ?? this.telephone,
      estAutorise: estAutorise ?? this.estAutorise,
      dateModification: dateModification ?? this.dateModification,
      motif: motif ?? this.motif,
    );
  }

  factory MedecinConsentModel.fromJson(Map<String, dynamic> json) {
    return MedecinConsentModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      specialite: json['specialite'] ?? 'Médecine Générale',
      hopital: json['hopital'] ?? 'Hôpital Principal de Dakar',
      telephone: json['telephone'] ?? '+221 77 000 00 00',
      estAutorise: json['estAutorise'] ?? true,
      dateModification: json['dateModification'] != null
          ? DateTime.parse(json['dateModification'])
          : DateTime.now(),
      motif: json['motif'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'specialite': specialite,
      'hopital': hopital,
      'telephone': telephone,
      'estAutorise': estAutorise,
      'dateModification': dateModification.toIso8601String(),
      'motif': motif,
    };
  }
}
