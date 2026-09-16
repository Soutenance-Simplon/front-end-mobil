class VaccinationModel {
  final String id;
  final String nomVaccin;
  final DateTime dateAdministration;
  final DateTime? dateRappel;
  final String? lotNumero;
  final String? centreVaccination;

  VaccinationModel({
    required this.id,
    required this.nomVaccin,
    required this.dateAdministration,
    this.dateRappel,
    this.lotNumero,
    this.centreVaccination,
  });

  factory VaccinationModel.fromJson(Map<String, dynamic> json) {
    return VaccinationModel(
      id: json['id']?.toString() ?? '',
      nomVaccin: json['nom_vaccin'] ?? json['nomVaccin'] ?? json['vaccine_name'] ?? '',
      dateAdministration: DateTime.tryParse(json['date_administration'] ?? json['dateAdministration'] ?? '') ?? DateTime.now(),
      dateRappel: json['date_rappel'] != null ? DateTime.tryParse(json['date_rappel']) : null,
      lotNumero: json['lot_numero'] ?? json['lotNumber'],
      centreVaccination: json['centre_vaccination'] ?? json['centre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_vaccin': nomVaccin,
      'date_administration': dateAdministration.toIso8601String(),
      'date_rappel': dateRappel?.toIso8601String(),
      'lot_numero': lotNumero,
      'centre_vaccination': centreVaccination,
    };
  }
}
