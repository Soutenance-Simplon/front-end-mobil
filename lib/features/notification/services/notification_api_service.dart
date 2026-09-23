import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationApiService {
  final ApiClient _client = ApiClient();
  Dio get dio => _client.dio;

  /// Récupérer les notifications d'un utilisateur
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final response = await dio.get('/notifications/user/$userId');
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data is List ? response.data : (response.data['data'] ?? []);
        return list.map((e) => NotificationModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Marquer une notification comme lue
  Future<bool> marquerCommeLue(String notificationId) async {
    try {
      final response = await dio.put('/notifications/$notificationId/lire');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
