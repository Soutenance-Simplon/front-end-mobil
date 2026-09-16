class InteractionMedicamenteuseModel {
  final String medicament1;
  final String medicament2;
  final String niveauDanger; // CONTRE_INDICATION_ABSOLUE, MAJEURE, MODEREE, MINEURE
  final String explication;
  final String recommandation;

  InteractionMedicamenteuseModel({
    required this.medicament1,
    required this.medicament2,
    required this.niveauDanger,
    required this.explication,
    required this.recommandation,
  });

  factory InteractionMedicamenteuseModel.fromJson(Map<String, dynamic> json) {
    return InteractionMedicamenteuseModel(
      medicament1: json['medicament1'] ?? '',
      medicament2: json['medicament2'] ?? '',
      niveauDanger: json['niveau_danger'] ?? json['severity'] ?? 'MODEREE',
      explication: json['explication'] ?? json['explanation'] ?? '',
      recommandation: json['recommandation'] ?? json['recommendation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicament1': medicament1,
      'medicament2': medicament2,
      'niveau_danger': niveauDanger,
      'explication': explication,
      'recommandation': recommandation,
    };
  }

  bool get estCritique => niveauDanger == 'CONTRE_INDICATION_ABSOLUE' || niveauDanger == 'MAJEURE';
}
