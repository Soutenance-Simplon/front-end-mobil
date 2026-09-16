class PermissionAccesModel {
  final String id;
  final String patientId;
  final String medecinId;
  final String? medecinNom;
  final String typeAcces; // TEMPORAIRE_URGENCE, CONSULTATION, PERMANENT
  final DateTime dateAccorde;
  final DateTime? dateExpiration;
  final bool actif;

  PermissionAccesModel({
    required this.id,
    required this.patientId,
    required this.medecinId,
    this.medecinNom,
    this.typeAcces = 'CONSULTATION',
    required this.dateAccorde,
    this.dateExpiration,
    this.actif = true,
  });

  factory PermissionAccesModel.fromJson(Map<String, dynamic> json) {
    return PermissionAccesModel(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? json['patientId']?.toString() ?? '',
      medecinId: json['medecin_id']?.toString() ?? json['medecinId']?.toString() ?? '',
      medecinNom: json['medecin_nom'] ?? json['medecinNom'],
      typeAcces: json['type_acces'] ?? json['typeAcces'] ?? 'CONSULTATION',
      dateAccorde: DateTime.tryParse(json['date_accorde'] ?? json['dateAccorde'] ?? '') ?? DateTime.now(),
      dateExpiration: json['date_expiration'] != null ? DateTime.tryParse(json['date_expiration']) : null,
      actif: json['actif'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'medecin_id': medecinId,
      'medecin_nom': medecinNom,
      'type_acces': typeAcces,
      'date_accorde': dateAccorde.toIso8601String(),
      'date_expiration': dateExpiration?.toIso8601String(),
      'actif': actif,
    };
  }
}
