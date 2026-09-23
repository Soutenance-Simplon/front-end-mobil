import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/interaction_medicamenteuse_model.dart';
import '../models/message_ia_model.dart';
import '../models/tri_symptome_model.dart';
import '../services/ia_api_service.dart';

class IaState {
  final bool isLoading;
  final String? error;
  final List<MessageIaModel> messages;
  final TriSymptomeModel? dernierTriage;
  final List<InteractionMedicamenteuseModel> alertesInteractions;

  const IaState({
    this.isLoading = false,
    this.error,
    this.messages = const [],
    this.dernierTriage,
    this.alertesInteractions = const [],
  });

  IaState copyWith({
    bool? isLoading,
    String? error,
    List<MessageIaModel>? messages,
    TriSymptomeModel? dernierTriage,
    List<InteractionMedicamenteuseModel>? alertesInteractions,
  }) {
    return IaState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      messages: messages ?? this.messages,
      dernierTriage: dernierTriage ?? this.dernierTriage,
      alertesInteractions: alertesInteractions ?? this.alertesInteractions,
    );
  }
}

class IaNotifier extends StateNotifier<IaState> {
  final IaApiService _apiService;

  IaNotifier(this._apiService)
      : super(
          IaState(
            messages: [
              MessageIaModel(
                id: 'init-1',
                contenu: "Bonjour ! Je suis l'assistant médical intelligent Diam Yaraam. Décrivez-moi vos symptômes ou posez une question médicale.",
                estUtilisateur: false,
                timestamp: DateTime.now(),
              ),
            ],
          ),
        );

  Future<void> initialiserContextePatient(Map<String, dynamic>? dossier, List<dynamic> famille) async {
    // Si déjà initialisé, on ignore
    if (state.messages.any((m) => m.contenu.startsWith("CONTEXTE_SYSTEME:"))) return;

    String contexte = "CONTEXTE_SYSTEME: L'utilisateur actuel a les informations suivantes dans son dossier médical : ";
    if (dossier != null) {
      final maladies = dossier['maladiesChroniques'] ?? [];
      final allergies = dossier['allergies'] ?? [];
      contexte += "Maladies chroniques: ${maladies.isNotEmpty ? maladies.join(', ') : 'Aucune'}. ";
      contexte += "Allergies: ${allergies.isNotEmpty ? allergies.join(', ') : 'Aucune'}. ";
    }
    
    if (famille.isNotEmpty) {
      contexte += "Antécédents familiaux connus: ";
      for (var membre in famille) {
        final fMaladies = membre['maladiesChroniques'] ?? [];
        if (fMaladies.isNotEmpty) {
          contexte += "${membre['lienParente']} souffre de ${fMaladies.join(', ')}. ";
        }
      }
    }

    contexte += "Veuillez utiliser ces informations pour personnaliser la prévention et les conseils médicaux.";

    final msgSysteme = MessageIaModel(
      id: 'sys-${DateTime.now().millisecondsSinceEpoch}',
      contenu: contexte,
      estUtilisateur: true,
      timestamp: DateTime.now(),
    );

    // On l'ajoute à l'état sans le rendre visible dans l'UI (l'UI devra filtrer les messages commençant par CONTEXTE_SYSTEME)
    state = state.copyWith(
      messages: [msgSysteme, ...state.messages],
    );
  }

  Future<void> envoyerMessage(String texte) async {
    final msgUser = MessageIaModel(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      contenu: texte,
      estUtilisateur: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      isLoading: true,
      messages: [...state.messages, msgUser],
    );

    try {
      final reponseIa = await _apiService.envoyerMessage(texte, historique: state.messages);
      state = state.copyWith(
        isLoading: false,
        messages: [...state.messages, reponseIa],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<TriSymptomeModel> evaluerSymptomes(String texte) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final triage = await _apiService.evaluerSymptomes(texte);
      state = state.copyWith(isLoading: false, dernierTriage: triage);
      return triage;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<List<InteractionMedicamenteuseModel>> verifierInteractions({
    required List<String> medicaments,
    required List<String> allergies,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final alertes = await _apiService.verifierInteractions(
        medicaments: medicaments,
        allergies: allergies,
      );
      state = state.copyWith(isLoading: false, alertesInteractions: alertes);
      return alertes;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return [];
    }
  }
}

final iaApiServiceProvider = Provider<IaApiService>((ref) {
  return IaApiService();
});

final iaProvider = StateNotifierProvider<IaNotifier, IaState>((ref) {
  final api = ref.watch(iaApiServiceProvider);
  return IaNotifier(api);
});
