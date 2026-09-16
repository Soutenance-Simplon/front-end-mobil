class HospitalisationModel {
  final String id;
  final String etablissement;
  final String motif;
  final DateTime dateEntree;
  final DateTime? dateSortie;
  final String? service;
  final String? medecinResponsable;

  HospitalisationModel({
    required this.id,
    required this.etablissement,
    required this.motif,
    required this.dateEntree,
    this.dateSortie,
    this.service,
    this.medecinResponsable,
  });

  factory HospitalisationModel.fromJson(Map<String, dynamic> json) {
    return HospitalisationModel(
      id: json['id']?.toString() ?? '',
      etablissement: json['etablissement'] ?? json['hospital'] ?? '',
      motif: json['motif'] ?? '',
      dateEntree: DateTime.tryParse(json['date_entree'] ?? json['dateEntree'] ?? '') ?? DateTime.now(),
      dateSortie: json['date_sortie'] != null ? DateTime.tryParse(json['date_sortie']) : null,
      service: json['service'],
      medecinResponsable: json['medecin_responsable'] ?? json['medecinResponsable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'etablissement': etablissement,
      'motif': motif,
      'date_entree': dateEntree.toIso8601String(),
      'date_sortie': dateSortie?.toIso8601String(),
      'service': service,
      'medecin_responsable': medecinResponsable,
    };
  }
}
