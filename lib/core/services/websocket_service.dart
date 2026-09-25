import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../network/api_client.dart';

/// Modèle d'une notification reçue en temps réel via WebSocket
class RtNotification {
  final String id;
  final String userId;
  final String type;
  final String titre;
  final String corps;
  final String rdvId;
  final DateTime dateEnvoi;
  bool lue;

  RtNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.titre,
    required this.corps,
    required this.rdvId,
    required this.dateEnvoi,
    this.lue = false,
  });

  factory RtNotification.fromJson(Map<String, dynamic> json) {
    return RtNotification(
      id: json['id']?.toString() ?? 'notif-${DateTime.now().millisecondsSinceEpoch}',
      userId: json['userId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'INFO',
      titre: json['titre']?.toString() ?? 'Notification',
      corps: json['corps']?.toString() ?? json['message']?.toString() ?? '',
      rdvId: json['rdvId']?.toString() ?? '',
      dateEnvoi: DateTime.tryParse(json['dateEnvoi']?.toString() ?? '') ?? DateTime.now(),
      lue: json['lue'] == true || json['lue'] == 'true',
    );
  }
}

/// Événement de mise à jour d'un RDV reçu via WebSocket
class RtRdvUpdate {
  final String rdvId;
  final String type; // CREATE, STATUT_CHANGE, DELETE
  final String statut;
  final String patientId;
  final String medecinId;
  final Map<String, dynamic> rawData;

  RtRdvUpdate({
    required this.rdvId,
    required this.type,
    required this.statut,
    required this.patientId,
    required this.medecinId,
    required this.rawData,
  });

  factory RtRdvUpdate.fromJson(Map<String, dynamic> json) {
    final rdvData = json['rdv'] as Map<String, dynamic>? ?? json;
    return RtRdvUpdate(
      rdvId: (rdvData['id'] ?? json['rdvId'] ?? '').toString(),
      type: json['type']?.toString() ?? 'UPDATE',
      statut: (rdvData['statut'] ?? json['statut'] ?? '').toString(),
      patientId: (rdvData['patientId'] ?? rdvData['patient_id'] ?? '').toString(),
      medecinId: (rdvData['medecinId'] ?? rdvData['medecin_id'] ?? '').toString(),
      rawData: rdvData,
    );
  }
}

/// Service WebSocket STOMP centralisé pour les notifications temps réel.
/// Se connecte à ws://127.0.0.1:8090/ws (via l'API Gateway).
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  StompClient? _client;
  bool _isConnected = false;
  String? _currentUserId;

  // Streams publics pour écouter les événements
  final StreamController<RtNotification> _notificationController =
      StreamController<RtNotification>.broadcast();
  final StreamController<RtRdvUpdate> _rdvUpdateController =
      StreamController<RtRdvUpdate>.broadcast();

  Stream<RtNotification> get onNotification => _notificationController.stream;
  Stream<RtRdvUpdate> get onRdvUpdate => _rdvUpdateController.stream;
  bool get isConnected => _isConnected;

  /// Connexion au serveur WebSocket STOMP avec le JWT de l'utilisateur connecté.
  Future<void> connect({required String userId}) async {
    if (_isConnected && _currentUserId == userId) return;

    _currentUserId = userId;
    final token = await ApiClient().getToken();

    _client = StompClient(
      config: StompConfig(
        url: 'ws://127.0.0.1:8090/ws',
        onConnect: _onConnect,
        onDisconnect: _onDisconnect,
        onWebSocketError: (error) {
          _isConnected = false;
          // Reconnexion automatique après 5 secondes en cas d'erreur
          Future.delayed(const Duration(seconds: 5), () {
            if (!_isConnected) connect(userId: userId);
          });
        },
        stompConnectHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
          'userId': userId,
        },
        webSocketConnectHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _isConnected = true;

    // Abonnement aux notifications globales (toutes) + filtrées par userId côté Flutter
    _client!.subscribe(
      destination: '/topic/notifications',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final data = jsonDecode(frame.body!);
          // Le backend envoie { destination, type, data: {...} }
          final notifData = data['data'] is Map
              ? data['data'] as Map<String, dynamic>
              : data as Map<String, dynamic>;
          final notif = RtNotification.fromJson(notifData);
          // Filtrage côté client : n'émettre que si destinataire = cet utilisateur
          if (notif.userId.isEmpty || notif.userId == _currentUserId) {
            _notificationController.add(notif);
          }
        } catch (_) {}
      },
    );

    // Abonnement aux mises à jour de RDV en temps réel
    _client!.subscribe(
      destination: '/topic/rdv-updates',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          final update = RtRdvUpdate.fromJson(data);
          // Émettre seulement si le RDV concerne l'utilisateur connecté
          if (update.patientId == _currentUserId ||
              update.medecinId == _currentUserId ||
              update.patientId.isEmpty) {
            _rdvUpdateController.add(update);
          }
        } catch (_) {}
      },
    );
  }

  void _onDisconnect(StompFrame frame) {
    _isConnected = false;
  }

  /// Déconnexion propre (à appeler au logout)
  void disconnect() {
    _client?.deactivate();
    _isConnected = false;
    _currentUserId = null;
  }

  void dispose() {
    disconnect();
    _notificationController.close();
    _rdvUpdateController.close();
  }
}

/// Provider Riverpod pour accéder au WebSocketService
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.disconnect());
  return service;
});
