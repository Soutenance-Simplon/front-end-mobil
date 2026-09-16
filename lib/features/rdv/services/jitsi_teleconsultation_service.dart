import 'package:flutter/foundation.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/salle_teleconsultation_model.dart';
import 'rdv_api_service.dart';

class JitsiTeleconsultationService {
  final RdvApiService _apiService;
  final JitsiMeet _jitsiMeet = JitsiMeet();

  JitsiTeleconsultationService(this._apiService);

  /// Demande l'autorisation au backend (rdv-service) puis lance la visioconférence Jitsi Meet
  Future<bool> rejoindreVisio({
    required String rdvId,
    String? userId,
    String? displayName,
    required Function(String errorMessage) onError,
    Function()? onJoined,
    Function()? onTerminated,
  }) async {
    // 1. Demande d'autorisation et d'obtention de la salle auprès du backend rdv-service
    SalleTeleconsultationModel? salle;
    try {
      salle = await _apiService.rejoindreTeleconsultation(
        rdvId,
        userId: userId,
        displayName: displayName,
      );
    } on TeleconsultationException catch (te) {
      // Erreur métier renvoyée par le backend (ex: salon pas encore ouvert, accès refusé, annulé)
      onError(te.message);
      return false;
    } catch (_) {
      salle = null;
    }

    // Fallback résilient : Si le backend rdv-service local n'est pas connecté ou en mode démo local
    if (salle == null) {
      final cleanId = rdvId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      final roomHash = cleanId.isNotEmpty ? cleanId : "dy_demo_${DateTime.now().millisecondsSinceEpoch}";
      salle = SalleTeleconsultationModel(
        id: "salle_$roomHash",
        rdvId: rdvId,
        nomSalon: "dy_$roomHash",
        jetonAcces: "token_demo",
        serveurUrl: "https://meet.jit.si",
        displayName: displayName ?? "Utilisateur Diam-Yaraam",
      );
    }

    final String roomName = salle.nomSalon.isNotEmpty ? salle.nomSalon : "dy_room_$rdvId";
    final String serverUrl = salle.serveurUrl.isNotEmpty ? salle.serveurUrl : "https://meet.jit.si";
    final String userDisplayName = salle.displayName ?? displayName ?? "Utilisateur Diam-Yaraam";

    // 2. Gestion adaptée selon l'environnement d'exécution (Web vs Mobile natif)
    if (kIsWeb) {
      // Sur Flutter Web : ouverture directe dans un nouvel onglet sécurisé
      try {
        final String encodedName = Uri.encodeComponent(userDisplayName);
        final Uri webUri = Uri.parse("$serverUrl/$roomName#userInfo.displayName=\"$encodedName\"");
        final launched = await launchUrl(
          webUri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
        if (launched) {
          if (onJoined != null) onJoined();
          return true;
        } else {
          onError("Impossible d'ouvrir le salon de visioconférence dans le navigateur.");
          return false;
        }
      } catch (e) {
        onError("Erreur d'ouverture Web : $e");
        return false;
      }
    }

    // Sur Mobile (Android / iOS) : Utilisation du SDK Jitsi Meet officiel
    try {
      final options = JitsiMeetConferenceOptions(
        serverURL: serverUrl,
        room: roomName,
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
          "prejoinPageEnabled": false,
        },
        featureFlags: {
          "welcomepage.enabled": false,
          "resolution": 360,
          "invite.enabled": false,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: userDisplayName,
        ),
      );

      final listener = JitsiMeetEventListener(
        conferenceJoined: (url) {
          if (onJoined != null) onJoined();
        },
        conferenceTerminated: (url, error) {
          if (onTerminated != null) onTerminated();
        },
        participantJoined: (email, name, role, participantId) {},
        participantLeft: (participantId) {},
      );

      if (onJoined != null) onJoined();
      await _jitsiMeet.join(options, listener);
      return true;
    } catch (e) {
      // Fallback externe si le SDK rencontre une limitation sur l'appareil
      final String encodedName = Uri.encodeComponent(userDisplayName);
      final Uri fallbackUri = Uri.parse("$serverUrl/$roomName#userInfo.displayName=\"$encodedName\"");
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        if (onJoined != null) onJoined();
        return true;
      }
      onError("Erreur lors du lancement de Jitsi Meet : $e");
      return false;
    }
  }

  /// Quitter la visioconférence Jitsi en cours
  void meQuitterVisio() {
    try {
      _jitsiMeet.hangUp();
    } catch (_) {}
  }
}
