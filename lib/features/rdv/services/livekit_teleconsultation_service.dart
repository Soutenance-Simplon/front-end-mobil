import 'package:livekit_client/livekit_client.dart';
import '../models/salle_teleconsultation_model.dart';
import 'rdv_api_service.dart';

/// Service de téléconsultation utilisant le SDK LiveKit officiel.
/// Le backend (rdv-service) génère le JWT signé avec la vraie clé LiveKit.
class LiveKitTeleconsultationService {
  final RdvApiService _apiService;
  Room? _room;

  LiveKitTeleconsultationService(this._apiService);

  Room? get room => _room;
  bool get isConnected => _room?.connectionState == ConnectionState.connected;

  /// Demande l'accès au backend, récupère le token LiveKit et connecte à la salle.
  Future<Room> rejoindre({
    required String rdvId,
    String? userId,
    String? displayName,
  }) async {
    // 1. Autorisation backend → token LiveKit signé + URL de salle
    final SalleTeleconsultationModel? salle = await _apiService.rejoindreTeleconsultation(
      rdvId,
      userId: userId,
      displayName: displayName,
    );

    if (salle == null) {
      throw Exception('Impossible d\'obtenir l\'accès à la téléconsultation. Vérifiez votre connexion et réessayez.');
    }

    final String token = salle.jetonAcces;
    final String serverUrl = salle.serveurUrl.isNotEmpty
        ? salle.serveurUrl
        : 'wss://diamyaram-3e670ked.livekit.cloud';

    if (token.isEmpty) {
      throw Exception('Token d\'accès invalide reçu du serveur.');
    }

    // 2. Créer et connecter la Room LiveKit
    _room = Room();

    final connectOptions = ConnectOptions(
      autoSubscribe: true,
    );

    final roomOptions = RoomOptions(
      defaultCameraCaptureOptions: const CameraCaptureOptions(
        cameraPosition: CameraPosition.front,
        params: VideoParametersPresets.h720_169,
      ),
      defaultAudioCaptureOptions: const AudioCaptureOptions(
        noiseSuppression: true,
        echoCancellation: true,
        autoGainControl: true,
      ),
      defaultVideoPublishOptions: const VideoPublishOptions(
        simulcast: false,
      ),
    );

    await _room!.connect(
      serverUrl,
      token,
      connectOptions: connectOptions,
      roomOptions: roomOptions,
    );

    // 3. Activer caméra et micro locaux
    await _room!.localParticipant?.setCameraEnabled(true);
    await _room!.localParticipant?.setMicrophoneEnabled(true);

    return _room!;
  }

  /// Couper/activer le micro
  Future<void> toggleMicro() async {
    final p = _room?.localParticipant;
    if (p == null) return;
    final enabled = p.isMicrophoneEnabled();
    await p.setMicrophoneEnabled(!enabled);
  }

  /// Couper/activer la caméra
  Future<void> toggleCamera() async {
    final p = _room?.localParticipant;
    if (p == null) return;
    final enabled = p.isCameraEnabled();
    await p.setCameraEnabled(!enabled);
  }

  /// Déconnexion propre
  Future<void> quitter() async {
    await _room?.disconnect();
    _room = null;
  }
}
