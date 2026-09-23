import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/allergie_model.dart';
import '../models/antecedent_model.dart';
import '../models/consultation_model.dart';
import '../models/dossier_medical_model.dart';
import '../models/maladie_chronique_model.dart';
import '../models/prescription_model.dart';
import '../models/vaccination_model.dart';
import '../services/dossier_api_service.dart';

class DossierState {
  final bool isLoading;
  final String? error;
  final DossierMedicalModel? dossier;

  const DossierState({
    this.isLoading = false,
    this.error,
    this.dossier,
  });

  DossierState copyWith({
    bool? isLoading,
    String? error,
    DossierMedicalModel? dossier,
  }) {
    return DossierState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      dossier: dossier ?? this.dossier,
    );
  }
}

class DossierNotifier extends StateNotifier<DossierState> {
  final DossierApiService _apiService;

  DossierNotifier(this._apiService) : super(const DossierState()) {
    loadDossier();
  }

  DossierMedicalModel _genererDossierParDefaut(String patientId, {String? groupe, double? poids, double? taille}) {
    return DossierMedicalModel(
      id: "dos-${patientId.replaceAll('-', '').toLowerCase()}",
      patientId: patientId,
      groupeSanguin: groupe ?? 'Non renseigné',
      poidsKg: poids ?? 0,
      tailleCm: taille ?? 0,
      allergies: const [],
      antecedents: const [],
      maladiesChroniques: const [],
      vaccinations: const [],
      consultations: const [],
      prescriptions: const [],
    );
  }

