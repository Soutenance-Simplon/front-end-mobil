import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/notification_model.dart';
import '../services/notification_api_service.dart';

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

  NotificationNotifier(this._apiService) : super(const NotificationState());

  Future<void> chargerNotifications({required String userId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _apiService.getNotifications(userId);
      state = state.copyWith(isLoading: false, notifications: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
}

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  return NotificationApiService();
});

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final api = ref.watch(notificationApiServiceProvider);
  final authState = ref.watch(authProvider);
  final notifier = NotificationNotifier(api);
  if (authState.user != null && authState.user!.id.isNotEmpty) {
    notifier.chargerNotifications(userId: authState.user!.id);
  }
  return notifier;
});
