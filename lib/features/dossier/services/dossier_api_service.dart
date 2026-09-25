import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/allergie_model.dart';
import '../models/antecedent_model.dart';
import '../models/consultation_model.dart';
import '../models/dossier_medical_model.dart';
import '../models/prescription_model.dart';
import '../models/vaccination_model.dart';

class DossierApiService {
  final ApiClient _client = ApiClient();
  Dio get dio => _client.dio;

  /// Récupérer le dossier médical complet du patient
  Future<DossierMedicalModel?> getDossierByPatientId(String patientId) async {
    try {
      final response = await dio.get('/dossiers/patient/$patientId');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return DossierMedicalModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Ajouter une nouvelle consultation
  Future<bool> ajouterConsultation(String patientId, ConsultationModel consultation) async {
    try {
      final response = await dio.post(
        '/dossiers/patient/$patientId/consultations',
        data: consultation.toJson(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Ajouter une prescription / Ordonnance intelligente (IA)
  Future<bool> ajouterPrescription(String patientId, PrescriptionModel prescription) async {
    try {
      final response = await dio.post(
        '/dossiers/patient/$patientId/prescriptions',
        data: prescription.toJson(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Ajouter une allergie
  Future<bool> ajouterAllergie(String patientId, AllergieModel allergie) async {
    try {
      final response = await dio.post(
        '/dossiers/patient/$patientId/allergies',
        data: allergie.toJson(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Ajouter un antécédent
  Future<bool> ajouterAntecedent(String patientId, AntecedentModel antecedent) async {
    try {
      final response = await dio.post(
        '/dossiers/patient/$patientId/antecedents',
        data: antecedent.toJson(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Ajouter un vaccin
  Future<bool> ajouterVaccin(String patientId, VaccinationModel vaccin) async {
    try {
      final response = await dio.post(
        '/dossiers/patient/$patientId/vaccinations',
        data: vaccin.toJson(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
