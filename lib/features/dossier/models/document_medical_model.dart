class DocumentMedicalModel {
  final String id;
  final String titre;
  final String typeDocument; // ORDONNANCE, ANALYSE, RADIO, COMPTE_RENDU
  final String urlFichier;
  final DateTime dateUpload;
  final String? medecinNom;

  DocumentMedicalModel({
    required this.id,
    required this.titre,
    this.typeDocument = 'COMPTE_RENDU',
    required this.urlFichier,
    required this.dateUpload,
    this.medecinNom,
  });

  factory DocumentMedicalModel.fromJson(Map<String, dynamic> json) {
    return DocumentMedicalModel(
      id: json['id']?.toString() ?? '',
      titre: json['titre'] ?? json['title'] ?? 'Document Médical',
      typeDocument: json['type_document'] ?? json['typeDocument'] ?? 'COMPTE_RENDU',
      urlFichier: json['url_fichier'] ?? json['urlFichier'] ?? '',
      dateUpload: DateTime.tryParse(json['date_upload'] ?? json['dateUpload'] ?? '') ?? DateTime.now(),
      medecinNom: json['medecin_nom'] ?? json['medecinNom'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'type_document': typeDocument,
      'url_fichier': urlFichier,
      'date_upload': dateUpload.toIso8601String(),
      'medecin_nom': medecinNom,
    };
  }
}
