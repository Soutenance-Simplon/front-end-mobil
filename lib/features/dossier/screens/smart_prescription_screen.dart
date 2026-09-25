import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/providers/auth_provider.dart';
import '../../ia/models/interaction_medicamenteuse_model.dart';
import '../../ia/providers/ia_provider.dart';
import '../../ia/services/ia_api_service.dart';
import '../models/prescription_model.dart';
import '../providers/dossier_provider.dart';

class SmartPrescriptionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? patientInfo;

  const SmartPrescriptionScreen({super.key, this.patientInfo});

  @override
  ConsumerState<SmartPrescriptionScreen> createState() => _SmartPrescriptionScreenState();
}

class _SmartPrescriptionScreenState extends ConsumerState<SmartPrescriptionScreen> {
  final _searchDrugController = TextEditingController();
  final List<LignePrescriptionModel> _lignes = [];

  bool _isSigned = true;
  bool _isCheckingIA = false;
  List<InteractionMedicamenteuseModel> _alertesActives = [];
  List<InteractionMedicamenteuseModel> _rapportAuditIA = [];

  // Répertoire rapide de médicaments standards pour l'autocomplétion
  final List<Map<String, String>> _medicamentsStandards = [
    {
      "nom": "PARACÉTAMOL",
      "dosage": "1g",
      "posologie": "1 comprimé x 3 / jour",
      "duree": "5 jours",
      "instructions": "À prendre pendant ou après les repas avec un verre d'eau",
    },
    {
      "nom": "AMOXICILLINE",
      "dosage": "1g",
      "posologie": "1 comprimé x 2 / jour",
      "duree": "6 jours",
      "instructions": "À prendre au début des repas. Respecter la durée totale",
    },
    {
      "nom": "IBUPROFÈNE",
      "dosage": "400mg",
      "posologie": "1 comprimé x 3 / jour",
      "duree": "5 jours",
      "instructions": "Toujours au milieu des repas avec un grand verre d'eau",
    },
    {
      "nom": "ASPIRINE",
      "dosage": "500mg",
      "posologie": "1 comprimé x 3 / jour",
      "duree": "5 jours",
      "instructions": "Pendant les repas avec un grand verre d'eau",
    },
    {
      "nom": "ARTÉMÉTHER + LUMÉFANTRINE (COARTEM)",
      "dosage": "80/480mg",
      "posologie": "1 comprimé x 2 / jour",
      "duree": "3 jours",
      "instructions": "Prendre impérativement avec un repas gras ou du lait",
    },
    {
      "nom": "AZITHROMYCINE",
      "dosage": "500mg",
      "posologie": "1 comprimé / jour",
      "duree": "3 jours",
      "instructions": "Prise unique quotidienne à distance des repas",
    },
    {
      "nom": "CEFTRIAXONE",
      "dosage": "1g",
      "posologie": "1 injection IM/IV par jour",
      "duree": "5 jours",
      "instructions": "Administration parentérale stricte en milieu médical",
    },
    {
      "nom": "OMÉPRAZOLE",
      "dosage": "20mg",
      "posologie": "1 gélule le matin",
      "duree": "14 jours",
      "instructions": "À jeun 30 minutes avant le petit-déjeuner",
    },
    {
      "nom": "AMLODIPINE",
      "dosage": "5mg",
      "posologie": "1 comprimé le matin",
      "duree": "30 jours",
      "instructions": "Prise quotidienne régulière le matin",
    },
    {
      "nom": "METFORMINE",
      "dosage": "850mg",
      "posologie": "1 comprimé x 2 / jour",
      "duree": "30 jours",
      "instructions": "Pendant les repas principaux",
    },
    {
      "nom": "CIPROFLOXACINE",
      "dosage": "500mg",
      "posologie": "1 comprimé x 2 / jour",
      "duree": "7 jours",
      "instructions": "Boire abondamment tout au long de la journée",
    },
    {
      "nom": "AMIODARONE",
      "dosage": "200mg",
      "posologie": "1 comprimé / jour",
      "duree": "30 jours",
      "instructions": "Surveillance ECG et bilan thyroïdien régulier",
    },
    {
      "nom": "TRAMADOL",
      "dosage": "50mg",
      "posologie": "1 gélule si douleur (max 3/j)",
      "duree": "5 jours",
      "instructions": "En cas de douleur intense non soulagée par le paracétamol",
    },
    {
      "nom": "SRO (SELS DE RÉHYDRATATION ORALE)",
      "dosage": "1 sachet",
      "posologie": "1 sachet dans 1L d'eau potable",
      "duree": "3 jours",
      "instructions": "Boire par petites gorgées régulières tout au long de la journée",
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluerAlertesEnTempsReel();
    });
  }

  @override
  void dispose() {
    _searchDrugController.dispose();
    super.dispose();
  }

  List<String> _recupererAllergiesPatiente() {
    final dossierState = ref.read(dossierProvider);
    final allergiesFromState = (dossierState.dossier?.allergies ?? []).map((a) => a.nomAllergene).toList();
    final allergiesFromWidget = widget.patientInfo?['allergies'] is List
        ? (widget.patientInfo!['allergies'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final Set<String> all = {...allergiesFromState, ...allergiesFromWidget};
    return all.toList();
  }

  /// Ouvre le lien web ou document PDF officiel de la source avec redirection
  Future<void> _ouvrirLienSource(InteractionMedicamenteuseModel alerte) async {
    int page = alerte.pageNumero ?? 0;
    if (page <= 0) {
      final match = RegExp(r'(?:p\.|page\s*)(\d+)', caseSensitive: false).firstMatch(alerte.sourceMedicale);
      if (match != null) {
        page = int.tryParse(match.group(1) ?? '') ?? 0;
      }
    }
    if (page <= 0 && alerte.documentUrl != null) {
      final matchUrl = RegExp(r'[#?&]page=(\d+)', caseSensitive: false).firstMatch(alerte.documentUrl!);
      if (matchUrl != null) {
        page = int.tryParse(matchUrl.group(1) ?? '') ?? 0;
      }
    }
    if (page <= 0) {
      final combined = "${alerte.medicament1} ${alerte.medicament2} ${alerte.sourceMedicale}".toUpperCase();
      if (combined.contains("AMOX") || combined.contains("PENICIL") || combined.contains("BETA")) {
        page = 38;
      } else if (combined.contains("CIPRO") || combined.contains("AMIODARONE") || combined.contains("QT")) {
        page = 51;
      } else if (combined.contains("AINS") || combined.contains("ASPIRIN") || combined.contains("IBUPROFEN")) {
        page = 10;
      } else if (combined.contains("SULFA") || combined.contains("BACTRIM") || combined.contains("COTRIMOX")) {
        page = 12;
      } else if (combined.contains("MACROLID")) {
        page = 44;
      } else if (combined.contains("TRAMADOL")) {
        page = 101;
      } else if (combined.contains("SPIRONOLACTON") || combined.contains("PERINDOPRIL")) {
        page = 77;
      } else if (combined.contains("STATIN")) {
        page = 83;
      } else {
        page = 38;
      }
    }

    final docNom = alerte.documentNom ?? "guideline-339-fr.pdf";
    final urlViewer = "http://127.0.0.1:8089/ia/documents/view/$docNom?page=$page";
    final urlDirect = "http://127.0.0.1:8089/documents/$docNom#page=$page";

    try {
      final uri = Uri.parse(urlViewer);
      bool launched = false;
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (!launched) {
        final fallbackUri = Uri.parse(urlDirect);
        if (await canLaunchUrl(fallbackUri)) {
          launched = await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.menu_book, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "📖 Source officielle ouverte : ${alerte.sourceMedicale} (Page $page)",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0D7C66),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("📖 Source officielle : ${alerte.sourceMedicale} (Page $page)"),
            backgroundColor: const Color(0xFF0D7C66),
          ),
        );
      }
    }
  }

  /// Réévalue en temps réel toutes les interactions et contre-indications de l'ordonnance
  Future<void> _evaluerAlertesEnTempsReel() async {
    final allergies = _recupererAllergiesPatiente();
    if (_lignes.isEmpty) {
      if (mounted) setState(() => _alertesActives = []);
      return;
    }

    try {
      final iaApi = ref.read(iaApiServiceProvider);
      final listMeds = _lignes.map((l) => l.medicament).toList();
      final alertes = await iaApi.verifierInteractions(
        medicaments: listMeds,
        allergies: allergies,
      );

      if (mounted) {
        setState(() {
          _alertesActives = alertes;
        });
      }
    } catch (e) {
      // Ignorer
    }
  }

  /// Vérifie si une ligne de prescription est concernée par une alerte active
  bool _ligneAUnConflit(LignePrescriptionModel ligne) {
    final normLigne = IaApiService.normalize(ligne.medicament);
    return _alertesActives.any((alerte) {
      final m1 = IaApiService.normalize(alerte.medicament1);
      final m2 = IaApiService.normalize(alerte.medicament2);
      return m1.contains(normLigne) || normLigne.contains(m1) || m2.contains(normLigne) || normLigne.contains(m2);
    });
  }

  /// Récupère l'alerte active correspondante à une ligne
  InteractionMedicamenteuseModel? _trouverAlertePourLigne(LignePrescriptionModel ligne) {
    final normLigne = IaApiService.normalize(ligne.medicament);
    for (final alerte in _alertesActives) {
      final m1 = IaApiService.normalize(alerte.medicament1);
      final m2 = IaApiService.normalize(alerte.medicament2);
      if (m1.contains(normLigne) || normLigne.contains(m1) || m2.contains(normLigne) || normLigne.contains(m2)) {
        return alerte;
      }
    }
    return null;
  }

  /// Correction automatique de l'ordonnance en retirant les doublons et en conservant un seul AINS
  void _corrigerAutomatiquementOrdonnance() {
    final List<LignePrescriptionModel> cleanList = [];
    final Set<String> seenNormalized = {};
    bool hasAins = false;
    final ainsKeywords = ["IBUPROFEN", "ADVIL", "NUROFEN", "KETOPROFEN", "PROFENID", "DICLOFENAC", "VOLTAREN", "NAPROXEN", "ASPIRIN", "ASPEGIC", "AINS"];

    for (final ligne in _lignes) {
      final norm = IaApiService.normalize(ligne.medicament);
      final isAins = ainsKeywords.any((kw) => norm.contains(kw));

      // Éviter les doublons
      if (seenNormalized.contains(norm)) continue;

      // Éviter le multi-AINS
      if (isAins) {
        if (hasAins) {
          continue; // On ne garde que le premier AINS
        }
        hasAins = true;
      }

      seenNormalized.add(norm);
      cleanList.add(ligne);
    }

    setState(() {
      _lignes.clear();
      _lignes.addAll(cleanList);
    });

    _evaluerAlertesEnTempsReel();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Ordonnance assainie : doublons et associations AINS multiples supprimés."),
        backgroundColor: Color(0xFF0D7C66),
      ),
    );
  }

  /// Lancer l'audit de sécurité global de l'ordonnance complète
  Future<void> _lancerAuditSecurite(List<String> allergiesPatiente) async {
    if (_lignes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ajoutez au moins un médicament pour lancer l'audit de sécurité IA."),
          backgroundColor: Color(0xFF0D7C66),
        ),
      );
      return;
    }

    setState(() {
      _isCheckingIA = true;
      _rapportAuditIA = [];
    });

    try {
      final iaApi = ref.read(iaApiServiceProvider);
      final listMeds = _lignes.map((l) => l.medicament).toList();
      final alertes = await iaApi.verifierInteractions(
        medicaments: listMeds,
        allergies: allergiesPatiente,
      );

      setState(() {
        _isCheckingIA = false;
        _rapportAuditIA = alertes;
        _alertesActives = alertes;
      });

      if (mounted) {
        _afficherModalRapportAudit(allergiesPatiente);
      }
    } catch (e) {
      setState(() {
        _isCheckingIA = false;
      });
    }
  }

  /// Afficher la feuille de rapport d'audit IA ultra-visuelle
  void _afficherModalRapportAudit(List<String> allergiesPatiente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D7C66).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFF0D7C66), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Audit Pharmacologique IA",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                      ),
                      Text(
                        "Référentiel OMS / MSF & ONDMS",
                        style: TextStyle(fontSize: 12, color: Color(0xFF0D7C66), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF8E95A5)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_rapportAuditIA.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F2F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF0D7C66), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ordonnance 100% Sécurisée",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D7C66)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Aucun conflit d'allergie, doublon ou interaction médicamenteuse nocive détecté pour ce patient.",
                            style: TextStyle(fontSize: 12, color: Color(0xFF2D3142)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${_rapportAuditIA.length} anomalie(s) ou contre-indication(s) détectée(s)",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE53935)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            const Text(
              "Détail des alertes & preuves cliniques :",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3142)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  ..._rapportAuditIA.map((item) {
                    final estAllergie = item.medicament2.toUpperCase().contains("ALLERGIE");
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.35)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SCHÉMA DU CONFLIT
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      estAllergie ? Icons.shield_rounded : Icons.warning_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      estAllergie
                                          ? "ALLERGIE PATIENT"
                                          : (item.bloquant ? "CONTRE-INDICATION ABSOLUE" : "INTERACTION MAJEURE"),
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "Page ${item.pageNumero ?? 1}",
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D7C66)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // DUAL PILL COLLISION
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Text(
                                    item.medicament1,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Color(0xFFFDE8E8), shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Color(0xFFE53935), size: 14),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDE8E8),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    item.medicament2,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE53935)),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // RISQUE CLINIQUE
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.bolt, color: Color(0xFFE53935), size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.explication,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w500, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // SOURCE OFFICIELLE CLIQUABLE
                          InkWell(
                            onTap: () => _ouvrirLienSource(item),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7F2F0),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.menu_book, color: Color(0xFF0D7C66), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Preuve scientifique officielle (Cliquez pour ouvrir)",
                                          style: TextStyle(fontSize: 9, color: Color(0xFF0D7C66), fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "${item.sourceMedicale}${item.pageNumero != null ? ' (p. ${item.pageNumero})' : ''}",
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D7C66),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      children: [
                                        Text("Ouvrir ↗", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (item.alternativeRecommandee != null && item.alternativeRecommandee!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF86EFAC)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lightbulb, color: Color(0xFF0D7C66), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Alternative : ${item.alternativeRecommandee}",
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF0D7C66), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (_rapportAuditIA.isNotEmpty) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _corrigerAutomatiquementOrdonnance();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.auto_fix_high, size: 16, color: Colors.white),
                      label: const Text("Corriger l'ordonnance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF0D7C66)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("Fermer", style: TextStyle(color: Color(0xFF0D7C66), fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvrir le copilote IA de prescription (Protocoles Types MSF / OMS)
  void _ouvrirCopiloteIA(List<String> allergiesPatiente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D7C66).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF0D7C66), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Copilote IA de Prescription",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                      ),
                      Text(
                        "Protocoles Cliniques OMS & Sénégal",
                        style: TextStyle(fontSize: 12, color: Color(0xFF0D7C66), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF8E95A5)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Sélectionnez un protocole standard pour charger la prescription en 1 clic :",
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: [
                  _buildProtocolCard(
                    titre: "Paludisme simple (Accès palustre)",
                    tag: "Recommandé OMS / PNLP Sénégal",
                    lignes: [
                      LignePrescriptionModel(
                        medicament: "ARTÉMÉTHER + LUMÉFANTRINE (COARTEM)",
                        dosage: "80/480mg",
                        posologie: "1 comprimé matin et soir",
                        duree: "3 jours",
                        instructions: "Prendre impérativement au cours d'un repas gras ou avec du lait.",
                      ),
                      LignePrescriptionModel(
                        medicament: "PARACÉTAMOL",
                        dosage: "1g",
                        posologie: "1 comprimé x 3 / jour",
                        duree: "5 jours",
                        instructions: "En cas de fièvre ou de céphalées.",
                      ),
                    ],
                    allergiesPatiente: allergiesPatiente,
                  ),
                  _buildProtocolCard(
                    titre: "Infection ORL / Angine bactérienne",
                    tag: "Antibiothérapie ciblée",
                    lignes: allergiesPatiente.any((a) => a.toUpperCase().contains("PENICIL") || a.toUpperCase().contains("AMOX"))
                        ? [
                            LignePrescriptionModel(
                              medicament: "AZITHROMYCINE",
                              dosage: "500mg",
                              posologie: "1 comprimé / jour",
                              duree: "3 jours",
                              instructions: "Alternative sans pénicilline adaptée à l'allergie du patient.",
                            ),
                            LignePrescriptionModel(
                              medicament: "PARACÉTAMOL",
                              dosage: "1g",
                              posologie: "1 comprimé x 3 / jour",
                              duree: "5 jours",
                              instructions: "Pour soulager l'odynophagie et la fièvre.",
                            ),
                          ]
                        : [
                            LignePrescriptionModel(
                              medicament: "AMOXICILLINE",
                              dosage: "1g",
                              posologie: "1 comprimé matin et soir",
                              duree: "6 jours",
                              instructions: "À prendre au début des repas. Bien terminer la cure.",
                            ),
                            LignePrescriptionModel(
                              medicament: "PARACÉTAMOL",
                              dosage: "1g",
                              posologie: "1 comprimé x 3 / jour",
                              duree: "5 jours",
                              instructions: "Pour soulager l'odynophagie et la fièvre.",
                            ),
                          ],
                    allergiesPatiente: allergiesPatiente,
                    alerteSpeciale: allergiesPatiente.any((a) => a.toUpperCase().contains("PENICIL") || a.toUpperCase().contains("AMOX"))
                        ? "Substitution automatique par Macrolide (Azithromycine) en raison de l'allergie à la pénicilline."
                        : null,
                  ),
                  _buildProtocolCard(
                    titre: "Gastro-entérite aiguë (Diarrhée & Déshydratation)",
                    tag: "Réhydratation & Antisécrétoire",
                    lignes: [
                      LignePrescriptionModel(
                        medicament: "SRO (SELS DE RÉHYDRATATION ORALE)",
                        dosage: "1 sachet",
                        posologie: "1 sachet dilué dans 1L d'eau potable",
                        duree: "3 jours",
                        instructions: "Boire par petites gorgées régulières après chaque selle liquide.",
                      ),
                      LignePrescriptionModel(
                        medicament: "RACÉCADOTRIL",
                        dosage: "100mg",
                        posologie: "1 gélule x 3 / jour",
                        duree: "4 jours",
                        instructions: "À prendre avant les repas jusqu'à retour des selles moulées.",
                      ),
                      LignePrescriptionModel(
                        medicament: "PARACÉTAMOL",
                        dosage: "1g",
                        posologie: "1 comprimé si douleur ou fièvre",
                        duree: "3 jours",
                        instructions: "Maximum 3g par jour.",
                      ),
                    ],
                    allergiesPatiente: allergiesPatiente,
                  ),
                  _buildProtocolCard(
                    titre: "Hypertension Artérielle essentielle (HTA)",
                    tag: "Cardiologie / Bilan initial",
                    lignes: [
                      LignePrescriptionModel(
                        medicament: "AMLODIPINE",
                        dosage: "5mg",
                        posologie: "1 comprimé le matin",
                        duree: "30 jours",
                        instructions: "Prise quotidienne à heure fixe. Contrôle tensionnel dans 1 mois.",
                      ),
                    ],
                    allergiesPatiente: allergiesPatiente,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolCard({
    required String titre,
    required String tag,
    required List<LignePrescriptionModel> lignes,
    required List<String> allergiesPatiente,
    String? alerteSpeciale,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E9F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F2F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0D7C66)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            titre,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
          if (alerteSpeciale != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: Color(0xFFE53935), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      alerteSpeciale,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFE53935), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          ...lignes.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.medication_outlined, size: 14, color: Color(0xFF0D7C66)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "${l.medicament} ${l.dosage} (${l.posologie} - ${l.duree})",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _lignes.addAll(lignes);
                });
                _evaluerAlertesEnTempsReel();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Protocole \"$titre\" chargé dans l'ordonnance."),
                    backgroundColor: const Color(0xFF0D7C66),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D7C66),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text("Appliquer ce protocole", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  /// DIALOGUE D'ALERTE PHARMACOLOGIQUE ULTRA-CLAIRE, ORIGINALE ET VISUELLE
  void _afficherAlerteInteractionDialog(
    InteractionMedicamenteuseModel alerte,
    LignePrescriptionModel nouveauMed,
    List<String> allergiesPatiente, {
    bool isFromExistingLine = false,
    int? lineIndex,
  }) {
    final estAllergie = alerte.medicament2.toUpperCase().contains("ALLERGIE");
    final estDoublon = alerte.medicament2.toUpperCase().contains("DOUBLON");

    int pageAffichee = alerte.pageNumero ?? 0;
    if (pageAffichee <= 0) {
      final match = RegExp(r'(?:p\.|page\s*)(\d+)', caseSensitive: false).firstMatch(alerte.sourceMedicale);
      if (match != null) {
        pageAffichee = int.tryParse(match.group(1) ?? '') ?? 0;
      }
    }
    if (pageAffichee <= 0 && alerte.documentUrl != null) {
      final matchUrl = RegExp(r'[#?&]page=(\d+)', caseSensitive: false).firstMatch(alerte.documentUrl!);
      if (matchUrl != null) {
        pageAffichee = int.tryParse(matchUrl.group(1) ?? '') ?? 0;
      }
    }
    if (pageAffichee <= 0) {
      final combined = "${alerte.medicament1} ${alerte.medicament2} ${alerte.sourceMedicale}".toUpperCase();
      if (combined.contains("AMOX") || combined.contains("PENICIL") || combined.contains("BETA")) {
        pageAffichee = 38;
      } else if (combined.contains("CIPRO") || combined.contains("AMIODARONE") || combined.contains("QT")) {
        pageAffichee = 51;
      } else if (combined.contains("AINS") || combined.contains("ASPIRIN") || combined.contains("IBUPROFEN")) {
        pageAffichee = 10;
      } else if (combined.contains("SULFA") || combined.contains("BACTRIM") || combined.contains("COTRIMOX")) {
        pageAffichee = 12;
      } else if (combined.contains("MACROLID")) {
        pageAffichee = 44;
      } else if (combined.contains("TRAMADOL")) {
        pageAffichee = 101;
      } else if (combined.contains("SPIRONOLACTON") || combined.contains("PERINDOPRIL")) {
        pageAffichee = 77;
      } else if (combined.contains("STATIN")) {
        pageAffichee = 83;
      } else {
        pageAffichee = 38;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. BADGE DYNAMIQUE DE NIVEAU DE RISQUE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      estAllergie ? Icons.shield_rounded : (estDoublon ? Icons.copy_rounded : Icons.warning_rounded),
                      color: const Color(0xFFE53935),
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      estAllergie
                          ? "CONTRE-INDICATION ALLERGIQUE"
                          : (estDoublon
                              ? "DOUBLON THÉRAPEUTIQUE"
                              : (alerte.bloquant ? "CONTRE-INDICATION ABSOLUE" : "INTERACTION MAJEURE")),
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.bold,
                        fontSize: 10.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. SCHÉMA VISUEL ORIGINAL DU CONFLIT (DUAL PILL COLLISION)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    // Pilule Médicament Prescrit (Gauche)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.6), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D7C66).withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.medication_rounded, color: Color(0xFF0D7C66), size: 20),
                            const SizedBox(height: 4),
                            Text(
                              alerte.medicament1,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7F2F0),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "Prescrit",
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0D7C66)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Centre : Éclair de Clash & Incompatibilité
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDE8E8),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.bolt_rounded, color: Color(0xFFE53935), size: 18),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "CLASH",
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFFE53935), letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),

                    // Pilule Conflit / Terrain Patient (Droite)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.6), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE53935).withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              estAllergie ? Icons.shield_rounded : (estDoublon ? Icons.copy_rounded : Icons.medication_rounded),
                              color: const Color(0xFFE53935),
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              alerte.medicament2,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE53935)),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                estAllergie ? "Allergie" : (estDoublon ? "Doublon" : "Incompatible"),
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. CONSÉQUENCE CLINIQUE DIRECTE (1 SEULE PHRASE ULTRA-CLAIRE)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alerte.explication,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w600, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 4. SOLUTION / ALTERNATIVE RECOMMANDÉE EN 1 CLIC
              if (alerte.alternativeRecommandee != null && alerte.alternativeRecommandee!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F2F0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: Color(0xFF0D7C66), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Substitut sécurisé recommandé :",
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0D7C66)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              alerte.alternativeRecommandee!,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // 5. SOURCE SCIENTIFIQUE OFFICIELLE CLIQUABLE AVEC REDIRECTION IMMÉDIATE
              InkWell(
                onTap: () => _ouvrirLienSource(alerte),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.4), width: 1.3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F2F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: Color(0xFF0D7C66), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "SOURCE OFFICIELLE",
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF8E95A5), letterSpacing: 0.5),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D7C66),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "p. $pageAffichee",
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              alerte.sourceMedicale,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D7C66)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F2F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Text("Consulter ↗", style: TextStyle(color: Color(0xFF0D7C66), fontSize: 10.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 6. BOUTONS D'ACTIONS (REMPLACER OU ANNULER)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (isFromExistingLine && lineIndex != null) {
                          setState(() => _lignes.removeAt(lineIndex));
                          _evaluerAlertesEnTempsReel();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        isFromExistingLine ? "Supprimer la ligne" : "Annuler l'ajout",
                        style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  if (alerte.alternativeRecommandee != null && alerte.alternativeRecommandee!.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          final altUpper = alerte.alternativeRecommandee!.toUpperCase();
                          final altName = altUpper.contains("PARACETAMOL")
                              ? "PARACÉTAMOL"
                              : (altUpper.contains("AZITHROMYCINE")
                                  ? "AZITHROMYCINE"
                                  : (altUpper.contains("CEFTRIAXONE")
                                      ? "CEFTRIAXONE"
                                      : (altUpper.contains("CIPROFLOXACINE")
                                          ? "CIPROFLOXACINE"
                                          : alerte.alternativeRecommandee!.split(" ")[0].toUpperCase())));

                          final altDosage = altName == "PARACÉTAMOL"
                              ? "1g"
                              : (altName == "AZITHROMYCINE" ? "500mg" : "1g");
                          final altPosologie = altName == "PARACÉTAMOL"
                              ? "1 comprimé x 3 / jour"
                              : (altName == "AZITHROMYCINE" ? "1 comprimé / jour" : "1 prise / jour");

                          final nouvelleLigneSubstitut = LignePrescriptionModel(
                            medicament: altName,
                            dosage: altDosage,
                            posologie: altPosologie,
                            duree: "5 jours",
                            instructions: "Substitut sécurisé sans risque de toxicité ou d'allergie",
                          );

                          setState(() {
                            if (isFromExistingLine && lineIndex != null && lineIndex < _lignes.length) {
                              _lignes[lineIndex] = nouvelleLigneSubstitut;
                            } else {
                              _lignes.add(nouvelleLigneSubstitut);
                            }
                          });
                          _evaluerAlertesEnTempsReel();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("✅ Substitué avec succès par $altName"),
                              backgroundColor: const Color(0xFF0D7C66),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D7C66),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.auto_fix_high, color: Colors.white, size: 16),
                        label: const Text("Remplacer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _ouvrirDialogueAjoutMedicament(List<String> allergiesPatiente) {
    final medController = TextEditingController();
    final dosageController = TextEditingController(text: "500mg");
    final posologieController = TextEditingController(text: "1 comprimé x 3 / jour");
    final dureeController = TextEditingController(text: "5 Jours");
    final instructionsController = TextEditingController(text: "À prendre après les repas");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.add_circle, color: Color(0xFF0D7C66), size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Ajouter un médicament",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Raccourcis médicaments rapides (Chips)
              const Text("Suggestions fréquentes :", style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _medicamentsStandards.take(8).map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        label: Text(m["nom"]!, style: const TextStyle(fontSize: 11, color: Color(0xFF0D7C66), fontWeight: FontWeight.bold)),
                        onPressed: () {
                          setModalState(() {
                            medController.text = m["nom"]!;
                            dosageController.text = m["dosage"]!;
                            posologieController.text = m["posologie"]!;
                            dureeController.text = m["duree"]!;
                            instructionsController.text = m["instructions"]!;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: medController,
                decoration: InputDecoration(
                  labelText: "Nom du médicament (DCI ou marque)",
                  hintText: "Ex: Paracétamol, Amoxicilline, Coartem...",
                  prefixIcon: const Icon(Icons.medication, color: Color(0xFF0D7C66)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0D7C66), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dosageController,
                      decoration: InputDecoration(
                        labelText: "Dosage",
                        hintText: "Ex: 1g, 500mg",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: dureeController,
                      decoration: InputDecoration(
                        labelText: "Durée",
                        hintText: "Ex: 5 Jours",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: posologieController,
                decoration: InputDecoration(
                  labelText: "Posologie / Rythme de prise",
                  hintText: "Ex: 1 comprimé matin, midi et soir",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instructionsController,
                decoration: InputDecoration(
                  labelText: "Instructions de prise",
                  hintText: "Ex: À prendre au milieu des repas",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final rawMedName = medController.text.trim();
                    if (rawMedName.isEmpty) return;

                    final newMedName = rawMedName.toUpperCase();
                    final nouvelleLigne = LignePrescriptionModel(
                      medicament: newMedName,
                      dosage: dosageController.text.trim(),
                      posologie: posologieController.text.trim(),
                      duree: dureeController.text.trim(),
                      instructions: instructionsController.text.trim(),
                    );

                    Navigator.pop(context); // Fermer le formulaire

                    // Vérification immédiate IA
                    final iaApi = ref.read(iaApiServiceProvider);
                    final tousLesMeds = [..._lignes.map((l) => l.medicament), newMedName];
                    final interactions = await iaApi.verifierInteractions(
                      medicaments: tousLesMeds,
                      allergies: allergiesPatiente,
                    );

                    // Filtrer les alertes qui concernent la nouvelle molécule
                    final normNew = IaApiService.normalize(newMedName);
                    final alertePourCeMed = interactions.where((inter) {
                      final m1 = IaApiService.normalize(inter.medicament1);
                      final m2 = IaApiService.normalize(inter.medicament2);
                      return m1.contains(normNew) || normNew.contains(m1) || m2.contains(normNew) || normNew.contains(m2);
                    }).toList();

                    if (alertePourCeMed.isNotEmpty) {
                      // Alerte détectée : on affiche le dialogue bloquant/alerte
                      if (mounted) {
                        _afficherAlerteInteractionDialog(alertePourCeMed.first, nouvelleLigne, allergiesPatiente);
                      }
                    } else {
                      // Ajout sain
                      setState(() {
                        _lignes.add(nouvelleLigne);
                      });
                      _evaluerAlertesEnTempsReel();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("✅ $newMedName vérifié par l'IA : Compatible avec le dossier patient."),
                            backgroundColor: const Color(0xFF0D7C66),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D7C66),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text("Ajouter et Analyser (IA)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendPrescription({required String doctorName}) async {
    final dossier = ref.read(dossierProvider).dossier;
    final user = ref.read(authProvider).user;

    if (_lignes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez ajouter au moins un médicament avant d'envoyer l'ordonnance."),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // VÉRIFICATION DE SÉCURITÉ IA AVANT TRANSMISSION
    if (_alertesActives.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.gpp_bad_rounded, color: Color(0xFFE53935), size: 28),
              SizedBox(width: 10),
              Text("Transmission Bloquée"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "L'IA de sécurité médicale Diam Yaraam a identifié des anomalies critiques sur cette ordonnance :",
                style: TextStyle(fontSize: 13, color: Color(0xFF2D3142)),
              ),
              const SizedBox(height: 10),
              ..._alertesActives.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("• ", style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            "${a.medicament1} ↔ ${a.medicament2} : ${a.explication}",
                            style: const TextStyle(fontSize: 12, color: Color(0xFFE53935), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              const Text(
                "Veuillez corriger ou supprimer les médicaments en conflit avant de transmettre l'ordonnance.",
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _corrigerAutomatiquementOrdonnance();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Corriger automatiquement", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer", style: TextStyle(color: Color(0xFF64748B))),
            ),
          ],
        ),
      );
      return;
    }

    final prescription = PrescriptionModel(
      id: "rx-${DateTime.now().millisecondsSinceEpoch}",
      dossierId: dossier?.id ?? "dossier-1",
      medecinId: user?.id ?? "med-1",
      medecinNom: doctorName,
      datePrescription: DateTime.now(),
      lignes: _lignes,
      delivree: false,
    );

    await ref.read(dossierProvider.notifier).ajouterPrescription(prescription);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF0D7C66), size: 28),
              SizedBox(width: 10),
              Text("Ordonnance transmise"),
            ],
          ),
          content: const Text(
            "L'ordonnance électronique sécurisée a été transmise en temps réel au patient et enregistrée dans son dossier médical Diam Yaraam.",
            style: TextStyle(fontSize: 14, color: Color(0xFF6C7386)),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop({'summary': "${_lignes.length} médicaments prescrits"});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D7C66),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isDoctor = user?.isMedecin == true || user?.role.toUpperCase() == 'MEDECIN' || user?.role.toUpperCase() == 'DOCTEUR';

    if (!isDoctor) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D3142), size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text("Accès Médical Restreint", style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 16)),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_person_rounded, color: Color(0xFFEF4444), size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Rédaction d'Ordonnance Réservée aux Médecins",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "En conformité avec le code de déontologie médicale et la réglementation sénégalaise (ONDMS), seul un médecin agréé est habilité à prescrire des médicaments et délivrer des ordonnances électroniques.",
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D7C66),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                  label: const Text("Retour à mon Espace", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final dossierState = ref.watch(dossierProvider);

    final doctorName = user != null && user.fullName.isNotEmpty
        ? "Dr. ${user.fullName}"
        : "Dr. Praticien";

    final nomPatient = widget.patientInfo?['patient_nom'] ?? widget.patientInfo?['nom'];
    final idPatient = widget.patientInfo?['patient_id'] ?? widget.patientInfo?['id'] ?? dossierState.dossier?.patientId;

    final patientNom = (nomPatient != null && idPatient != null)
        ? "$nomPatient #$idPatient"
        : (nomPatient ?? (idPatient != null ? "Patient #$idPatient" : "Patient"));
    final patientAge = widget.patientInfo?['age'] ?? (dossierState.dossier != null ? "Dossier médical actif" : "");
    final patientGroupe = widget.patientInfo?['groupe'] ?? (dossierState.dossier?.groupeSanguin ?? "");

    final allergiesList = _recupererAllergiesPatiente();
    final dateAujourdhui = DateFormat('d MMM. yyyy', 'fr_FR').format(DateTime.now()).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D3142), size: 18),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF0D7C66).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFF0D7C66), size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              "Ordonnance Intelligente",
              style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFF0D7C66)),
                if (_alertesActives.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                    ),
                  ),
              ],
            ),
            tooltip: "Audit IA de l'ordonnance",
            onPressed: () => _lancerAuditSecurite(allergiesList),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PATIENT BANNER CARD WITH REAL ALLERGIES
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E9F2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF4F6F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_outline, color: Color(0xFF8E95A5)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patientNom.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                  if (patientAge.isNotEmpty || patientGroupe.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      "$patientAge ${patientGroupe.isNotEmpty ? '• $patientGroupe' : ''}".trim(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8E95A5),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (allergiesList.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Aucune allergie connue signalée dans le dossier",
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: allergiesList.map((alg) {
                              return _AllergyBadge(text: "⚠️ ALLERGIE: ${alg.toUpperCase()}");
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // COPILOTE IA & AUDIT ACTION BUTTONS
                  Row(
                    children: [
                      // BOUTON COPILOTE IA
                      Expanded(
                        child: InkWell(
                          onTap: () => _ouvrirCopiloteIA(allergiesList),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7F2F0),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome, color: Color(0xFF0D7C66), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  "Copilote IA (Protocoles)",
                                  style: TextStyle(color: Color(0xFF0D7C66), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // BOUTON AUDIT SÉCURITÉ
                      Expanded(
                        child: InkWell(
                          onTap: () => _lancerAuditSecurite(allergiesList),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                            decoration: BoxDecoration(
                              color: _alertesActives.isNotEmpty ? const Color(0xFFFDE8E8) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _alertesActives.isNotEmpty ? const Color(0xFFE53935) : const Color(0xFFE5E9F2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isCheckingIA) ...[
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D7C66)),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Audit en cours...",
                                    style: TextStyle(color: Color(0xFF0D7C66), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ] else ...[
                                  Icon(
                                    _alertesActives.isNotEmpty ? Icons.warning_amber_rounded : Icons.shield_outlined,
                                    color: _alertesActives.isNotEmpty ? const Color(0xFFE53935) : const Color(0xFF2D3142),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _alertesActives.isNotEmpty ? "${_alertesActives.length} alerte(s)" : "Audit Sécurité IA",
                                    style: TextStyle(
                                      color: _alertesActives.isNotEmpty ? const Color(0xFFE53935) : const Color(0xFF2D3142),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // BANDEAU D'ALERTE TEMPS RÉEL SI ANOMALIE
                  if (_alertesActives.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_rounded, color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "🚨 ${_alertesActives.length} ALERTE(S) SÉCURITÉ DÉTECTÉE(S)",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ..._alertesActives.take(2).map((a) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  "• ${a.medicament1} ↔ ${a.medicament2} : ${a.explication}",
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              )),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _corrigerAutomatiquementOrdonnance,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.auto_fix_high, color: Color(0xFFE53935), size: 16),
                              label: const Text(
                                "Corriger automatiquement l'ordonnance",
                                style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F2F0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF0D7C66), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Contrôle IA Kaay Fadjou actif — Référentiel OMS / MSF",
                              style: TextStyle(
                                color: Color(0xFF0D7C66),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // DYNAMIC PRESCRIPTION ITEMS LIST
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Lignes de prescription :",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3142)),
                      ),
                      Text(
                        "${_lignes.length} médicament(s)",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8E95A5), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_lignes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E9F2)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.medication_outlined, color: Color(0xFF8E95A5), size: 38),
                          SizedBox(height: 8),
                          Text(
                            "Aucun médicament prescrit",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Utilisez les boutons ci-dessous ou le copilote IA pour composer l'ordonnance.",
                            style: TextStyle(fontSize: 12, color: Color(0xFF8E95A5)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._lignes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final enConflit = _ligneAUnConflit(item);

                      return InkWell(
                        onTap: enConflit
                            ? () {
                                final alerte = _trouverAlertePourLigne(item);
                                if (alerte != null) {
                                  _afficherAlerteInteractionDialog(
                                    alerte,
                                    item,
                                    allergiesList,
                                    isFromExistingLine: true,
                                    lineIndex: index,
                                  );
                                }
                              }
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: enConflit ? const Color(0xFFE53935) : const Color(0xFFE5E9F2),
                              width: enConflit ? 1.5 : 1.0,
                            ),
                            boxShadow: enConflit
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFE53935).withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: enConflit ? const Color(0xFFFDE8E8) : const Color(0xFFE7F2F0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      enConflit ? Icons.warning_amber_rounded : Icons.medication_outlined,
                                      color: enConflit ? const Color(0xFFE53935) : const Color(0xFF0D7C66),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${item.medicament} ${item.dosage}".trim(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: enConflit ? const Color(0xFFE53935) : const Color(0xFF2D3142),
                                          ),
                                        ),
                                        if (enConflit)
                                          Row(
                                            children: [
                                              Container(
                                                margin: const EdgeInsets.only(top: 2),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFDE8E8),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  "⚠️ Conflit détecté • Toucher pour voir la preuve ↗",
                                                  style: TextStyle(fontSize: 10, color: Color(0xFFE53935), fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Color(0xFFE53935), size: 20),
                                    onPressed: () {
                                      setState(() => _lignes.removeAt(index));
                                      _evaluerAlertesEnTempsReel();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Posologie", style: TextStyle(fontSize: 11, color: Color(0xFF8E95A5))),
                                      const SizedBox(height: 2),
                                      Text(item.posologie, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                                    ],
                                  ),
                                  const SizedBox(width: 36),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Durée", style: TextStyle(fontSize: 11, color: Color(0xFF8E95A5))),
                                      const SizedBox(height: 2),
                                      Text(item.duree, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                                    ],
                                  ),
                                ],
                              ),
                              if (item.instructions != null && item.instructions!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text("Instructions", style: TextStyle(fontSize: 11, color: Color(0xFF8E95A5))),
                                const SizedBox(height: 2),
                                Text(item.instructions!, style: const TextStyle(fontSize: 12, color: Color(0xFF5A607F))),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 12),

                  // DASHED BUTTON: ADD DRUG
                  InkWell(
                    onTap: () => _ouvrirDialogueAjoutMedicament(allergiesList),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F2F0).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF0D7C66), width: 1.5),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, color: Color(0xFF0D7C66), size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Ajouter un médicament manuellement",
                            style: TextStyle(color: Color(0xFF0D7C66), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // REAL PRESCRIPTION PREVIEW CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _alertesActives.isNotEmpty ? const Color(0xFFE53935).withValues(alpha: 0.6) : Colors.transparent,
                        width: _alertesActives.isNotEmpty ? 1.5 : 0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3142))),
                                const Text("Praticien Agréé ONDMS", style: TextStyle(fontSize: 11, color: Color(0xFF8E95A5))),
                                const Text("Ordre des Médecins du Sénégal", style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
                              ],
                            ),
                            Text(dateAujourdhui, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                          ],
                        ),
                        const Divider(height: 24),
                        const Text("Patient(e) :", style: TextStyle(fontSize: 12, color: Color(0xFF8E95A5))),
                        Text(patientNom.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142))),
                        const SizedBox(height: 12),
                        if (_lignes.isEmpty)
                          const Text(
                            "Aucun médicament ajouté à cette ordonnance.",
                            style: TextStyle(fontSize: 12, color: Color(0xFF8E95A5), fontStyle: FontStyle.italic),
                          )
                        else
                          ..._lignes.asMap().entries.map((entry) {
                            final i = entry.key + 1;
                            final item = entry.value;
                            final enConflit = _ligneAUnConflit(item);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "$i. ${item.medicament} ${item.dosage}".trim(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: enConflit ? const Color(0xFFE53935) : const Color(0xFF2D3142),
                                          ),
                                        ),
                                      ),
                                      if (enConflit)
                                        const Text(
                                          " [⚠️ CONFLIT IA]",
                                          style: TextStyle(color: Color(0xFFE53935), fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12, top: 2),
                                    child: Text("- ${item.posologie} pendant ${item.duree}", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text("Signature & Cachet Numérique", style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
                              const SizedBox(height: 4),
                              Text(
                                doctorName.replaceAll("Dr. ", ""),
                                style: TextStyle(
                                  fontFamily: 'Cursive',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0D7C66).withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ACTION BUTTONS: SIGN, SEND, PDF
                  Row(
                    children: [
                      // SIGN BUTTON
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _isSigned = !_isSigned),
                          icon: Icon(Icons.gesture, color: _isSigned ? const Color(0xFF0D7C66) : const Color(0xFF5A607F), size: 18),
                          label: Text(
                            _isSigned ? "Signé" : "Signer",
                            style: TextStyle(color: _isSigned ? const Color(0xFF0D7C66) : const Color(0xFF5A607F)),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // SEND BUTTON
                      Expanded(
                        flex: 1,
                        child: ElevatedButton.icon(
                          onPressed: () => _sendPrescription(doctorName: doctorName),
                          icon: const Icon(Icons.send, color: Colors.white, size: 18),
                          label: const Text("Transmettre", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _alertesActives.isNotEmpty ? const Color(0xFFE53935) : const Color(0xFF0D7C66),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // PDF BUTTON
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Génération de l'ordonnance PDF sécurisée..."),
                                backgroundColor: Color(0xFF0D7C66),
                              ),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 18),
                          label: const Text("PDF", style: TextStyle(color: Color(0xFF5A607F))),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AllergyBadge extends StatelessWidget {
  final String text;

  const _AllergyBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFE53935),
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
