import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/models/specialite_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  // Base URL vers l'API Gateway Spring Cloud (port 8090)
  static String get baseUrl => 'http://127.0.0.1:8090/api';

  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await _storage.deleteAll();
          }
          handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // ==========================================
  // 🩺 MÉDECINS & ONMS
  // ==========================================

  /// Recherche automatique des données ONMS par numéro d'Ordre
  Future<Map<String, dynamic>?> lookupOnms(String numeroOrdre) async {
    try {
      final response = await _dio.get('/medecins/onms/lookup/$numeroOrdre');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Vérification et enregistrement d'un Médecin ONMS
  Future<bool> verifyAndRegisterMedecin(String userId, String numeroOrdre) async {
    try {
      final response = await _dio.post(
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

  /// Recherche de médecins par spécialité et région
  Future<List<dynamic>> searchMedecins({String? specialite, String? region}) async {
    try {
      final response = await _dio.get(
        '/medecins/search',
        queryParameters: {
          if (specialite != null) 'specialite': specialite,
          if (region != null) 'region': region,
        },
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // 🪪 QR CODE SANTÉ & URGENCE (DUAL-VIEW)
  // ==========================================

  /// Scan du QR Code d'urgence (Vue Citoyen vs Vue Médecin Authentifié)
  Future<Map<String, dynamic>?> scanQrUrgence(String qrToken, {bool isMedecin = false}) async {
    try {
      final response = await _dio.get(
        '/qr-urgence/scan/$qrToken',
        queryParameters: {'isMedecin': isMedecin},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // 📁 DOSSIER MÉDICAL NUMÉRIQUE
  // ==========================================

  Future<Map<String, dynamic>?> getDossierMedical(String patientId) async {
    try {
      final response = await _dio.get('/dossiers/patient/$patientId');
      return response.data['data'];
    } catch (e) {
      return null;
    }
  }

  Future<bool> addAllergie(String patientId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/dossiers/patient/$patientId/allergies', data: data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addConsultation(String patientId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/dossiers/patient/$patientId/consultations', data: data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 📅 RENDEZ-VOUS & TÉLÉCONSULTATION
  // ==========================================

  Future<Map<String, dynamic>?> demanderRendezVous({
    required String patientId,
    required String medecinId,
    required String motif,
    required String dateHeureIso,
  }) async {
    try {
      final response = await _dio.post(
        '/rdv/demander',
        queryParameters: {
          'patientId': patientId,
          'medecinId': medecinId,
          'motif': motif,
          'dateHeure': dateHeureIso,
        },
      );
      return response.data['data'];
    } catch (e) {
      return null;
    }
  }

  Future<bool> confirmerPaiementRdv(String rdvId, String refPaiement) async {
    try {
      final response = await _dio.put(
        '/rdv/$rdvId/confirmer-paiement',
        queryParameters: {'refPaiement': refPaiement},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 💳 WALLET SANTÉ & PAIEMENTS (WAVE)
  // ==========================================

  Future<Map<String, dynamic>?> getPortefeuille(String userId) async {
    try {
      final response = await _dio.get('/wallet/user/$userId');
      return response.data['data'];
    } catch (e) {
      return null;
    }
  }

  Future<bool> deposerFonds({
    required String userId,
    required double montant,
    String moyen = "MOBILE_MONEY_WAVE",
  }) async {
    try {
      final response = await _dio.post(
        '/wallet/deposer',
        queryParameters: {
          'userId': userId,
          'montant': montant,
          'moyen': moyen,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> payerPourProche({
    required String tuteurUserId,
    required String beneficiaireUserId,
    required double montant,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        '/wallet/payer-pour-proche',
        queryParameters: {
          'tuteurUserId': tuteurUserId,
          'beneficiaireUserId': beneficiaireUserId,
          'montant': montant,
          if (description != null) 'description': description,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // SPÉCIALITÉS & TOP DOCTORS
  // ==========================================

  Future<List<Specialite>> getSpecialites() async {
    try {
      final response = await _dio.get('/medecins/search');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List data = response.data['data'];
        return data.map((e) => Specialite.fromJson(e)).toList();
      }
    } catch (e) {
      // Fallback local pour la présentation
    }
    return [
      Specialite(id: 1, nom: "Cardiologie", description: "Maladies du cœur et des vaisseaux"),
      Specialite(id: 2, nom: "Pédiatrie", description: "Santé des enfants et des nourrissons"),
      Specialite(id: 3, nom: "Gynécologie", description: "Santé de la femme et suivi de grossesse"),
      Specialite(id: 4, nom: "Médecine Générale", description: "Consultations et soins primaires"),
    ];
  }

  Future<List<dynamic>> getTopDoctors() async {
    return searchMedecins();
  }
}
