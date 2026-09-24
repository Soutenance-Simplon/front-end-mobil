class InteractionMedicamenteuseModel {
  final String medicament1;
  final String medicament2;
  final String niveauDanger; // CONTRE_INDICATION_ABSOLUE, MAJEURE, MODEREE, MINEURE
  final String explication;
  final String recommandation;
  final bool bloquant;
  final String sourceMedicale;
  final int? pageNumero;
  final String? documentUrl;
  final String? documentNom;
  final String? alternativeRecommandee;

  InteractionMedicamenteuseModel({
    required this.medicament1,
    required this.medicament2,
    required this.niveauDanger,
    required this.explication,
    required this.recommandation,
    this.bloquant = false,
    this.sourceMedicale = "Guide Médicaments Essentiels MSF/OMS",
    this.pageNumero,
    this.documentUrl,
    this.documentNom,
    this.alternativeRecommandee,
  });

  factory InteractionMedicamenteuseModel.fromJson(Map<String, dynamic> json) {
    return InteractionMedicamenteuseModel(
      medicament1: json['medicament1']?.toString() ?? '',
      medicament2: json['medicament2']?.toString() ?? '',
      niveauDanger: json['niveau_danger']?.toString() ?? json['severity']?.toString() ?? 'MODEREE',
      explication: json['explication']?.toString() ?? json['explanation']?.toString() ?? '',
      recommandation: json['recommandation']?.toString() ?? json['recommendation']?.toString() ?? '',
      bloquant: json['bloquant'] == true || (json['niveau_danger'] == 'CONTRE_INDICATION_ABSOLUE'),
      sourceMedicale: json['source_medicale']?.toString() ?? "Guide Médicaments Essentiels MSF/OMS",
      pageNumero: json['page_numero'] is int ? json['page_numero'] : int.tryParse(json['page_numero']?.toString() ?? ''),
      documentUrl: json['document_url']?.toString(),
      documentNom: json['document_nom']?.toString(),
      alternativeRecommandee: json['alternative_recommandee']?.toString() ?? json['alternative']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicament1': medicament1,
      'medicament2': medicament2,
      'niveau_danger': niveauDanger,
      'explication': explication,
      'recommandation': recommandation,
      'bloquant': bloquant,
      'source_medicale': sourceMedicale,
      'page_numero': pageNumero,
      'document_url': documentUrl,
      'document_nom': documentNom,
      'alternative_recommandee': alternativeRecommandee,
    };
  }

  bool get estCritique =>
      bloquant ||
      niveauDanger == 'CONTRE_INDICATION_ABSOLUE' ||
      niveauDanger == 'MAJEURE' ||
      niveauDanger == 'CRITIQUE';
}
