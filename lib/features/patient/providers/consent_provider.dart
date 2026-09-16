import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medecin_consent_model.dart';

class ConsentState {
  final bool isLoading;
  final String? message;
  final List<MedecinConsentModel> medecins;

  const ConsentState({
    this.isLoading = false,
    this.message,
    this.medecins = const [],
  });

  ConsentState copyWith({
    bool? isLoading,
    String? message,
    List<MedecinConsentModel>? medecins,
  }) {
    return ConsentState(
      isLoading: isLoading ?? this.isLoading,
      message: message,
      medecins: medecins ?? this.medecins,
    );
  }

  /// Vérifie si un médecin spécifique dispose des autorisations actives
  bool verifierAccesMedecin(String medecinIdOrName) {
    if (medecins.isEmpty) return true;
    final query = medecinIdOrName.trim().toLowerCase();
    for (final m in medecins) {
      if (m.id.toLowerCase() == query ||
          m.nom.toLowerCase() == query ||
          m.nom.toLowerCase().contains(query) ||
          query.contains(m.nom.toLowerCase())) {
        return m.estAutorise;
      }
    }
    return true;
  }

  /// Retrouve la fiche de consentement d'un médecin
  MedecinConsentModel? trouverMedecin(String medecinIdOrName) {
    final query = medecinIdOrName.trim().toLowerCase();
    for (final m in medecins) {
      if (m.id.toLowerCase() == query ||
          m.nom.toLowerCase() == query ||
          m.nom.toLowerCase().contains(query) ||
          query.contains(m.nom.toLowerCase())) {
        return m;
      }
    }
    return null;
  }
}

class ConsentNotifier extends StateNotifier<ConsentState> {
  ConsentNotifier()
      : super(ConsentState(
          medecins: [
            MedecinConsentModel(
              id: 'med-cheikh-fall',
              nom: 'Dr. Cheikh Fall',
              specialite: 'Cardiologie & Médecine Interne',
              hopital: 'Hôpital Principal de Dakar',
              telephone: '+221 77 555 12 34',
              estAutorise: true,
              dateModification: DateTime.now().subtract(const Duration(days: 10)),
              motif: 'Médecin traitant cardiologue',
            ),
            MedecinConsentModel(
              id: 'med-aissatou-diop',
              nom: 'Dr. Aïssatou Diop',
              specialite: 'Médecine Générale & Téléconsultation',
              hopital: 'Clinique Diam-Yaraam Plateau',
              telephone: '+221 77 444 56 78',
              estAutorise: false, // Révoqué pour la démonstration
              dateModification: DateTime.now().subtract(const Duration(days: 2)),
              motif: 'Accès révoqué par le patient suite à fin de traitement',
            ),
            MedecinConsentModel(
              id: 'med-ousmane-sow',
              nom: 'Dr. Ousmane Sow',
              specialite: 'Urgentiste SAMU 15',
              hopital: 'SAMU National Sénégal',
              telephone: '+221 77 333 99 00',
              estAutorise: true,
              dateModification: DateTime.now().subtract(const Duration(days: 30)),
              motif: 'Prise en charge d\'urgence autorisée',
            ),
            MedecinConsentModel(
              id: 'med-mamadou-ba',
              nom: 'Dr. Mamadou Ba',
              specialite: 'Pneumologie & Allergologie',
              hopital: 'Hôpital Fann',
              telephone: '+221 78 222 11 44',
              estAutorise: true,
              dateModification: DateTime.now().subtract(const Duration(days: 15)),
              motif: 'Suivi respiratoire et asthme',
            ),
          ],
        ));

  /// Révoquer l'accès d'un médecin
  void revoquerAcces(String medecinId) {
    state = state.copyWith(
      medecins: state.medecins.map((m) {
        if (m.id == medecinId) {
          return m.copyWith(
            estAutorise: false,
            dateModification: DateTime.now(),
            motif: 'Accès révoqué par le patient',
          );
        }
        return m;
      }).toList(),
      message: 'Accès au dossier médical révoqué avec succès.',
    );
  }

  /// Accorder ou rétablir l'accès d'un médecin
  void accorderAcces(String medecinId) {
    state = state.copyWith(
      medecins: state.medecins.map((m) {
        if (m.id == medecinId) {
          return m.copyWith(
            estAutorise: true,
            dateModification: DateTime.now(),
            motif: 'Accès accordé par le patient',
          );
        }
        return m;
      }).toList(),
      message: 'Accès au dossier médical accordé au praticien.',
    );
  }

  /// Basculer l'état d'accès d'un médecin
  void toggleAcces(String medecinId) {
    final med = state.medecins.firstWhere(
      (m) => m.id == medecinId,
      orElse: () => MedecinConsentModel(
        id: medecinId,
        nom: 'Dr. Praticien',
        specialite: 'Médecine Générale',
        hopital: 'Cabinet Diam-Yaraam',
        telephone: '+221 77 000 00 00',
        estAutorise: false,
        dateModification: DateTime.now(),
      ),
    );

    if (med.estAutorise) {
      revoquerAcces(medecinId);
    } else {
      accorderAcces(medecinId);
    }
  }

  /// Vérifier si un médecin a l'autorisation d'accès au dossier médical complet
  bool verifierAccesMedecin(String? medecinId, {String? patientId}) {
    if (medecinId == null || medecinId.isEmpty) return false;
    final match = state.medecins.where(
      (m) => m.id.toLowerCase() == medecinId.toLowerCase() ||
          m.nom.toLowerCase().contains(medecinId.toLowerCase()),
    );
    if (match.isNotEmpty) {
      return match.first.estAutorise;
    }
    // Par défaut pour un praticien inconnu : non accordé sans consentement préalable
    return false;
  }

  /// Ajouter ou autoriser un nouveau praticien
  void ajouterMedecin(MedecinConsentModel medecin) {
    final list = List<MedecinConsentModel>.from(state.medecins);
    final idx = list.indexWhere((m) => m.id == medecin.id || m.nom.toLowerCase() == medecin.nom.toLowerCase());
    if (idx != -1) {
      list[idx] = medecin.copyWith(estAutorise: true);
    } else {
      list.insert(0, medecin);
    }
    state = state.copyWith(
      medecins: list,
      message: 'Praticien ${medecin.nom} ajouté aux autorisations.',
    );
  }

  /// Envoyer une demande d'accès au patient
  Future<bool> demanderAcces({required String medecinNom, required String patientNom}) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      isLoading: false,
      message: 'Demande d\'accès envoyée au patient $patientNom.',
    );
    return true;
  }
}

final consentProvider = StateNotifierProvider<ConsentNotifier, ConsentState>((ref) {
  return ConsentNotifier();
});
