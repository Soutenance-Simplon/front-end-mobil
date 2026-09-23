class SalleTeleconsultationModel {
  final String id;
  final String rdvId;
  final String nomSalon;
  final String jetonAcces;
  final String serveurUrl;
  final String? displayName;
  final String? role;
  final bool audioActive;
  final bool videoActive;
  final bool estEnCours;

  SalleTeleconsultationModel({
    required this.id,
    required this.rdvId,
    required this.nomSalon,
    required this.jetonAcces,
    this.serveurUrl = 'https://meet.jit.si',
    this.displayName,
    this.role,
    this.audioActive = true,
    this.videoActive = true,
    this.estEnCours = true,
  });

  factory SalleTeleconsultationModel.fromJson(Map<String, dynamic> json) {
    return SalleTeleconsultationModel(
      id: json['id']?.toString() ?? '',
      rdvId: json['rdv_id']?.toString() ?? json['rdvId']?.toString() ?? '',
      nomSalon: json['nom_salon'] ?? json['roomName'] ?? 'dy_${json['rdv_id'] ?? "room"}',
      jetonAcces: json['jeton_acces'] ?? json['token'] ?? '',
      serveurUrl: json['serveur_url'] ?? json['serverUrl'] ?? 'https://meet.jit.si',
      displayName: json['displayName'] ?? json['display_name'],
      role: json['role'],
      audioActive: json['audio_active'] ?? true,
      videoActive: json['video_active'] ?? true,
      estEnCours: json['est_en_cours'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rdv_id': rdvId,
      'nom_salon': nomSalon,
      'jeton_acces': jetonAcces,
      'serveur_url': serveurUrl,
      'displayName': displayName,
      'role': role,
    };
  }
}
