import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medecin_model.dart';
import '../models/onms_reference_model.dart';
import '../models/specialite_model.dart';
import '../services/medecin_api_service.dart';

class MedecinState {
  final bool isLoading;
  final String? error;
  final List<MedecinModel> medecins;
  final List<SpecialiteModel> specialites;
  final String? selectedSpecialite;
  final String? selectedRegion;
  final String searchQuery;
  final OnmsReferenceModel? onmsLookupResult;

  const MedecinState({
    this.isLoading = false,
    this.error,
    this.medecins = const [],
    this.specialites = const [],
    this.selectedSpecialite,
    this.selectedRegion,
    this.searchQuery = '',
    this.onmsLookupResult,
  });

  MedecinState copyWith({
    bool? isLoading,
    String? error,
    List<MedecinModel>? medecins,
    List<SpecialiteModel>? specialites,
    String? selectedSpecialite,
    String? selectedRegion,
    String? searchQuery,
    OnmsReferenceModel? onmsLookupResult,
  }) {
    return MedecinState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      medecins: medecins ?? this.medecins,
      specialites: specialites ?? this.specialites,
      selectedSpecialite: selectedSpecialite ?? this.selectedSpecialite,
      selectedRegion: selectedRegion ?? this.selectedRegion,
      searchQuery: searchQuery ?? this.searchQuery,
      onmsLookupResult: onmsLookupResult ?? this.onmsLookupResult,
    );
  }
}

class MedecinNotifier extends StateNotifier<MedecinState> {
  final MedecinApiService _apiService;

  MedecinNotifier(this._apiService) : super(const MedecinState()) {
    init();
  }

  Future<void> init() async {
    await loadSpecialites();
    await searchMedecins();
  }

  Future<void> loadSpecialites() async {
    try {
      final specs = await _apiService.getSpecialites();
      state = state.copyWith(specialites: specs);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> searchMedecins({String? query, String? specialite, String? region}) async {
    final resolvedSpecialite = specialite != null
        ? (specialite.trim().isEmpty ? null : specialite.trim())
        : state.selectedSpecialite;

    state = state.copyWith(
      isLoading: true,
      error: null,
      searchQuery: query ?? state.searchQuery,
      selectedSpecialite: resolvedSpecialite,
      selectedRegion: region ?? state.selectedRegion,
    );

    try {
      final results = await _apiService.searchMedecins(
        search: state.searchQuery,
        specialite: state.selectedSpecialite,
        region: state.selectedRegion,
      );
      state = state.copyWith(isLoading: false, medecins: results);
      _enrichSpecialites(results);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _enrichSpecialites(List<MedecinModel> medecins) {
    final existing = state.specialites.map((s) => s.nom.toLowerCase().trim()).toSet();
    final List<SpecialiteModel> toAdd = [];
    int nextId = (state.specialites.isNotEmpty
            ? state.specialites.map((s) => s.id).reduce((a, b) => a > b ? a : b)
            : 0) +
        1;
    for (final m in medecins) {
      final s = m.specialite.trim();
      if (s.isNotEmpty && !existing.contains(s.toLowerCase())) {
        existing.add(s.toLowerCase());
        toAdd.add(SpecialiteModel(
          id: nextId++,
          nom: s,
          description: "Consultation en $s",
        ));
      }
    }
    if (toAdd.isNotEmpty) {
      state = state.copyWith(specialites: [...state.specialites, ...toAdd]);
    }
  }

  Future<OnmsReferenceModel?> lookupOnms(String numeroOrdre) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _apiService.lookupOnms(numeroOrdre);
    state = state.copyWith(isLoading: false, onmsLookupResult: result);
    return result;
  }
}

final medecinApiServiceProvider = Provider<MedecinApiService>((ref) {
  return MedecinApiService();
});

final medecinProvider = StateNotifierProvider<MedecinNotifier, MedecinState>((ref) {
  final api = ref.watch(medecinApiServiceProvider);
  return MedecinNotifier(api);
});
