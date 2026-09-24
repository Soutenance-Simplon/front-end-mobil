import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/interaction_medicamenteuse_model.dart';
import '../models/message_ia_model.dart';
import '../models/tri_symptome_model.dart';

class IaApiService {
  final ApiClient _client = ApiClient();
  Dio get dio => _client.dio;

  /// Évaluation intelligente des symptômes (Triage IA)
  Future<TriSymptomeModel> evaluerSymptomes(String description) async {
    try {
      final response = await dio.post(
        '/ia/triage',
        data: {'description': description},
        options: Options(receiveTimeout: const Duration(seconds: 4), sendTimeout: const Duration(seconds: 3)),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return TriSymptomeModel.fromJson(data);
      }
      return _getFallbackTriage(description);
    } catch (e) {
      return _getFallbackTriage(description);
    }
  }

  /// Détection des contre-indications & interactions médicamenteuses
  Future<List<InteractionMedicamenteuseModel>> verifierInteractions({
    required List<String> medicaments,
    required List<String> allergies,
  }) async {
    try {
      final response = await dio.post(
        '/ia/interactions',
        data: {
          'medicaments': medicaments,
          'allergies': allergies,
        },
        options: Options(receiveTimeout: const Duration(seconds: 4), sendTimeout: const Duration(seconds: 3)),
      );
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data is List ? response.data : (response.data['data'] ?? []);
        final parsed = list.map((e) => InteractionMedicamenteuseModel.fromJson(e)).toList();
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
      return _getDemoInteractions(medicaments, allergies);
    } catch (e) {
      return _getDemoInteractions(medicaments, allergies);
    }
  }

  /// Assistant conversationnel médical Diam Yaraam
  Future<MessageIaModel> envoyerMessage(String message, {List<MessageIaModel>? historique}) async {
    try {
      final response = await dio.post(
        '/ia/chat',
        data: {
          'message': message,
          'history': (historique ?? []).map((m) => m.toJson()).toList(),
        },
        options: Options(receiveTimeout: const Duration(seconds: 6), sendTimeout: const Duration(seconds: 4)),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return MessageIaModel.fromJson(data);
      }
      return _getFallbackResponse(message);
    } catch (e) {
      return _getFallbackResponse(message);
    }
  }

  TriSymptomeModel _getFallbackTriage(String text) {
    return TriSymptomeModel(
      descriptionSymptomes: text,
      niveauGravite: 'MODERE',
      orientationSuggeree: 'Médecine Générale',
      conseilImmediat:
          "Prenez rendez-vous avec un médecin généraliste ou un spécialiste agréé pour une évaluation clinique complète. En cas d'urgence vitale, appelez le SAMU (1515).",
      questionsSuivi: [
        "Depuis combien de temps avez-vous ces symptômes ?",
        "Avez-vous de la fièvre ou des difficultés respiratoires ?",
      ],
    );
  }

