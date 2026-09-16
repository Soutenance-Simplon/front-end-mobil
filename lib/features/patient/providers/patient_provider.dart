import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient_model.dart';
import '../models/qr_urgence_model.dart';
import '../services/patient_api_service.dart';

class PatientState {
  final bool isLoading;
  final String? error;
  final PatientModel? patient;
  final QrUrgenceModel? qrUrgenceData;
  final bool isMedecinMode;

  const PatientState({
    this.isLoading = false,
    this.error,
    this.patient,
    this.qrUrgenceData,
    this.isMedecinMode = false,
  });

  PatientState copyWith({
    bool? isLoading,
    String? error,
    PatientModel? patient,
    QrUrgenceModel? qrUrgenceData,
    bool? isMedecinMode,
  }) {
    return PatientState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      patient: patient ?? this.patient,
      qrUrgenceData: qrUrgenceData ?? this.qrUrgenceData,
      isMedecinMode: isMedecinMode ?? this.isMedecinMode,
    );
  }
}

class PatientNotifier extends StateNotifier<PatientState> {
  final PatientApiService _apiService;

  PatientNotifier(this._apiService) : super(const PatientState()) {
    loadProfile();
  }

  void toggleMedecinMode(bool isMedecin) {
    state = state.copyWith(isMedecinMode: isMedecin);
  }

  Future<void> loadProfile({String patientId = 'p1'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final patient = await _apiService.getPatientProfile(patientId);
      state = state.copyWith(isLoading: false, patient: patient);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateEmergencyContact({
    required String patientId,
    required String nom,
    required String telephone,
    required String lien,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedPatient = await _apiService.updateEmergencyContact(patientId, nom, telephone, lien);
      if (updatedPatient != null) {
        state = state.copyWith(isLoading: false, patient: updatedPatient);
      } else {
        state = state.copyWith(isLoading: false, error: "Échec de la mise à jour du contact");
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<QrUrgenceModel?> scannerQr(String token, {bool? isMedecin}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final medecin = isMedecin ?? state.isMedecinMode;
      final data = await _apiService.scanQrUrgence(token, isMedecin: medecin);
      state = state.copyWith(isLoading: false, qrUrgenceData: data);
      return data;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final patientApiServiceProvider = Provider<PatientApiService>((ref) {
  return PatientApiService();
});

final patientProvider = StateNotifierProvider<PatientNotifier, PatientState>((ref) {
  final api = ref.watch(patientApiServiceProvider);
  return PatientNotifier(api);
});
