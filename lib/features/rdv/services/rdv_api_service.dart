import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/rendez_vous_model.dart';
import '../models/salle_teleconsultation_model.dart';

class RdvApiService {
  final ApiClient _client = ApiClient();
  Dio get dio => _client.dio;

  /// Créer une nouvelle demande de rendez-vous
  Future<RendezVousModel?> creerRendezVous({
    required String patientId,
    required String medecinId,
    required DateTime dateHeure,
    required String motif,
    String typeConsultation = 'PRESENTIELLE',
    double montant = 15000,
  }) async {
    try {
      final response = await dio.post(
        '/rdv',
        data: {
          'patient_id': patientId,
          'medecin_id': medecinId,
          'date_heure': dateHeure.toIso8601String(),
          'motif': motif,
          'type_consultation': typeConsultation,
          'montant': montant,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        return RendezVousModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Récupérer les rendez-vous d'un patient
  Future<List<RendezVousModel>> getRendezVousPatient(String patientId) async {
    try {
      final response = await dio.get('/rdv/patient/$patientId');
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data is List ? response.data : (response.data['data'] ?? []);
        return list.map((e) => RendezVousModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Récupérer l'agenda d'un médecin
  Future<List<RendezVousModel>> getAgendaMedecin(String medecinId) async {
    try {
      final response = await dio.get('/rdv/medecin/$medecinId');
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data is List ? response.data : (response.data['data'] ?? []);
        return list.map((e) => RendezVousModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Changer le statut d'un rendez-vous (CONFIRME, ANNULE, TERMINE)
  Future<bool> updateStatutRdv(String rdvId, String statut) async {
    try {
      final response = await dio.put(
        '/rdv/$rdvId/statut',
        data: {'statut': statut},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Obtenir la session de téléconsultation sécurisée auprès du backend rdv-service
  Future<SalleTeleconsultationModel?> rejoindreTeleconsultation(
    String rdvId, {
    String? userId,
    String? displayName,
  }) async {
    try {
      final response = await dio.post(
        '/rdv/$rdvId/teleconsultation/join',
        queryParameters: {
          if (userId != null && userId.isNotEmpty) 'userId': userId,
          if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return SalleTeleconsultationModel.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final resData = e.response!.data;
        if (resData is Map && resData['message'] != null && resData['message'].toString().isNotEmpty) {
          throw TeleconsultationException(resData['message'].toString(), e.response?.statusCode);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

class TeleconsultationException implements Exception {
  final String message;
  final int? statusCode;
  TeleconsultationException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}
