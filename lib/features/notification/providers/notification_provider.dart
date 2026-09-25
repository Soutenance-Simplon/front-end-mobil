import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/notification_model.dart';
import '../services/notification_api_service.dart';
import '../../../core/services/websocket_service.dart';

class NotificationState {
  final bool isLoading;
  final String? error;
  final List<NotificationModel> notifications;

  const NotificationState({
    this.isLoading = false,
    this.error,
    this.notifications = const [],
  });

  int get nonLuesCount => notifications.where((n) => !n.lue).length;

  NotificationState copyWith({
    bool? isLoading,
    String? error,
    List<NotificationModel>? notifications,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      notifications: notifications ?? this.notifications,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationApiService _apiService;
  final WebSocketService _wsService;
  StreamSubscription<RtNotification>? _wsSub;

  NotificationNotifier(this._apiService, this._wsService)
      : super(const NotificationState());

  /// Charge les notifications depuis le backend ET écoute les nouvelles en temps réel.
  Future<void> chargerNotifications({required String userId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _apiService.getNotifications(userId);
      state = state.copyWith(isLoading: false, notifications: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }

    // Écouter les nouvelles notifications via WebSocket
    _wsSub?.cancel();
    _wsSub = _wsService.onNotification.listen((rtNotif) {
      // Convertir RtNotification en NotificationModel
      final newNotif = NotificationModel(
        id: rtNotif.id,
        userId: rtNotif.userId.isNotEmpty ? rtNotif.userId : userId,
        titre: rtNotif.titre,
        corps: rtNotif.corps,
        typeNotification: rtNotif.type,
        dateEnvoi: rtNotif.dateEnvoi,
        lue: false,
        lienRedirection: rtNotif.rdvId.isNotEmpty ? '/rdv/${rtNotif.rdvId}' : null,
      );

      // Éviter les doublons
      final dejaPresente = state.notifications.any((n) => n.id == newNotif.id);
      if (!dejaPresente) {
        state = state.copyWith(
          notifications: [newNotif, ...state.notifications],
        );
      }
    });
  }

  Future<void> marquerCommeLue(String id) async {
    await _apiService.marquerCommeLue(id);
    final maj = state.notifications.map((n) {
      if (n.id == id) {
        return NotificationModel(
          id: n.id,
          userId: n.userId,
          titre: n.titre,
          corps: n.corps,
          typeNotification: n.typeNotification,
          dateEnvoi: n.dateEnvoi,
          lue: true,
          lienRedirection: n.lienRedirection,
        );
      }
      return n;
    }).toList();
    state = state.copyWith(notifications: maj);
  }

  Future<void> toutMarquerCommeLu() async {
    final maj = state.notifications.map((n) => NotificationModel(
          id: n.id,
          userId: n.userId,
          titre: n.titre,
          corps: n.corps,
          typeNotification: n.typeNotification,
          dateEnvoi: n.dateEnvoi,
          lue: true,
          lienRedirection: n.lienRedirection,
        )).toList();
    state = state.copyWith(notifications: maj);
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }
}

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  return NotificationApiService();
});

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final api = ref.watch(notificationApiServiceProvider);
  final ws = ref.watch(webSocketServiceProvider);
  final authState = ref.watch(authProvider);
  final notifier = NotificationNotifier(api, ws);
  if (authState.user != null && authState.user!.id.isNotEmpty) {
    notifier.chargerNotifications(userId: authState.user!.id);
  }
  return notifier;
});
