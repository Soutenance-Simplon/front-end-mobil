class MaladieChroniqueModel {
  final String id;
  final String nomMaladie;
  final String? dateDiagnostic;
  final String statut; // SOUS_TRAITEMENT, STABLE, GUERI

  MaladieChroniqueModel({
    required this.id,
    required this.nomMaladie,
    this.dateDiagnostic,
    this.statut = 'SOUS_TRAITEMENT',
  });

  factory MaladieChroniqueModel.fromJson(Map<String, dynamic> json) {
    return MaladieChroniqueModel(
      id: json['id']?.toString() ?? '',
      nomMaladie: json['nom_maladie'] ?? json['nomMaladie'] ?? json['name'] ?? '',
      dateDiagnostic: json['date_diagnostic'] ?? json['dateDiagnostic'],
      statut: json['statut'] ?? 'SOUS_TRAITEMENT',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_maladie': nomMaladie,
      'date_diagnostic': dateDiagnostic,
      'statut': statut,
    };
  }
}