  Future<void> loadDossier({String patientId = 'p1', String? defaultGroupe, double? defaultPoids, double? defaultTaille}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dossierApi = await _apiService.getDossierByPatientId(patientId);
      if (dossierApi != null) {
        state = state.copyWith(isLoading: false, dossier: dossierApi);
      } else {
        final fallback = _genererDossierParDefaut(patientId, groupe: defaultGroupe, poids: defaultPoids, taille: defaultTaille);
        state = state.copyWith(isLoading: false, dossier: fallback);
      }
    } catch (e) {
      final fallback = _genererDossierParDefaut(patientId, groupe: defaultGroupe, poids: defaultPoids, taille: defaultTaille);
      state = state.copyWith(isLoading: false, dossier: fallback);
    }
  }

  Future<bool> mettreAJourConstantes({
    required String groupeSanguin,
    required double poidsKg,
    required double tailleCm,
  }) async {
    if (state.dossier == null) return false;
    final current = state.dossier!;
    final updated = DossierMedicalModel(
      id: current.id,
      patientId: current.patientId,
      groupeSanguin: groupeSanguin,
      poidsKg: poidsKg,
      tailleCm: tailleCm,
      allergies: current.allergies,
      antecedents: current.antecedents,
      maladiesChroniques: current.maladiesChroniques,
      vaccinations: current.vaccinations,
      consultations: current.consultations,
      prescriptions: current.prescriptions,
      documents: current.documents,
      hospitalisations: current.hospitalisations,
    );
    state = state.copyWith(dossier: updated);
    return true;
  }

  Future<bool> ajouterConsultation(ConsultationModel consultation) async {
    if (state.dossier == null) return false;
    await _apiService.ajouterConsultation(state.dossier!.id, consultation);
    final updated = DossierMedicalModel(
      id: state.dossier!.id,
      patientId: state.dossier!.patientId,
      groupeSanguin: state.dossier!.groupeSanguin,
      poidsKg: state.dossier!.poidsKg,
      tailleCm: state.dossier!.tailleCm,
      allergies: state.dossier!.allergies,
      antecedents: state.dossier!.antecedents,
      maladiesChroniques: state.dossier!.maladiesChroniques,
      vaccinations: state.dossier!.vaccinations,
      consultations: [consultation, ...state.dossier!.consultations],
      prescriptions: state.dossier!.prescriptions,
      documents: state.dossier!.documents,
      hospitalisations: state.dossier!.hospitalisations,
    );
    state = state.copyWith(dossier: updated);
    return true;
  }

  Future<bool> ajouterPrescription(PrescriptionModel prescription) async {
    if (state.dossier == null) return false;
    await _apiService.ajouterPrescription(state.dossier!.id, prescription);
    final updated = DossierMedicalModel(
      id: state.dossier!.id,
      patientId: state.dossier!.patientId,
      groupeSanguin: state.dossier!.groupeSanguin,
      poidsKg: state.dossier!.poidsKg,
      tailleCm: state.dossier!.tailleCm,
      allergies: state.dossier!.allergies,
      antecedents: state.dossier!.antecedents,
      maladiesChroniques: state.dossier!.maladiesChroniques,
      vaccinations: state.dossier!.vaccinations,
      consultations: state.dossier!.consultations,
      prescriptions: [prescription, ...state.dossier!.prescriptions],
      documents: state.dossier!.documents,
      hospitalisations: state.dossier!.hospitalisations,
    );
    state = state.copyWith(dossier: updated);
    return true;
  }

  Future<bool> ajouterAllergieDirect({
    required String nomAllergene,
    required String severite,
    String type = 'MEDICAMENTEUSE',
    String? reaction,
  }) async {
    if (state.dossier == null) return false;
    final allergie = AllergieModel(
      id: 'all-${DateTime.now().millisecondsSinceEpoch}',
      nomAllergene: nomAllergene,
      typeAllergie: type,
      severite: severite,
      reaction: reaction,
    );
    await _apiService.ajouterAllergie(state.dossier!.id, allergie);
    final updated = DossierMedicalModel(
      id: state.dossier!.id,
      patientId: state.dossier!.patientId,
      groupeSanguin: state.dossier!.groupeSanguin,
      poidsKg: state.dossier!.poidsKg,
      tailleCm: state.dossier!.tailleCm,
      allergies: [allergie, ...state.dossier!.allergies],
      antecedents: state.dossier!.antecedents,
      maladiesChroniques: state.dossier!.maladiesChroniques,
      vaccinations: state.dossier!.vaccinations,
      consultations: state.dossier!.consultations,
      prescriptions: state.dossier!.prescriptions,
      documents: state.dossier!.documents,
      hospitalisations: state.dossier!.hospitalisations,
    );
    state = state.copyWith(dossier: updated);
    return true;
  }

  Future<bool> ajouterAntecedentDirect({
    required String description,
    required String type,
    int? annee,
  }) async {
    if (state.dossier == null) return false;
    final antecedent = AntecedentModel(
      id: 'ant-${DateTime.now().millisecondsSinceEpoch}',
      description: description,
      typeAntecedent: type,
      dateEvenement: annee?.toString(),
    );
    await _apiService.ajouterAntecedent(state.dossier!.id, antecedent);
    final updated = DossierMedicalModel(
      id: state.dossier!.id,
      patientId: state.dossier!.patientId,
      groupeSanguin: state.dossier!.groupeSanguin,
      poidsKg: state.dossier!.poidsKg,
      tailleCm: state.dossier!.tailleCm,
      allergies: state.dossier!.allergies,
      antecedents: [antecedent, ...state.dossier!.antecedents],
      maladiesChroniques: state.dossier!.maladiesChroniques,
      vaccinations: state.dossier!.vaccinations,
      consultations: state.dossier!.consultations,
      prescriptions: state.dossier!.prescriptions,
      documents: state.dossier!.documents,
      hospitalisations: state.dossier!.hospitalisations,
    );
    state = state.copyWith(dossier: updated);
    return true;
  }
}

final dossierApiServiceProvider = Provider<DossierApiService>((ref) {
  return DossierApiService();
});

final dossierProvider = StateNotifierProvider<DossierNotifier, DossierState>((ref) {
  final api = ref.watch(dossierApiServiceProvider);
  return DossierNotifier(api);
});
