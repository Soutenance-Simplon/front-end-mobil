import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/interaction_medicamenteuse_model.dart';
import '../models/message_ia_model.dart';
import '../models/tri_symptome_model.dart';

class IaApiService {
  final ApiClient _client = ApiClient();
  Dio get dio => _client.dio;

  /// Évaluation intelligente des symptômes (Triage IA)
  Future<TriSymptomeModel> evaluerSymptomes(String description) async {
    try {
      final response = await dio.post(
        '/ia/triage',
        data: {'description': description},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return TriSymptomeModel.fromJson(data);
      }
      return _getFallbackTriage(description);
    } catch (e) {
      return _getFallbackTriage(description);
    }
  }

  /// Détection des contre-indications & interactions médicamenteuses
  Future<List<InteractionMedicamenteuseModel>> verifierInteractions({
    required List<String> medicaments,
    required List<String> allergies,
  }) async {
    try {
      final response = await dio.post(
        '/ia/interactions',
        data: {
          'medicaments': medicaments,
          'allergies': allergies,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data is List ? response.data : (response.data['data'] ?? []);
        return list.map((e) => InteractionMedicamenteuseModel.fromJson(e)).toList();
      }
      return _getDemoInteractions(medicaments, allergies);
    } catch (e) {
      return _getDemoInteractions(medicaments, allergies);
    }
  }

  /// Assistant conversationnel médical Diam Yaraam
  Future<MessageIaModel> envoyerMessage(String message, {List<MessageIaModel>? historique}) async {
    try {
      final response = await dio.post(
        '/ia/chat',
        data: {
          'message': message,
          'history': (historique ?? []).map((m) => m.toJson()).toList(),
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return MessageIaModel.fromJson(data);
      }
      return _getFallbackResponse(message);
    } catch (e) {
      return _getFallbackResponse(message);
    }
  }

  TriSymptomeModel _getFallbackTriage(String text) {
    return TriSymptomeModel(
      descriptionSymptomes: text,
      niveauGravite: 'INDISPONIBLE',
      orientationSuggeree: '',
      conseilImmediat:
          "Le service d'analyse IA est temporairement indisponible. Veuillez consulter un professionnel de santé agréé ou appeler le SAMU (1515) en cas d'urgence.",
      questionsSuivi: [],
    );
  }

  List<InteractionMedicamenteuseModel> _getDemoInteractions(
      List<String> meds, List<String> allergies) {
    return [];
  }

  MessageIaModel _getFallbackResponse(String userMsg) {
    return MessageIaModel(
      id: 'ia-${DateTime.now().millisecondsSinceEpoch}',
      contenu:
          "Le service d'assistant IA est temporairement indisponible. Veuillez réessayer dans quelques instants ou prendre directement rendez-vous avec un médecin agréé.",
      estUtilisateur: false,
      timestamp: DateTime.now(),
      recommandations: [],
    );
  }
}
