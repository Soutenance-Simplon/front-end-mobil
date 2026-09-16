import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/creneau_model.dart';
import '../models/medecin_model.dart';
import '../models/onms_reference_model.dart';
import '../models/specialite_model.dart';

class MedecinApiService {
  final ApiClient _client = ApiClient();
  Dio get dio => _client.dio;

  /// Vérification ONMS automatique par numéro d'Ordre (RM01 à RM04)
  Future<OnmsReferenceModel?> lookupOnms(String numeroOrdre) async {
    try {
      final response = await dio.get('/medecins/onms/lookup/$numeroOrdre');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return OnmsReferenceModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Inscription et validation ONMS du médecin
  Future<bool> verifyAndRegisterMedecin(String userId, String numeroOrdre) async {
    try {
      final response = await dio.post(
        '/medecins/verify-onms',
        queryParameters: {
          'userId': userId,
          'numeroOrdre': numeroOrdre,
        },
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Recherche filtrée de médecins (Spécialité, Région, Nom)
  Future<List<MedecinModel>> searchMedecins({
    String? specialite,
    String? region,
    String? search,
  }) async {
    try {
      final response = await dio.get(
        '/medecins/search',
        queryParameters: {
          if (specialite != null && specialite.isNotEmpty) 'specialite': specialite,
          if (region != null && region.isNotEmpty) 'region': region,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data is List ? response.data : (response.data['data'] ?? []);
        return list.map((e) => MedecinModel.fromJson(e)).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Détail d'un médecin par son identifiant
  Future<MedecinModel?> getMedecinById(String id) async {
    try {
      final response = await dio.get('/medecins/$id');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return MedecinModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  /// Créneaux disponibles d'un médecin
  Future<List<CreneauModel>> getCreneauxDisponibles(String medecinId, {String? date}) async {
    final token = await _client.getToken();
    final options = Options(
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    try {
      final response = await dio.get(
        '/medecins/$medecinId/creneaux',
        queryParameters: {if (date != null) 'date': date},
        options: options,
      );

      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data is List ? response.data : (response.data['data'] ?? []);
        return list.map((e) => CreneauModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Création d'un créneau de consultation
  Future<CreneauModel?> creerCreneau({
    required String medecinId,
    required DateTime start,
    required DateTime end,
    String type = 'TELECONSULTATION',
  }) async {
    final token = await _client.getToken();
    final options = Options(
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    // Format ISO standard yyyy-MM-ddTHH:mm:ss sans millisecondes pour Spring
    final startStr = start.toIso8601String().split('.').first;
    final endStr = end.toIso8601String().split('.').first;

    try {
      final response = await dio.post(
        '/medecins/$medecinId/creneaux',
        queryParameters: {
          'start': startStr,
          'end': endStr,
          'type': type,
        },
        options: options,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return CreneauModel.fromJson(data);
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response!.data['message'].toString()
          : (e.response?.statusCode == 409
              ? "Collision de créneau détectée : un créneau existe déjà sur cette plage horaire."
              : (e.message ?? "Erreur lors de la création du créneau."));
      throw Exception(msg);
    } catch (e) {
      throw Exception("Erreur lors de la création du créneau : $e");
    }
    return null;
  }

  /// Modification du statut d'un créneau (BLOQUE, DISPONIBLE, RESERVE)
  Future<bool> changerStatutCreneau(String medecinId, String creneauId, String statut) async {
    final token = await _client.getToken();
    final options = Options(
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    try {
      final response = await dio.put(
        '/medecins/$medecinId/creneaux/$creneauId/statut',
        queryParameters: {'statut': statut},
        options: options,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Suppression d'un créneau
  Future<bool> supprimerCreneau(String medecinId, String creneauId) async {
    final token = await _client.getToken();
    final options = Options(
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    try {
      final response = await dio.delete(
        '/medecins/$medecinId/creneaux/$creneauId',
        options: options,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static final List<SpecialiteModel> defaultSpecialites = [
    SpecialiteModel(id: 1, nom: "Cardiologie", description: "Maladies du cœur et des vaisseaux", icone: "favorite"),
    SpecialiteModel(id: 2, nom: "Pédiatrie", description: "Santé des enfants et des nourrissons", icone: "child_care"),
    SpecialiteModel(id: 3, nom: "Médecine Générale", description: "Consultations et soins primaires", icone: "medical_services"),
    SpecialiteModel(id: 4, nom: "Gynécologie Obstétrique", description: "Santé de la femme et suivi de grossesse", icone: "pregnant_woman"),
    SpecialiteModel(id: 5, nom: "Dermatologie", description: "Soins et pathologies de la peau", icone: "healing"),
    SpecialiteModel(id: 6, nom: "Ophtalmologie", description: "Santé des yeux et de la vision", icone: "remove_red_eye"),
    SpecialiteModel(id: 7, nom: "Radiologie", description: "Imagerie médicale et diagnostics", icone: "document_scanner"),
    SpecialiteModel(id: 8, nom: "Neurologie", description: "Système nerveux et cerveau", icone: "psychology"),
    SpecialiteModel(id: 9, nom: "Chirurgie Générale", description: "Interventions et chirurgie", icone: "healing"),
    SpecialiteModel(id: 10, nom: "Pneumologie", description: "Voies respiratoires et poumons", icone: "air"),
  ];

  /// Liste des spécialités médicales disponibles
  Future<List<SpecialiteModel>> getSpecialites() async {
    try {
      final response = await dio.get('/medecins/specialites');
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data is List ? response.data : (response.data['data'] ?? []);
        final parsed = list.map((e) => SpecialiteModel.fromJson(e)).toList();
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
    } catch (_) {}

    return defaultSpecialites;
  }
}
