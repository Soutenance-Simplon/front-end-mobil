/// Modèle de la salle de téléconsultation LiveKit.
/// Le backend (TeleconsultationJoinResponse) envoie :
///   roomName, serverUrl, displayName, token, role
class SalleTeleconsultationModel {
  final String id;
  final String rdvId;
  final String nomSalon;   // = roomName du backend
  final String jetonAcces; // = token du backend (JWT LiveKit signé)
  final String serveurUrl; // = serverUrl du backend (wss://...livekit.cloud)
  final String? displayName;
  final String? role; // "MEDECIN" ou "PATIENT"
  final bool audioActive;
  final bool videoActive;
  final bool estEnCours;

  SalleTeleconsultationModel({
    required this.id,
    required this.rdvId,
    required this.nomSalon,
    required this.jetonAcces,
    this.serveurUrl = 'wss://diamyaram-3e670ked.livekit.cloud',
    this.displayName,
    this.role,
    this.audioActive = true,
    this.videoActive = true,
    this.estEnCours = true,
  });

  factory SalleTeleconsultationModel.fromJson(Map<String, dynamic> json) {
    // Le backend renvoie : roomName, serverUrl, token, displayName, role
    // (via TeleconsultationJoinResponse sérialisé par Jackson)
    final nomSalon = json['roomName']?.toString() ??
        json['nom_salon']?.toString() ??
        json['room_name']?.toString() ??
        '';

    final token = json['token']?.toString() ??
        json['jeton_acces']?.toString() ??
        json['jetonAcces']?.toString() ??
        '';

    final serveurUrl = json['serverUrl']?.toString() ??
        json['serveur_url']?.toString() ??
        json['server_url']?.toString() ??
        'wss://diamyaram-3e670ked.livekit.cloud';

    return SalleTeleconsultationModel(
      id: json['id']?.toString() ?? '',
      rdvId: json['rdvId']?.toString() ??
          json['rdv_id']?.toString() ??
          '',
      nomSalon: nomSalon,
      jetonAcces: token,
      serveurUrl: serveurUrl,
      displayName: json['displayName']?.toString() ??
          json['display_name']?.toString(),
      role: json['role']?.toString(),
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
