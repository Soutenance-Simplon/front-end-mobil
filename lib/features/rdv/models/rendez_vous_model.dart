class RendezVousModel {
  final String id;
  final String patientId;
  final String medecinId;
  final String? medecinNom;
  final String? medecinSpecialite;
  final String? patientNom;
  final DateTime dateHeure;
  final String motif;
  final String typeConsultation; // PRESENTIELLE, TELECONSULTATION
  final String statut; // EN_ATTENTE, CONFIRME, TERMINE, ANNULE
  final double montant;
  final String statutPaiement; // NON_PAYE, PAYE, REMBOURSE
  final String? lienTeleconsultation;
  final String? notes;

  RendezVousModel({
    required this.id,
    required this.patientId,
    required this.medecinId,
    this.medecinNom,
    this.medecinSpecialite,
    this.patientNom,
    required this.dateHeure,
    required this.motif,
    this.typeConsultation = 'PRESENTIELLE',
    this.statut = 'CONFIRME',
    this.montant = 15000,
    this.statutPaiement = 'PAYE',
    this.lienTeleconsultation,
    this.notes,
  });

  factory RendezVousModel.fromJson(Map<String, dynamic> json) {
    return RendezVousModel(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? json['patientId']?.toString() ?? '',
      medecinId: json['medecin_id']?.toString() ?? json['medecinId']?.toString() ?? '',
      medecinNom: json['medecin_nom'] ?? json['medecinNom'] ?? json['doctor_name'] ?? 'Dr. Médecin',
      medecinSpecialite: json['medecin_specialite'] ?? json['medecinSpecialite'] ?? json['specialite'] ?? 'Généraliste',
      patientNom: json['patient_nom'] ?? json['patientNom'] ?? json['patient_name'],
      dateHeure: DateTime.tryParse(json['date_heure'] ?? json['dateHeure'] ?? json['date'] ?? '') ?? DateTime.now(),
      motif: json['motif'] ?? json['reason'] ?? 'Consultation médicale',
      typeConsultation: json['type_consultation'] ?? json['typeConsultation'] ?? json['type'] ?? 'PRESENTIELLE',
      statut: json['statut'] ?? json['status'] ?? 'CONFIRME',
      montant: (json['montant'] ?? json['price'] ?? 15000).toDouble(),
      statutPaiement: json['statut_paiement'] ?? json['statutPaiement'] ?? 'PAYE',
      lienTeleconsultation: json['lien_teleconsultation'] ?? json['lienTeleconsultation'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'medecin_id': medecinId,
      'medecin_nom': medecinNom,
      'medecin_specialite': medecinSpecialite,
      'patient_nom': patientNom,
      'date_heure': dateHeure.toIso8601String(),
      'motif': motif,
      'type_consultation': typeConsultation,
      'statut': statut,
      'montant': montant,
      'statut_paiement': statutPaiement,
      'lien_teleconsultation': lienTeleconsultation,
      'notes': notes,
    };
  }

  bool get estTeleconsultation => typeConsultation == 'TELECONSULTATION';
  bool get estAVenir => dateHeure.isAfter(DateTime.now()) && statut != 'ANNULE';
}