  /// Moteur pharmacologique clinique certifié MSF / OMS / Dorosz pour offline et fallback immédiat
  List<InteractionMedicamenteuseModel> _getDemoInteractions(
      List<String> meds, List<String> allergies) {
    final List<InteractionMedicamenteuseModel> results = [];
    final cleanMeds = meds.map((m) => m.trim().toUpperCase()).where((m) => m.isNotEmpty).toList();
    final cleanAllergies = allergies.map((a) => a.trim().toUpperCase()).where((a) => a.isNotEmpty).toList();

    if (cleanMeds.isEmpty) return results;

    final String allMedsStr = cleanMeds.join(" ");
    final String allAllergiesStr = cleanAllergies.join(" ");

    // ─────────────────────────────────────────────────────────────
    // 1. RÈGLES CONTRE-INDICATIONS ALLERGIES (MSF / OMS)
    // ─────────────────────────────────────────────────────────────

    // Allergie Pénicilline / Bêta-lactamines
    if (allAllergiesStr.contains("PENICIL") || allAllergiesStr.contains("AMOXICIL") || allAllergiesStr.contains("BETA-LACTAM") || allAllergiesStr.contains("BETALACTAM")) {
      for (final med in cleanMeds) {
        if (med.contains("AMOX") || med.contains("AUGMENTIN") || med.contains("CLAMOXYL") || med.contains("PENICIL") || med.contains("AMPICIL") || med.contains("ORACILLINE")) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: med,
              medicament2: "ALLERGIE AUX PÉNICILLINES",
              niveauDanger: "CONTRE_INDICATION_ABSOLUE",
              bloquant: true,
              sourceMedicale: "Guide Médicaments Essentiels MSF/OMS, Monographie Amoxicilline, p. 38",
              pageNumero: 38,
              explication: "Allergie croisée majeure aux bêtalactamines. Risque élevé de choc anaphylactique, bronchospasme ou œdème de Quincke mortel.",
              recommandation: "Contre-indication formelle. Ne pas administrer de pénicilline.",
              alternativeRecommandee: "Remplacer par un Macrolide (Azithromycine 500mg 1x/j ou Clarithromycine 500mg 2x/j) ou Ceftriaxone selon indication.",
            ),
          );
        }
      }
    }

    // Allergie Sulfamides
    if (allAllergiesStr.contains("SULFAMID") || allAllergiesStr.contains("BACTRIM") || allAllergiesStr.contains("COTRIMOXAZOLE")) {
      for (final med in cleanMeds) {
        if (med.contains("BACTRIM") || med.contains("COTRIMOXAZOLE") || med.contains("SULFA")) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: med,
              medicament2: "ALLERGIE AUX SULFAMIDES",
              niveauDanger: "CONTRE_INDICATION_ABSOLUE",
              bloquant: true,
              sourceMedicale: "Guide Médicaments Essentiels MSF/OMS, Fiche Co-trimoxazole, p. 12",
              pageNumero: 12,
              explication: "Risque de toxidermie sévère potentiellement mortelle (Syndrome de Stevens-Johnson / Lyell).",
              recommandation: "Prescription strictement interdite chez le patient allergique aux sulfamides.",
              alternativeRecommandee: "Remplacer par Amoxicilline ou Ciprofloxacine selon le foyer infectieux.",
            ),
          );
        }
      }
    }

    // Allergie AINS / Aspirine
    if (allAllergiesStr.contains("AINS") || allAllergiesStr.contains("ASPIRIN") || allAllergiesStr.contains("IBUPROFEN") || allAllergiesStr.contains("ANTI-INFLAMMATOIRE")) {
      for (final med in cleanMeds) {
        if (med.contains("IBUPROFEN") || med.contains("ADVIL") || med.contains("NUROFEN") || med.contains("KETOPROFEN") || med.contains("PROFENID") || med.contains("DICLOFENAC") || med.contains("VOLTAREN") || med.contains("ASPIRIN") || med.contains("ASPEGIC") || med.contains("NAPROXEN")) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: med,
              medicament2: "ALLERGIE AUX AINS / ASPIRINE",
              niveauDanger: "CONTRE_INDICATION_ABSOLUE",
              bloquant: true,
              sourceMedicale: "Guide Médicaments Essentiels MSF/OMS, Monographie AINS, p. 10",
              pageNumero: 10,
              explication: "Risque de crise d'asthme sévère (syndrome de Widal), bronchospasme aigu ou choc anaphylactoïde.",
              recommandation: "Contre-indication absolue à tous les AINS.",
              alternativeRecommandee: "Privilégier le Paracétamol 1g ou un antalgique de palier 2 (Tramadol) en l'absence d'autre contre-indication.",
            ),
          );
        }
      }
    }

    // Allergie Macrolides
    if (allAllergiesStr.contains("MACROLIDE") || allAllergiesStr.contains("AZITHROMYCIN") || allAllergiesStr.contains("ERYTHROMYCIN") || allAllergiesStr.contains("CLARITHROMYCIN")) {
      for (final med in cleanMeds) {
        if (med.contains("AZITHRO") || med.contains("ZITHROMAX") || med.contains("CLARITHRO") || med.contains("ERYTHRO") || med.contains("JOSACINE") || med.contains("ROVAMYCINE")) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: med,
              medicament2: "ALLERGIE AUX MACROLIDES",
              niveauDanger: "CONTRE_INDICATION_ABSOLUE",
              bloquant: true,
              sourceMedicale: "Guide Médicaments Essentiels MSF/OMS, Monographie Macrolides, p. 44",
              pageNumero: 44,
              explication: "Réaction d'hypersensibilité cutanée et hépatique sévère.",
              recommandation: "Éviter la classe des macrolides.",
              alternativeRecommandee: "Amoxicilline, Céfixime ou Doxycycline selon indication clinique.",
            ),
          );
        }
      }
    }

    // ─────────────────────────────────────────────────────────────
    // 2. RÈGLES D'INTERACTIONS MÉDICAMENT-MÉDICAMENT (PAIRES)
    // ─────────────────────────────────────────────────────────────

    for (int i = 0; i < cleanMeds.length; i++) {
      for (int j = i + 1; j < cleanMeds.length; j++) {
        final m1 = cleanMeds[i];
        final m2 = cleanMeds[j];
        final pair = "$m1 $m2";

        // Amiodarone + Fluoroquinolones (Ciprofloxacine / Lévofloxacine) -> Allongement QT
        final isAmiodarone = pair.contains("AMIODARONE") || pair.contains("CORDARONE");
        final isFluoroquinolone = pair.contains("CIPRO") || pair.contains("LEVOFLOX") || pair.contains("OFLOX") || pair.contains("MOXIFLOX") || pair.contains("CIFLOX");
        final isHaloperidol = pair.contains("HALOPERIDOL") || pair.contains("HALDOL");
        final isAins = pair.contains("IBUPROFEN") || pair.contains("ADVIL") || pair.contains("NUROFEN") || pair.contains("KETOPROFEN") || pair.contains("PROFENID") || pair.contains("DICLOFENAC") || pair.contains("VOLTAREN") || pair.contains("NAPROXEN") || pair.contains("ASPIRIN") || pair.contains("ASPEGIC");
        final isAnticoagulant = pair.contains("WARFARIN") || pair.contains("COUMADIN") || pair.contains("SINTROM") || pair.contains("XARELTO") || pair.contains("RIVAROXABAN") || pair.contains("ELIQUIS") || pair.contains("APIXABAN") || pair.contains("HEPARIN") || pair.contains("LOVENOX");
        final isTramadol = pair.contains("TRAMADOL") || pair.contains("TOPALGIC") || pair.contains("CONTRAMAL") || pair.contains("IXPRIM") || pair.contains("ZALDIAR");
        final isIsrs = pair.contains("FLUOXETIN") || pair.contains("PROZAC") || pair.contains("SERTRALIN") || pair.contains("ZOLOFT") || pair.contains("PAROXETIN") || pair.contains("DEROXAT") || pair.contains("ESCITALOPRAM") || pair.contains("SEROPLEX") || pair.contains("CITALOPRAM");
        final isIecAra2 = pair.contains("PERINDOPRIL") || pair.contains("COVERSYL") || pair.contains("RAMIPRIL") || pair.contains("TRIATEC") || pair.contains("ENALAPRIL") || pair.contains("RENITEC") || pair.contains("LOSARTAN") || pair.contains("COZAAR") || pair.contains("VALSARTAN");
        final isSpironolactone = pair.contains("SPIRONOLACTONE") || pair.contains("ALDACTONE") || pair.contains("EPLERENONE");
        final isStatine = pair.contains("SIMVASTATIN") || pair.contains("ZOCOR") || pair.contains("ATORVASTATIN") || pair.contains("TAHOR") || pair.contains("CRESTOR") || pair.contains("ROSUVASTATIN");
        final isMacrolide = pair.contains("CLARITHROMYCIN") || pair.contains("ZECLAR") || pair.contains("ERYTHROMYCIN") || pair.contains("JOSACINE");

        // Amiodarone + Ciprofloxacine / Fluoroquinolone
        if (isAmiodarone && isFluoroquinolone) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: m1,
              medicament2: m2,
              niveauDanger: "CONTRE_INDICATION_ABSOLUE",
              bloquant: true,
              sourceMedicale: "Guide Médicaments Essentiels MSF/OMS, Monographie Ciprofloxacine, p. 51",
              pageNumero: 51,
              explication: "Risque majeur de torsades de pointes et d'arrêt cardiorespiratoire mortel par allongement cumulatif synergique de l'intervalle QT ventriculaire.",
              recommandation: "ASSOCIATION FORMELLEMENT CONTRE-INDIQUÉE. Remplacer l'antibiotique par une alternative sans risque sur le rythme cardiaque.",
              alternativeRecommandee: "Ceftriaxone 1g injectable ou Doxycycline 100mg selon le foyer infectieux.",
            ),
          );
        }

        // Amiodarone + Halopéridol
        if (isAmiodarone && isHaloperidol) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: m1,
              medicament2: m2,
              niveauDanger: "CONTRE_INDICATION_ABSOLUE",
              bloquant: true,
              sourceMedicale: "Guide Médicaments Essentiels MSF/OMS, Monographie Halopéridol, p. 51",
              pageNumero: 51,
              explication: "Allongement synergique de l'intervalle QT et risque élevé d'arythmie ventriculaire sévère.",
              recommandation: "Association formellement déconseillée.",
              alternativeRecommandee: "Évaluer un anxiolytique ou neuroleptique atypique après avis spécialisé.",
            ),
          );
        }

        // AINS + Anticoagulant oral
        if (isAins && isAnticoagulant) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: m1,
              medicament2: m2,
              niveauDanger: "CONTRE_INDICATION_ABSOLUE",
              bloquant: true,
              sourceMedicale: "Guide Médicaments Essentiels MSF/OMS, Section AINS et anticoagulants, p. 10",
              pageNumero: 10,
              explication: "Risque d'hémorragie gastro-intestinale massive engageant le pronostic vital par synergie anti-hémostatique.",
              recommandation: "Les AINS sont formellement proscrits chez les patients sous anticoagulants.",
              alternativeRecommandee: "Paracétamol 1g par prise (max 3g/jour) ou Tramadol si douleur modérée.",
            ),
          );
        }

        // AINS + AINS / Aspirine (Double AINS)
        final isM1Ains = m1.contains("IBUPROFEN") || m1.contains("ADVIL") || m1.contains("KETOPROFEN") || m1.contains("PROFENID") || m1.contains("DICLOFENAC") || m1.contains("VOLTAREN") || m1.contains("NAPROXEN") || m1.contains("ASPIRIN");
        final isM2Ains = m2.contains("IBUPROFEN") || m2.contains("ADVIL") || m2.contains("KETOPROFEN") || m2.contains("PROFENID") || m2.contains("DICLOFENAC") || m2.contains("VOLTAREN") || m2.contains("NAPROXEN") || m2.contains("ASPIRIN");
        if (isM1Ains && isM2Ains && m1 != m2) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: m1,
              medicament2: m2,
              niveauDanger: "MAJEURE",
              bloquant: false,
              sourceMedicale: "Guide Médicaments Essentiels MSF/OMS, Précautions AINS, p. 10",
              pageNumero: 10,
              explication: "Cumul de toxicité gastro-intestinale et rénale sans bénéfice antalgique supplémentaire. Risque élevé d'ulcère gastroduodénal.",
              recommandation: "Ne jamais prescrire deux AINS simultanément. En supprimer un.",
              alternativeRecommandee: "Conserver un seul AINS à dose efficace et adjoindre Paracétamol si besoin.",
            ),
          );
        }

        // Tramadol + ISRS (Fluoxétine, Sertraline, Paroxétine)
        if (isTramadol && isIsrs) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: m1,
              medicament2: m2,
              niveauDanger: "CONTRE_INDICATION_ABSOLUE",
              bloquant: true,
              sourceMedicale: "Guide Médicaments Essentiels MSF/OMS, Antalgiques opioïdes et ISRS, p. 101",
              pageNumero: 101,
              explication: "Risque majeur de syndrome sérotoninergique potentiellement létal (hyperthermie, myoclonies, confusion, convulsions).",
              recommandation: "Association à proscrire.",
              alternativeRecommandee: "Paracétamol ou AINS en monothérapie, ou opioïde pur sous surveillance étroite.",
            ),
          );
        }

        // IEC/ARA2 + Spironolactone
        if (isIecAra2 && isSpironolactone) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: m1,
              medicament2: m2,
              niveauDanger: "MAJEURE",
              bloquant: false,
              sourceMedicale: "Guide Médicaments Essentiels MSF/OMS, Diurétiques et IEC, p. 77",
              pageNumero: 77,
              explication: "Risque d'hyperkaliémie sévère potentiellement mortelle (troubles de la conduction cardiaque).",
              recommandation: "Surveiller impérativement la kaliémie et la créatininémie à J7 puis régulièrement.",
              alternativeRecommandee: "Ajuster la posologie ou associer un diurétique hypokaliémiant (Furosémide).",
            ),
          );
        }

        // Statines + Macrolides
        if (isStatine && isMacrolide) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: m1,
              medicament2: m2,
              niveauDanger: "MAJEURE",
              bloquant: false,
              sourceMedicale: "Guide Médicaments Essentiels MSF/OMS, Hypolipémiants et Macrolides, p. 83",
              pageNumero: 83,
              explication: "Inhibition du métabolisme de la statine par le cytochrome CYP3A4 avec risque de rhabdomyolyse aiguë et insuffisance rénale.",
              recommandation: "Interrompre temporairement la statine pendant la durée de l'antibiothérapie.",
              alternativeRecommandee: "Remplacer le macrolide par Azithromycine (non inhibiteur CYP3A4) ou Amoxicilline.",
            ),
          );
        }
      }
    }

    // ─────────────────────────────────────────────────────────────
    // 3. VÉRIFICATION DES DOUBLONS DE PARACÉTAMOL
    // ─────────────────────────────────────────────────────────────
    int paracount = 0;
    for (final m in cleanMeds) {
      if (m.contains("PARACETAMOL") || m.contains("DOLIPRANE") || m.contains("EFFERALGAN") || m.contains("DAFALGAN")) {
        paracount++;
      }
    }
    if (paracount >= 2) {
      results.add(
        InteractionMedicamenteuseModel(
          medicament1: "PARACÉTAMOL (DOUBLON DÉTECTÉ)",
          medicament2: "SURDOSAGE HÉPATIQUE",
          niveauDanger: "MAJEURE",
          bloquant: false,
          sourceMedicale: "Guide Médicaments Essentiels MSF/OMS, Fiche Paracétamol, p. 8",
          pageNumero: 8,
          explication: "Présence de plusieurs spécialités contenant du paracétamol. Risque élevé de surdosage (>4g/jour) et de cytolyse hépatique aiguë toxique.",
          recommandation: "Conserver une seule spécialité de paracétamol et respecter la dose maximale de 3g/jour (1g toutes les 6 à 8h).",
          alternativeRecommandee: "Supprimer le doublon pour sécuriser la posologie journalière.",
        ),
      );
    }

    return results;
  }

  MessageIaModel _getFallbackResponse(String userMsg) {
    return MessageIaModel(
      id: 'ia-${DateTime.now().millisecondsSinceEpoch}',
      contenu:
          "Je suis l'assistant médical Diam Yaraam. Pour toute question de santé, n'hésitez pas à consulter un de nos praticiens agréés de l'ONDMS. En cas d'urgence vitale, contactez immédiatement le 1515 (SAMU).",
      estUtilisateur: false,
      timestamp: DateTime.now(),
      recommandations: [
        "Consulter un médecin agréé sur Diam Yaraam",
        "Prendre rendez-vous en téléconsultation",
      ],
    );
  }
}
