class ConsultationModel {
  final String id;
  final String dossierId;
  final String medecinId;
  final String? medecinNom;
  final DateTime dateConsultation;
  final String motif;
  final String? diagnostic;
  final String? observation;
  final double? tensionArterielle;
  final double? temperature;
  final double? frequenceCardiaque;

  ConsultationModel({
    required this.id,
    required this.dossierId,
    required this.medecinId,
    this.medecinNom,
    required this.dateConsultation,
    required this.motif,
    this.diagnostic,
    this.observation,
    this.tensionArterielle,
    this.temperature,
    this.frequenceCardiaque,
  });

  factory ConsultationModel.fromJson(Map<String, dynamic> json) {
    return ConsultationModel(
      id: json['id']?.toString() ?? '',
      dossierId: json['dossier_id']?.toString() ?? json['dossierId']?.toString() ?? '',
      medecinId: json['medecin_id']?.toString() ?? json['medecinId']?.toString() ?? '',
      medecinNom: json['medecin_nom'] ?? json['medecinNom'] ?? 'Dr. Praticien',
      dateConsultation: DateTime.tryParse(json['date_consultation'] ?? json['dateConsultation'] ?? '') ?? DateTime.now(),
      motif: json['motif'] ?? '',
      diagnostic: json['diagnostic'],
      observation: json['observation'],
      tensionArterielle: (json['tension_arterielle'] ?? json['tensionArterielle'])?.toDouble(),
      temperature: (json['temperature'])?.toDouble(),
      frequenceCardiaque: (json['frequence_cardiaque'] ?? json['frequenceCardiaque'])?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dossier_id': dossierId,
      'medecin_id': medecinId,
      'medecin_nom': medecinNom,
      'date_consultation': dateConsultation.toIso8601String(),
      'motif': motif,
      'diagnostic': diagnostic,
      'observation': observation,
      'tension_arterielle': tensionArterielle,
      'temperature': temperature,
      'frequence_cardiaque': frequenceCardiaque,
    };
  }
}
