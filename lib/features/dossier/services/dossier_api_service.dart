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
  Future<bool> ajouterConsultation(String dossierId, ConsultationModel consultation) async {
    try {
      final response = await dio.post(
        '/dossiers/$dossierId/consultations',
        data: consultation.toJson(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Ajouter une prescription / Ordonnance intelligente (IA)
  Future<bool> ajouterPrescription(String dossierId, PrescriptionModel prescription) async {
    try {
      final response = await dio.post(
        '/dossiers/$dossierId/prescriptions',
        data: prescription.toJson(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Ajouter une allergie
  Future<bool> ajouterAllergie(String dossierId, AllergieModel allergie) async {
    try {
      final response = await dio.post(
        '/dossiers/$dossierId/allergies',
        data: allergie.toJson(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Ajouter un antécédent
  Future<bool> ajouterAntecedent(String dossierId, AntecedentModel antecedent) async {
    try {
      final response = await dio.post(
        '/dossiers/$dossierId/antecedents',
        data: antecedent.toJson(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Ajouter un vaccin
  Future<bool> ajouterVaccin(String dossierId, VaccinationModel vaccin) async {
    try {
      final response = await dio.post(
        '/dossiers/$dossierId/vaccinations',
        data: vaccin.toJson(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
