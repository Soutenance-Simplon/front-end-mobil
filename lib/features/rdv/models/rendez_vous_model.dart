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
    // Le backend Java (Jackson) sérialise en camelCase :
    // patientId, medecinId, dateHeureSouhaitee, dateHeureConfirmee, typeConsultation, statut, paiementValide, tarifApplique
    final dateStr = json['dateHeureConfirmee']?.toString() ??
        json['dateHeureSouhaitee']?.toString() ??
        json['date_heure']?.toString() ??
        json['dateHeure']?.toString() ??
        json['date']?.toString();

    final double montantParsed = (() {
      final raw = json['tarifApplique'] ?? json['montant'] ?? json['price'];
      if (raw == null) return 15000.0;
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw.toString()) ?? 15000.0;
    })();

    final bool paye = json['paiementValide'] == true || json['paiementValide'] == 'true';
    final String statutPaiement = json['statut_paiement']?.toString() ??
        json['statutPaiement']?.toString() ??
        (paye ? 'PAYE' : 'NON_PAYE');

    return RendezVousModel(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? json['patient_id']?.toString() ?? '',
      medecinId: json['medecinId']?.toString() ?? json['medecin_id']?.toString() ?? '',
      medecinNom: json['medecinNom'] ?? json['medecin_nom'] ?? json['doctor_name'],
      medecinSpecialite: json['medecinSpecialite'] ?? json['medecin_specialite'] ?? json['specialite'],
      patientNom: json['patientNom'] ?? json['patient_nom'] ?? json['patient_name'],
      dateHeure: (dateStr != null && dateStr.isNotEmpty)
          ? (DateTime.tryParse(dateStr) ?? DateTime.now())
          : DateTime.now(),
      motif: json['motif']?.toString() ?? json['reason']?.toString() ?? 'Consultation médicale',
      typeConsultation: json['typeConsultation']?.toString() ??
          json['type_consultation']?.toString() ??
          json['type']?.toString() ??
          'TELECONSULTATION',
      statut: json['statut']?.toString() ?? json['status']?.toString() ?? 'EN_ATTENTE',
      montant: montantParsed,
      statutPaiement: statutPaiement,
      lienTeleconsultation: json['lienTeleconsultation']?.toString() ??
          json['lien_teleconsultation']?.toString(),
      notes: json['notes']?.toString(),
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
