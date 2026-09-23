class LignePrescriptionModel {
  final String medicament;
  final String dosage;
  final String posologie;
  final String duree;
  final String? instructions;

  LignePrescriptionModel({
    required this.medicament,
    required this.dosage,
    required this.posologie,
    required this.duree,
    this.instructions,
  });

  factory LignePrescriptionModel.fromJson(Map<String, dynamic> json) {
    return LignePrescriptionModel(
      medicament: json['medicament'] ?? json['medication'] ?? '',
      dosage: json['dosage'] ?? '',
      posologie: json['posologie'] ?? json['frequency'] ?? '',
      duree: json['duree'] ?? json['duration'] ?? '',
      instructions: json['instructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicament': medicament,
      'dosage': dosage,
      'posologie': posologie,
      'duree': duree,
      'instructions': instructions,
    };
  }
}

class PrescriptionModel {
  final String id;
  final String dossierId;
  final String medecinId;
  final String? medecinNom;
  final DateTime datePrescription;
  final List<LignePrescriptionModel> lignes;
  final String? qrCodeValidation;
  final bool delivree;

  PrescriptionModel({
    required this.id,
    required this.dossierId,
    required this.medecinId,
    this.medecinNom,
    required this.datePrescription,
    this.lignes = const [],
    this.qrCodeValidation,
    this.delivree = false,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id']?.toString() ?? '',
      dossierId: json['dossier_id']?.toString() ?? json['dossierId']?.toString() ?? '',
      medecinId: json['medecin_id']?.toString() ?? json['medecinId']?.toString() ?? '',
      medecinNom: json['medecin_nom'] ?? json['medecinNom'],
      datePrescription: DateTime.tryParse(json['date_prescription'] ?? json['datePrescription'] ?? '') ?? DateTime.now(),
      lignes: (json['lignes'] as List? ?? []).map((e) => LignePrescriptionModel.fromJson(e)).toList(),
      qrCodeValidation: json['qr_code_validation'] ?? json['qrCodeValidation'],
      delivree: json['delivree'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dossier_id': dossierId,
      'medecin_id': medecinId,
      'medecin_nom': medecinNom,
      'date_prescription': datePrescription.toIso8601String(),
      'lignes': lignes.map((e) => e.toJson()).toList(),
      'qr_code_validation': qrCodeValidation,
      'delivree': delivree,
    };
  }
}
