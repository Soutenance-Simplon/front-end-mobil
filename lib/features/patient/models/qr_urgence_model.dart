class QrUrgenceModel {
  final String patientId;
  final String nomComplet;
  final String? nom;
  final String? prenom;
  final String? photoUrl;
  final String? telephonePatient;
  final String? adresse;
  final String? ville;
  final String? dateNaissance;
  final String groupeSanguin;
  final List<String> allergiesMajeures;
  final List<String> maladiesChroniques;
  final List<String> antecedents;
  final List<String> traitementsEnCours;
  final String contactUrgenceNom;
  final String contactUrgenceTel;
  final String contactUrgenceLien;
  final String viewMode; // "CITOYEN_PUBLIC" ou "MEDECIN_AUTHENTIFIE"
  final bool isVueSecouriste; // true: Citoyen/Secouriste, false: Médecin

  QrUrgenceModel({
    required this.patientId,
    required this.nomComplet,
    this.nom,
    this.prenom,
    this.photoUrl,
    this.telephonePatient,
    this.adresse,
    this.ville,
    this.dateNaissance,
    required this.groupeSanguin,
    this.allergiesMajeures = const [],
    this.maladiesChroniques = const [],
    this.antecedents = const [],
    this.traitementsEnCours = const [],
    required this.contactUrgenceNom,
    required this.contactUrgenceTel,
    this.contactUrgenceLien = 'Proche',
    this.viewMode = 'CITOYEN_PUBLIC',
    this.isVueSecouriste = true,
  });

  factory QrUrgenceModel.fromJson(Map<String, dynamic> json) {
    final vMode = json['viewMode'] ?? json['view_mode'] ?? (json['is_vue_secouriste'] == false ? 'MEDECIN_AUTHENTIFIE' : 'CITOYEN_PUBLIC');
    final pNom = json['nom']?.toString().trim() ?? '';
    final pPrenom = json['prenom']?.toString().trim() ?? '';
    final full = json['nom_complet']?.toString() ?? json['nomComplet']?.toString() ?? (pPrenom.isNotEmpty || pNom.isNotEmpty ? '$pPrenom $pNom'.trim() : 'Patient');

    return QrUrgenceModel(
      patientId: json['patient_id']?.toString() ?? json['patientId']?.toString() ?? 'QR-PASS',
      nomComplet: full,
      nom: pNom.isNotEmpty ? pNom : null,
      prenom: pPrenom.isNotEmpty ? pPrenom : null,
      photoUrl: json['photoUrl'] ?? json['photo_url'],
      telephonePatient: json['telephone_patient'] ?? json['telephonePatient'] ?? json['telephone'],
      adresse: json['adresse'],
      ville: json['ville'],
      dateNaissance: json['date_naissance'] ?? json['dateNaissance'],
      groupeSanguin: json['groupe_sanguin'] ?? json['groupeSanguin'] ?? 'Non renseigné',
      allergiesMajeures: List<String>.from(json['allergies_majeures'] ?? json['allergiesMajeures'] ?? json['allergies'] ?? []),
      maladiesChroniques: List<String>.from(json['maladies_chroniques'] ?? json['maladiesChroniques'] ?? json['maladies'] ?? []),
      antecedents: List<String>.from(json['antecedents'] ?? []),
      traitementsEnCours: List<String>.from(json['traitements_en_cours'] ?? json['traitementsEnCours'] ?? json['traitements'] ?? []),
      contactUrgenceNom: json['contact_urgence_nom'] ?? json['contactUrgenceNom'] ?? 'Non renseigné',
      contactUrgenceTel: json['contact_urgence_tel'] ?? json['contactUrgenceTelephone'] ?? json['telephone_contact'] ?? 'Non renseigné',
      contactUrgenceLien: json['contact_urgence_lien'] ?? json['contactUrgenceLien'] ?? json['lien_parente_contact'] ?? 'Proche',
      viewMode: vMode,
      isVueSecouriste: vMode == 'CITOYEN_PUBLIC' || (json['is_vue_secouriste'] ?? true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'nom_complet': nomComplet,
      'nom': nom,
      'prenom': prenom,
      'photo_url': photoUrl,
      'groupe_sanguin': groupeSanguin,
      'allergies_majeures': allergiesMajeures,
      'maladies_chroniques': maladiesChroniques,
      'antecedents': antecedents,
      'traitements_en_cours': traitementsEnCours,
      'contact_urgence_nom': contactUrgenceNom,
      'contact_urgence_tel': contactUrgenceTel,
      'contact_urgence_lien': contactUrgenceLien,
      'view_mode': viewMode,
      'is_vue_secouriste': isVueSecouriste,
    };
  }
}
