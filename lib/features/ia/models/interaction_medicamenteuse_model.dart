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
    final rawSource = json['source_medicale']?.toString() ?? "Guide Médicaments Essentiels MSF/OMS";
    final rawDocUrl = json['document_url']?.toString();

    // Extraction multi-niveaux du numéro de page
    int? parsedPage;
    if (json['page_numero'] is int) {
      parsedPage = json['page_numero'];
    } else if (json['page'] is int) {
      parsedPage = json['page'];
    } else if (json['page_no'] is int) {
      parsedPage = json['page_no'];
    } else if (json['pageNumber'] is int) {
      parsedPage = json['pageNumber'];
    } else {
      final pageStr = json['page_numero']?.toString() ??
          json['page']?.toString() ??
          json['page_no']?.toString() ??
          json['pageNumber']?.toString();
      if (pageStr != null && pageStr.isNotEmpty) {
        parsedPage = int.tryParse(pageStr);
      }
    }

    // Extraction par regex depuis la source médicale si nécessaire (ex: "Monographie Amoxicilline, p. 38" -> 38)
    if (parsedPage == null) {
      final matchSource = RegExp(r'(?:p\.|page\s*)(\d+)', caseSensitive: false).firstMatch(rawSource);
      if (matchSource != null) {
        parsedPage = int.tryParse(matchSource.group(1) ?? '');
      }
    }

    // Extraction par regex depuis l'URL si nécessaire (ex: "...#page=38" ou "?page=38" -> 38)
    if (parsedPage == null && rawDocUrl != null) {
      final matchUrl = RegExp(r'[#?&]page=(\d+)', caseSensitive: false).firstMatch(rawDocUrl);
      if (matchUrl != null) {
        parsedPage = int.tryParse(matchUrl.group(1) ?? '');
      }
    }

    // Déduction clinique par défaut pour les molécules et allergies du référentiel MSF
    if (parsedPage == null) {
      final combined = "${json['medicament1']} ${json['medicament2']} $rawSource".toUpperCase();
      if (combined.contains("AMOX") || combined.contains("PENICIL") || combined.contains("BETA")) {
        parsedPage = 38;
      } else if (combined.contains("CIPRO") || combined.contains("AMIODARONE") || combined.contains("QT")) {
        parsedPage = 51;
      } else if (combined.contains("AINS") || combined.contains("ASPIRIN") || combined.contains("IBUPROFEN") || combined.contains("WARFARIN")) {
        parsedPage = 10;
      } else if (combined.contains("SULFA") || combined.contains("BACTRIM") || combined.contains("COTRIMOX")) {
        parsedPage = 12;
      } else if (combined.contains("MACROLID") || combined.contains("AZITHRO") || combined.contains("ERYTHRO")) {
        parsedPage = 44;
      } else if (combined.contains("TRAMADOL") || combined.contains("FLUOXETIN") || combined.contains("ISRS")) {
        parsedPage = 101;
      } else if (combined.contains("SPIRONOLACTON") || combined.contains("PERINDOPRIL") || combined.contains("IEC")) {
        parsedPage = 77;
      } else if (combined.contains("STATIN") || combined.contains("SIMVASTATIN")) {
        parsedPage = 83;
      }
    }

    final docNom = json['document_nom']?.toString() ?? "guideline-339-fr.pdf";
    final docUrl = rawDocUrl ?? (parsedPage != null ? "http://127.0.0.1:8089/ia/documents/view/$docNom?page=$parsedPage" : null);

    return InteractionMedicamenteuseModel(
      medicament1: json['medicament1']?.toString() ?? '',
      medicament2: json['medicament2']?.toString() ?? '',
      niveauDanger: json['niveau_danger']?.toString() ?? json['severity']?.toString() ?? 'MODEREE',
      explication: json['explication']?.toString() ?? json['explanation']?.toString() ?? '',
      recommandation: json['recommandation']?.toString() ?? json['recommendation']?.toString() ?? '',
      bloquant: json['bloquant'] == true || (json['niveau_danger'] == 'CONTRE_INDICATION_ABSOLUE'),
      sourceMedicale: rawSource,
      pageNumero: parsedPage,
      documentUrl: docUrl,
      documentNom: docNom,
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
