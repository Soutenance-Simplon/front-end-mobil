import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../medecin/models/creneau_model.dart';
import '../../medecin/providers/medecin_provider.dart';
import '../../medecin/services/medecin_api_service.dart';

class PlanningState {
  final bool isLoading;
  final String? error;
  final List<CreneauModel> tousLesCreneaux;
  final String? medecinIdCharge;

  const PlanningState({
    this.isLoading = false,
    this.error,
    this.tousLesCreneaux = const [],
    this.medecinIdCharge,
  });

  PlanningState copyWith({
    bool? isLoading,
    String? error,
    List<CreneauModel>? tousLesCreneaux,
    String? medecinIdCharge,
  }) {
    return PlanningState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      tousLesCreneaux: tousLesCreneaux ?? this.tousLesCreneaux,
      medecinIdCharge: medecinIdCharge ?? this.medecinIdCharge,
    );
  }
}

class PlanningNotifier extends StateNotifier<PlanningState> {
  final MedecinApiService _apiService;

  PlanningNotifier(this._apiService) : super(const PlanningState());

  /// Charger les vrais créneaux enregistrés en base pour un médecin
  Future<void> chargerCreneauxDuMedecin(String medecinId) async {
    if (medecinId.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final list = await _apiService.getCreneauxDisponibles(medecinId);
      state = state.copyWith(
        isLoading: false,
        tousLesCreneaux: list,
        medecinIdCharge: medecinId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        tousLesCreneaux: [],
      );
    }
  }

  /// Retourne UNIQUEMENT les créneaux réels DISPONIBLES et FUTURS pour ce médecin et cette date exacte
  List<CreneauModel> getCreneauxDisponibles({
    required String medecinId,
    required DateTime date,
    String? periode, // 'Matin' ou 'Soir'
  }) {
    final now = DateTime.now();
    return state.tousLesCreneaux.where((c) {
      final matchDate = c.dateHeureDebut.year == date.year &&
          c.dateHeureDebut.month == date.month &&
          c.dateHeureDebut.day == date.day;
      final estDisponible = c.statut == 'DISPONIBLE';

      if (!matchDate || !estDisponible) return false;

      // EXCLURE FORMELLEMENT LES CRÉNEAUX DÉJÀ PASSÉS OU À MOINS DE 30 MINUTES
      if (c.dateHeureDebut.isBefore(now.add(const Duration(minutes: 30)))) return false;

      if (periode == 'Matin') {
        return c.dateHeureDebut.hour < 13;
      } else if (periode == 'Soir') {
        return c.dateHeureDebut.hour >= 13;
      }
      return true;
    }).toList();
  }

  /// Le médecin ajoute un vrai créneau dans la base PostgreSQL du backend
  Future<CreneauModel?> ajouterCreneau({
    required String medecinId,
    required DateTime dateHeureDebut,
    required DateTime dateHeureFin,
    required String typeConsultation,
  }) async {
    // CONTRÔLE STRICT : IMPOSSIBLE DE CRÉER UN CRÉNEAU DANS LE PASSÉ
    if (dateHeureDebut.isBefore(DateTime.now())) {
      state = state.copyWith(isLoading: false, error: "Impossible de créer un créneau pour une date ou une heure passée.");
      throw Exception("Impossible de créer un créneau pour une date ou une heure passée.");
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final created = await _apiService.creerCreneau(
        medecinId: medecinId,
        start: dateHeureDebut,
        end: dateHeureFin,
        type: typeConsultation,
      );

      if (created != null) {
        state = state.copyWith(
          isLoading: false,
          tousLesCreneaux: [...state.tousLesCreneaux, created],
        );
        return created;
      }
      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      final cleanError = e.toString().replaceFirst("Exception: ", "");
      state = state.copyWith(isLoading: false, error: cleanError);
      rethrow;
    }
  }

  /// Le patient ou le médecin réserve / débloque un créneau
  Future<void> reserverCreneau({required String creneauId, String? medecinId}) async {
    final medId = medecinId ?? state.medecinIdCharge ?? 'med-1';
    _apiService.changerStatutCreneau(medId, creneauId, 'RESERVE');

    final updated = state.tousLesCreneaux.map((c) {
      if (c.id == creneauId) {
        return CreneauModel(
          id: c.id,
          medecinId: c.medecinId,
          dateHeureDebut: c.dateHeureDebut,
          dateHeureFin: c.dateHeureFin,
          typeConsultation: c.typeConsultation,
          statut: "RESERVE",
        );
      }
      return c;
    }).toList();

    state = state.copyWith(tousLesCreneaux: updated);
  }

  /// Bloquer un créneau
  Future<void> bloquerCreneau({required String creneauId, String? medecinId}) async {
    final medId = medecinId ?? state.medecinIdCharge ?? 'med-1';
    _apiService.changerStatutCreneau(medId, creneauId, 'BLOQUE');

    final updated = state.tousLesCreneaux.map((c) {
      if (c.id == creneauId) {
        return CreneauModel(
          id: c.id,
          medecinId: c.medecinId,
          dateHeureDebut: c.dateHeureDebut,
          dateHeureFin: c.dateHeureFin,
          typeConsultation: c.typeConsultation,
          statut: "BLOQUE",
        );
      }
      return c;
    }).toList();

    state = state.copyWith(tousLesCreneaux: updated);
  }

  /// Rendre disponible un créneau
  Future<void> debloquerCreneau({required String creneauId, String? medecinId}) async {
    final medId = medecinId ?? state.medecinIdCharge ?? 'med-1';
    _apiService.changerStatutCreneau(medId, creneauId, 'DISPONIBLE');

    final updated = state.tousLesCreneaux.map((c) {
      if (c.id == creneauId) {
        return CreneauModel(
          id: c.id,
          medecinId: c.medecinId,
          dateHeureDebut: c.dateHeureDebut,
          dateHeureFin: c.dateHeureFin,
          typeConsultation: c.typeConsultation,
          statut: "DISPONIBLE",
        );
      }
      return c;
    }).toList();

    state = state.copyWith(tousLesCreneaux: updated);
  }

  /// Supprimer un créneau
  Future<void> supprimerCreneau({required String creneauId, String? medecinId}) async {
    final medId = medecinId ?? state.medecinIdCharge ?? 'med-1';
    _apiService.supprimerCreneau(medId, creneauId);

    state = state.copyWith(
      tousLesCreneaux: state.tousLesCreneaux.where((c) => c.id != creneauId).toList(),
    );
  }
}

final planningProvider = StateNotifierProvider<PlanningNotifier, PlanningState>((ref) {
  final api = ref.watch(medecinApiServiceProvider);
  return PlanningNotifier(api);
});
