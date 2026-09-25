import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/rendez_vous_model.dart';
import '../models/salle_teleconsultation_model.dart';
import '../services/rdv_api_service.dart';

class RdvState {
  final bool isLoading;
  final String? error;
  final List<RendezVousModel> mesRendezVous;
  final List<RendezVousModel> agendaMedecin;
  final SalleTeleconsultationModel? salonActif;

  const RdvState({
    this.isLoading = false,
    this.error,
    this.mesRendezVous = const [],
    this.agendaMedecin = const [],
    this.salonActif,
  });

  RdvState copyWith({
    bool? isLoading,
    String? error,
    List<RendezVousModel>? mesRendezVous,
    List<RendezVousModel>? agendaMedecin,
    SalleTeleconsultationModel? salonActif,
    bool clearError = false,
  }) {
    return RdvState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      mesRendezVous: mesRendezVous ?? this.mesRendezVous,
      agendaMedecin: agendaMedecin ?? this.agendaMedecin,
      salonActif: salonActif ?? this.salonActif,
    );
  }
}

class RdvNotifier extends StateNotifier<RdvState> {
  final RdvApiService _apiService;

  RdvNotifier(this._apiService) : super(const RdvState());

  /// Charge les rendez-vous d'un patient depuis le backend réel.
  /// Affiche une liste vide si aucun RDV n'existe (pas de fallback fictif).
  Future<void> loadMesRendezVous({required String patientId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _apiService.getRendezVousPatient(patientId);
      state = state.copyWith(isLoading: false, mesRendezVous: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger vos rendez-vous : ${e.toString()}',
        mesRendezVous: [],
      );
    }
  }

  /// Charge l'agenda d'un médecin depuis le backend réel.
  Future<void> loadAgendaMedecin({required String medecinId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _apiService.getAgendaMedecin(medecinId);
      state = state.copyWith(isLoading: false, agendaMedecin: list);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de charger l\'agenda : ${e.toString()}',
        agendaMedecin: [],
      );
    }
  }

  /// Réserve un rendez-vous via le backend.
  /// IMPORTANT : Ne crée PLUS de RDV fictif en local si le backend échoue.
  /// Un retour `false` signifie que le backend n'a pas persisté le RDV.
  Future<bool> reserverRendezVous({
    required String patientId,
    required String medecinId,
    required DateTime dateHeure,
    required String motif,
    String typeConsultation = 'PRESENTIELLE',
    double montant = 15000,
    String? medecinNom,
    String? medecinSpecialite,
  }) async {
    // Validation : au moins 30 min à l'avance
    if (dateHeure.isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
      state = state.copyWith(
        error: "Un rendez-vous doit être pris au moins 30 minutes à l'avance.",
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final rdv = await _apiService.creerRendezVous(
        patientId: patientId,
        medecinId: medecinId,
        dateHeure: dateHeure,
        motif: motif,
        typeConsultation: typeConsultation,
        montant: montant,
      );

      if (rdv != null) {
        // Succès : le RDV existe vraiment en base de données
        state = state.copyWith(
          isLoading: false,
          mesRendezVous: [rdv, ...state.mesRendezVous],
        );
        return true;
      }

      // Le backend a répondu mais sans données valides
      state = state.copyWith(
        isLoading: false,
        error: 'Le rendez-vous n\'a pas pu être créé. Vérifiez votre connexion et réessayez.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création du rendez-vous : ${e.toString()}',
      );
      return false;
    }
  }

  /// Annule un rendez-vous via le backend et met à jour l'état local si succès.
  Future<bool> annulerRdv(String rdvId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _apiService.updateStatutRdv(rdvId, 'ANNULE');
      if (success) {
        final updated = state.mesRendezVous.map((r) {
          if (r.id == rdvId) {
            return RendezVousModel(
              id: r.id,
              patientId: r.patientId,
              medecinId: r.medecinId,
              medecinNom: r.medecinNom,
              medecinSpecialite: r.medecinSpecialite,
              dateHeure: r.dateHeure,
              motif: r.motif,
              typeConsultation: r.typeConsultation,
              statut: 'ANNULE',
              montant: r.montant,
              statutPaiement: 'REMBOURSE',
            );
          }
          return r;
        }).toList();
        state = state.copyWith(isLoading: false, mesRendezVous: updated);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible d\'annuler le rendez-vous.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'annulation : ${e.toString()}',
      );
      return false;
    }
  }

  Future<SalleTeleconsultationModel?> rejoindreSalon(String rdvId) async {
    final salon = await _apiService.rejoindreTeleconsultation(rdvId);
    state = state.copyWith(salonActif: salon);
    return salon;
  }

  /// Met à jour un RDV reçu via WebSocket en temps réel
  void mettreAJourRdvTempsReel(RendezVousModel rdvMisAJour) {
    // Mettre à jour dans mesRendezVous
    final updatedPatient = state.mesRendezVous.map((r) {
      return r.id == rdvMisAJour.id ? rdvMisAJour : r;
    }).toList();
    // Si non trouvé dans la liste patient, c'est peut-être un nouveau RDV
    final existePatient = state.mesRendezVous.any((r) => r.id == rdvMisAJour.id);
    final nouvelleListePatient = existePatient
        ? updatedPatient
        : [rdvMisAJour, ...state.mesRendezVous];

    // Mettre à jour dans agendaMedecin
    final updatedMedecin = state.agendaMedecin.map((r) {
      return r.id == rdvMisAJour.id ? rdvMisAJour : r;
    }).toList();
    final existeMedecin = state.agendaMedecin.any((r) => r.id == rdvMisAJour.id);
    final nouvelleListeMedecin = existeMedecin
        ? updatedMedecin
        : [rdvMisAJour, ...state.agendaMedecin];

    state = state.copyWith(
      mesRendezVous: nouvelleListePatient,
      agendaMedecin: nouvelleListeMedecin,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final rdvApiServiceProvider = Provider<RdvApiService>((ref) {
  return RdvApiService();
});

final rdvProvider = StateNotifierProvider<RdvNotifier, RdvState>((ref) {
  final api = ref.watch(rdvApiServiceProvider);
  final authState = ref.watch(authProvider);
  final notifier = RdvNotifier(api);
  if (authState.user != null && authState.user!.id.isNotEmpty) {
    if (authState.user!.role == 'MEDECIN') {
      notifier.loadAgendaMedecin(medecinId: authState.user!.id);
    } else {
      notifier.loadMesRendezVous(patientId: authState.user!.id);
    }
  }
  return notifier;
});
