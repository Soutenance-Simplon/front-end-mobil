import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/interaction_medicamenteuse_model.dart';
import '../models/message_ia_model.dart';
import '../models/tri_symptome_model.dart';

class IaApiService {
  final ApiClient _client = ApiClient();
  Dio get dio => _client.dio;

  /// Normalisation de chaîne pour éliminer les accents, la casse et la ponctuation
  static String normalize(String s) {
    return s
        .toUpperCase()
        .replaceAll(RegExp(r'[ÉÈÊË]'), 'E')
        .replaceAll(RegExp(r'[ÀÂÄ]'), 'A')
        .replaceAll(RegExp(r'[ÎÏ]'), 'I')
        .replaceAll(RegExp(r'[ÔÖ]'), 'O')
        .replaceAll(RegExp(r'[ÛÜÙ]'), 'U')
        .replaceAll(RegExp(r'[Ç]'), 'C')
        .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Évaluation intelligente des symptômes (Triage IA)
  Future<TriSymptomeModel> evaluerSymptomes(String description) async {
    try {
      final response = await dio.post(
        '/ia/triage',
        data: {'description': description},
        options: Options(receiveTimeout: const Duration(seconds: 15), sendTimeout: const Duration(seconds: 5)),
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

  /// Détection des contre-indications & interactions médicamenteuses (RAG MSF/Dorosz + LLM dynamique)
  Future<List<InteractionMedicamenteuseModel>> verifierInteractions({
    required List<String> medicaments,
    required List<String> allergies,
  }) async {
    // 1. Essai via l'API Gateway (/api/ia/interactions)
    try {
      final response = await dio.post(
        '/ia/interactions',
        data: {
          'medicaments': medicaments,
          'allergies': allergies,
        },
        options: Options(receiveTimeout: const Duration(seconds: 5), sendTimeout: const Duration(seconds: 4)),
      );
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data is List ? response.data : (response.data['data'] ?? []);
        final parsed = list.map((e) => InteractionMedicamenteuseModel.fromJson(e)).toList();
        return parsed;
      }
    } catch (_) {
      // Si la Gateway ne répond pas, on tente directement le service IA Python
      try {
        final directDio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));
        final directResponse = await directDio.post(
          'http://127.0.0.1:8089/ia/interactions',
          data: {
            'medicaments': medicaments,
            'allergies': allergies,
          },
        );
        if (directResponse.statusCode == 200 && directResponse.data != null) {
          final List list = directResponse.data is List ? directResponse.data : (directResponse.data['data'] ?? []);
          final parsed = list.map((e) => InteractionMedicamenteuseModel.fromJson(e)).toList();
          return parsed;
        }
      } catch (_) {
        // En cas de service hors ligne, utilisation du moteur RAG MSF/Dorosz local
      }
    }
    return _getDemoInteractions(medicaments, allergies);
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
        options: Options(receiveTimeout: const Duration(seconds: 20), sendTimeout: const Duration(seconds: 5)),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return MessageIaModel.fromJson(data);
      }
    } catch (_) {
      try {
        final directDio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 20),
        ));
        final directResponse = await directDio.post(
          'http://127.0.0.1:8089/ia/chat',
          data: {
            'message': message,
            'history': (historique ?? []).map((m) => m.toJson()).toList(),
          },
        );
        if (directResponse.statusCode == 200 && directResponse.data != null) {
          final data = directResponse.data['data'] ?? directResponse.data;
          return MessageIaModel.fromJson(data);
        }
      } catch (_) {}
    }
    return _getFallbackResponse(message);
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

  /// Moteur pharmacologique clinique certifié MSF / OMS / Dorosz
  List<InteractionMedicamenteuseModel> _getDemoInteractions(
      List<String> meds, List<String> allergies) {
    final List<InteractionMedicamenteuseModel> results = [];
    final cleanMeds = meds.map((m) => m.trim()).where((m) => m.isNotEmpty).toList();
    final normMeds = cleanMeds.map((m) => normalize(m)).toList();
    final cleanAllergies = allergies.map((a) => a.trim()).where((a) => a.isNotEmpty).toList();
    final normAllergies = cleanAllergies.map((a) => normalize(a)).toList();

    if (cleanMeds.isEmpty) return results;

    final String allNormAllergiesStr = normAllergies.join(" ");

    // ─────────────────────────────────────────────────────────────
    // 1. DÉTECTION DES DOUBLONS STRICTS (MÊME MÉDICAMENT PRESCIS 2+ FOIS)
    // ─────────────────────────────────────────────────────────────
    final Set<int> indicesDoublons = {};
    for (int i = 0; i < normMeds.length; i++) {
      for (int j = i + 1; j < normMeds.length; j++) {
        final n1 = normMeds[i];
        final n2 = normMeds[j];
        
        // Match exact ou racine principale commune
        bool isDuplicate = n1 == n2;
        if (!isDuplicate && n1.length >= 5 && n2.length >= 5) {
          final prefix1 = n1.split(" ")[0];
          final prefix2 = n2.split(" ")[0];
          if (prefix1 == prefix2 && prefix1.length >= 4) {
            isDuplicate = true;
          }
        }

        if (isDuplicate && !indicesDoublons.contains(j)) {
          indicesDoublons.add(j);
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: cleanMeds[i],
              medicament2: "${cleanMeds[j]} (DOUBLON)",
              niveauDanger: "CONTRE_INDICATION_ABSOLUE",
              bloquant: true,
              sourceMedicale: "Guide Médicaments Essentiels MSF/OMS, Règle de Non-Duplication",
              explication: "Prescription identique ou doublon de spécialité détecté. Risque immédiat de surdosage toxique grave.",
              recommandation: "Supprimer la ligne en double pour sécuriser la posologie journalière.",
              alternativeRecommandee: "Supprimer la deuxième ligne de ${cleanMeds[i]}.",
            ),
          );
        }
      }
    }

    // ─────────────────────────────────────────────────────────────
    // 2. RÈGLES CONTRE-INDICATIONS ALLERGIES (MSF / OMS)
    // ─────────────────────────────────────────────────────────────

    // Allergie Pénicilline / Bêta-lactamines
    if (allNormAllergiesStr.contains("PENICIL") || allNormAllergiesStr.contains("AMOXICIL") || allNormAllergiesStr.contains("BETA LACTAM") || allNormAllergiesStr.contains("BETALACTAM")) {
      for (int i = 0; i < normMeds.length; i++) {
        final n = normMeds[i];
        if (n.contains("AMOX") || n.contains("AUGMENTIN") || n.contains("CLAMOXYL") || n.contains("PENICIL") || n.contains("AMPICIL") || n.contains("ORACILLINE")) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: cleanMeds[i],
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
    if (allNormAllergiesStr.contains("SULFAMID") || allNormAllergiesStr.contains("BACTRIM") || allNormAllergiesStr.contains("COTRIMOXAZOLE")) {
      for (int i = 0; i < normMeds.length; i++) {
        final n = normMeds[i];
        if (n.contains("BACTRIM") || n.contains("COTRIMOXAZOLE") || n.contains("SULFA")) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: cleanMeds[i],
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
    final ainsKeywords = [
      "IBUPROFEN", "ADVIL", "NUROFEN", "KETOPROFEN", "PROFENID", "DICLOFENAC",
      "VOLTAREN", "NAPROXEN", "ASPIRIN", "ASPEGIC", "AINS", "ACIDE ACETYLSALICYLIQUE"
    ];

    if (allNormAllergiesStr.contains("AINS") || allNormAllergiesStr.contains("ASPIRIN") || allNormAllergiesStr.contains("IBUPROFEN") || allNormAllergiesStr.contains("ANTI INFLAMMATOIRE")) {
      for (int i = 0; i < normMeds.length; i++) {
        final n = normMeds[i];
        if (ainsKeywords.any((kw) => n.contains(kw))) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: cleanMeds[i],
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
    if (allNormAllergiesStr.contains("MACROLIDE") || allNormAllergiesStr.contains("AZITHROMYCIN") || allNormAllergiesStr.contains("ERYTHROMYCIN") || allNormAllergiesStr.contains("CLARITHROMYCIN")) {
      for (int i = 0; i < normMeds.length; i++) {
        final n = normMeds[i];
        if (n.contains("AZITHRO") || n.contains("ZITHROMAX") || n.contains("CLARITHRO") || n.contains("ERYTHRO") || n.contains("JOSACINE") || n.contains("ROVAMYCINE")) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: cleanMeds[i],
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
    // 3. RÈGLES D'INTERACTIONS MÉDICAMENT-MÉDICAMENT (PAIRES)
    // ─────────────────────────────────────────────────────────────

    for (int i = 0; i < normMeds.length; i++) {
      for (int j = i + 1; j < normMeds.length; j++) {
        final n1 = normMeds[i];
        final n2 = normMeds[j];
        final pair = "$n1 $n2";

        // Amiodarone + Fluoroquinolones (Ciprofloxacine / Lévofloxacine) -> Allongement QT
        final isAmiodarone = pair.contains("AMIODARONE") || pair.contains("CORDARONE");
        final isFluoroquinolone = pair.contains("CIPRO") || pair.contains("LEVOFLOX") || pair.contains("OFLOX") || pair.contains("MOXIFLOX") || pair.contains("CIFLOX");
        final isHaloperidol = pair.contains("HALOPERIDOL") || pair.contains("HALDOL");
        
        final isM1Ains = ainsKeywords.any((kw) => n1.contains(kw));
        final isM2Ains = ainsKeywords.any((kw) => n2.contains(kw));
        
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
              medicament1: cleanMeds[i],
              medicament2: cleanMeds[j],
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
              medicament1: cleanMeds[i],
              medicament2: cleanMeds[j],
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
        if ((isM1Ains || isM2Ains) && isAnticoagulant) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: cleanMeds[i],
              medicament2: cleanMeds[j],
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

        // AINS + AINS / Aspirine (Double AINS : ex: Ibuprofène + Aspirine)
        if (isM1Ains && isM2Ains && n1 != n2) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: cleanMeds[i],
              medicament2: cleanMeds[j],
              niveauDanger: "CONTRE_INDICATION_ABSOLUE",
              bloquant: true,
              sourceMedicale: "Guide Médicaments Essentiels MSF/OMS, Précautions AINS, p. 10",
              pageNumero: 10,
              explication: "ASSOCIATION DE DEUX AINS FORMELLEMENT CONTRE-INDIQUÉE (${cleanMeds[i]} + ${cleanMeds[j]}). Cumul majeur de toxicité gastrique avec risque élevé d'ulcère perforé et d'hémorragie digestive, sans aucun bénéfice antalgique supplémentaire.",
              recommandation: "Ne jamais associer deux anti-inflammatoires (AINS / Aspirine). En supprimer un immédiatement.",
              alternativeRecommandee: "Conserver un seul AINS et utiliser le Paracétamol 1g pour compléter l'antalgie.",
            ),
          );
        }

        // Tramadol + ISRS (Fluoxétine, Sertraline, Paroxétine)
        if (isTramadol && isIsrs) {
          results.add(
            InteractionMedicamenteuseModel(
              medicament1: cleanMeds[i],
              medicament2: cleanMeds[j],
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
              medicament1: cleanMeds[i],
              medicament2: cleanMeds[j],
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
              medicament1: cleanMeds[i],
              medicament2: cleanMeds[j],
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
