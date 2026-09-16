class OnmsReferenceModel {
  final int? id;
  final String numeroOrdre;
  final String nom;
  final String prenom;
  final String specialite;
  final String? dateInscription;
  final String statutProfessionnel;
  final String? etablissement;
  final String? region;
  final String? section;
  final String? telephone;

  OnmsReferenceModel({
    this.id,
    required this.numeroOrdre,
    required this.nom,
    required this.prenom,
    required this.specialite,
    this.dateInscription,
    this.statutProfessionnel = 'ACTIF',
    this.etablissement,
    this.region,
    this.section,
    this.telephone,
  });

  factory OnmsReferenceModel.fromJson(Map<String, dynamic> json) {
    return OnmsReferenceModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      numeroOrdre: json['numero_ordre'] ?? json['numeroOrdre'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      specialite: json['specialite'] ?? '',
      dateInscription: json['date_inscription'] ?? json['dateInscription'],
      statutProfessionnel: json['statut_professionnel'] ?? json['statutProfessionnel'] ?? 'ACTIF',
      etablissement: json['etablissement'],
      region: json['region'],
      section: json['section'],
      telephone: json['telephone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero_ordre': numeroOrdre,
      'nom': nom,
      'prenom': prenom,
      'specialite': specialite,
      'date_inscription': dateInscription,
      'statut_professionnel': statutProfessionnel,
      'etablissement': etablissement,
      'region': region,
      'section': section,
      'telephone': telephone,
    };
  }

  String get nomComplet => "Dr. $prenom $nom";
  bool get estAutorise => statutProfessionnel == 'ACTIF';
}
