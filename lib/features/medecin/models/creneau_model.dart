class CreneauModel {
  final String id;
  final String medecinId;
  final DateTime dateHeureDebut;
  final DateTime dateHeureFin;
  final String typeConsultation;
  final String statut; // DISPONIBLE, RESERVE, BLOQUE, PASSE

  CreneauModel({
    required this.id,
    required this.medecinId,
    required this.dateHeureDebut,
    required this.dateHeureFin,
    this.typeConsultation = 'PRESENTIELLE',
    this.statut = 'DISPONIBLE',
  });

  factory CreneauModel.fromJson(Map<String, dynamic> json) {
    String medId = '';
    if (json['medecin'] is Map && json['medecin']['id'] != null) {
      medId = json['medecin']['id'].toString();
    } else if (json['medecin_id'] != null) {
      medId = json['medecin_id'].toString();
    } else if (json['medecinId'] != null) {
      medId = json['medecinId'].toString();
    }

    return CreneauModel(
      id: json['id']?.toString() ?? '',
      medecinId: medId,
      dateHeureDebut: DateTime.tryParse(json['date_heure_debut'] ?? json['dateHeureDebut'] ?? '') ?? DateTime.now(),
      dateHeureFin: DateTime.tryParse(json['date_heure_fin'] ?? json['dateHeureFin'] ?? '') ?? DateTime.now(),
      typeConsultation: json['type_consultation'] ?? json['typeConsultation'] ?? 'TELECONSULTATION',
      statut: json['statut'] ?? 'DISPONIBLE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medecin_id': medecinId,
      'date_heure_debut': dateHeureDebut.toIso8601String(),
      'date_heure_fin': dateHeureFin.toIso8601String(),
      'type_consultation': typeConsultation,
      'statut': statut,
    };
  }

  bool get estDisponible => statut == 'DISPONIBLE';
}

class DisponibiliteModel {
  final String id;
  final String medecinId;
  final String jourSemaine;
  final String heureDebut;
  final String heureFin;
  final int dureeCreneauMinutes;
  final String typeConsultation;
  final bool actif;

  DisponibiliteModel({
    required this.id,
    required this.medecinId,
    required this.jourSemaine,
    required this.heureDebut,
    required this.heureFin,
    this.dureeCreneauMinutes = 30,
    this.typeConsultation = 'LES_DEUX',
    this.actif = true,
  });

  factory DisponibiliteModel.fromJson(Map<String, dynamic> json) {
    return DisponibiliteModel(
      id: json['id']?.toString() ?? '',
      medecinId: json['medecin_id']?.toString() ?? '',
      jourSemaine: json['jour_semaine'] ?? json['jourSemaine'] ?? 'LUNDI',
      heureDebut: json['heure_debut'] ?? json['heureDebut'] ?? '08:00',
      heureFin: json['heure_fin'] ?? json['heureFin'] ?? '17:00',
      dureeCreneauMinutes: json['duree_creneau_minutes'] ?? json['dureeCreneauMinutes'] ?? 30,
      typeConsultation: json['type_consultation'] ?? json['typeConsultation'] ?? 'LES_DEUX',
      actif: json['actif'] ?? true,
    );
  }
}
