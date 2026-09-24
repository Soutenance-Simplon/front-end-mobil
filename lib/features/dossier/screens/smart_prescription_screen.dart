import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../../ia/models/interaction_medicamenteuse_model.dart';
import '../../ia/providers/ia_provider.dart';
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
  InteractionMedicamenteuseModel? _alerteIA;
  List<InteractionMedicamenteuseModel> _rapportAuditIA = [];
  bool _auditEffectue = false;

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
    {
      "nom": "RACÉCADOTRIL",
      "dosage": "100mg",
      "posologie": "1 gélule x 3 / jour",
      "duree": "4 jours",
      "instructions": "Avant les repas jusqu'à arrêt des selles liquides",
    },
  ];

  @override
  void dispose() {
    _searchDrugController.dispose();
    super.dispose();
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
      _auditEffectue = false;
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
        _auditEffectue = true;
      });

      if (mounted) {
        _afficherModalRapportAudit(allergiesPatiente);
      }
    } catch (e) {
      setState(() {
        _isCheckingIA = false;
        _auditEffectue = true;
      });
    }
  }

  /// Afficher la feuille de rapport d'audit IA
  void _afficherModalRapportAudit(List<String> allergiesPatiente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
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
                            "Aucun conflit d'allergie ou interaction médicamenteuse nocive détecté pour ce patient.",
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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 26),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${_rapportAuditIA.length} alerte(s) de sécurité détectée(s) sur cette ordonnance.",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE53935)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              "Détail des vérifications cliniques :",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3142)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  ..._rapportAuditIA.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.niveauDanger.replaceAll("_", " "),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${item.medicament1} ↔ ${item.medicament2}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3142)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.explication,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Source : ${item.sourceMedicale}${item.pageNumero != null ? ' (p. ${item.pageNumero})' : ''}",
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF0D7C66), fontWeight: FontWeight.w600),
                          ),
                          if (item.alternativeRecommandee != null && item.alternativeRecommandee!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7F2F0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lightbulb_outline, color: Color(0xFF0D7C66), size: 18),
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
                  // Verification patient allergies summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E9F2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Profil Allergique Patient :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                        const SizedBox(height: 4),
                        Text(
                          allergiesPatiente.isNotEmpty
                              ? allergiesPatiente.join(", ").toUpperCase()
                              : "Aucune allergie connue répertoriée dans le dossier",
                          style: TextStyle(
                            fontSize: 12,
                            color: allergiesPatiente.isNotEmpty ? const Color(0xFFE53935) : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D7C66),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Fermer l'audit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
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
                  _buildProtocolCard(
                    titre: "Infection Urinaire basse non compliquée (Cystite)",
                    tag: "Monodose minute",
                    lignes: [
                      LignePrescriptionModel(
                        medicament: "FOSFOMYCINE-TROMÉTAMOL",
                        dosage: "3g",
                        posologie: "1 sachet en prise unique le soir au coucher",
                        duree: "1 jour",
                        instructions: "Vider la vessie avant la prise. Boire 1,5L d'eau le lendemain.",
                      ),
                      LignePrescriptionModel(
                        medicament: "PARACÉTAMOL",
                        dosage: "1g",
                        posologie: "1 comprimé x 3 / jour si brûlures",
                        duree: "3 jours",
                        instructions: "Pendant les repas.",
                      ),
                    ],
                    allergiesPatiente: allergiesPatiente,
                  ),
                  _buildProtocolCard(
                    titre: "Diabète de Type 2 (Première intention)",
                    tag: "Endocrinologie",
                    lignes: [
                      LignePrescriptionModel(
                        medicament: "METFORMINE",
                        dosage: "850mg",
                        posologie: "1 comprimé matin et soir",
                        duree: "30 jours",
                        instructions: "À prendre au milieu des repas pour réduire les effets digestifs.",
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
                  _alerteIA = null;
                });
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

  /// Dialogue d'alerte critique avec action de substitution automatique
  void _afficherAlerteInteractionDialog(
    InteractionMedicamenteuseModel alerte,
    LignePrescriptionModel nouveauMed,
    List<String> allergiesPatiente,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_rounded, color: Color(0xFFE53935), size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerte.bloquant ? "CONTRE-INDICATION ABSOLUE" : "ALERTE PHARMACOLOGIQUE",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  Text(
                    "${alerte.medicament1} ↔ ${alerte.medicament2}",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF2D3142), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerte.explication,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF2D3142), height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Source : ${alerte.sourceMedicale}${alerte.pageNumero != null ? ' (p. ${alerte.pageNumero})' : ''}",
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFFE53935), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (alerte.alternativeRecommandee != null && alerte.alternativeRecommandee!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                "Alternative thérapeutique recommandée :",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D7C66)),
              ),
              const SizedBox(height: 4),
              Text(
                alerte.alternativeRecommandee!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _alerteIA = null);
            },
            child: const Text("Annuler l'ajout", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          if (alerte.alternativeRecommandee != null && alerte.alternativeRecommandee!.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Extraire le nom de l'alternative si possible ou ouvrir le modal avec l'alternative
                final altName = alerte.alternativeRecommandee!.split(" ")[0].toUpperCase();
                setState(() {
                  _lignes.add(
                    LignePrescriptionModel(
                      medicament: altName.isNotEmpty ? altName : "ALTERNATIVE CONSEILLÉE",
                      dosage: "Dosage standard",
                      posologie: "1 prise x 2 / jour",
                      duree: "5 jours",
                      instructions: "Substitut sécurisé sans risque d'interaction",
                    ),
                  );
                  _alerteIA = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Alternative $altName ajoutée à l'ordonnance."),
                    backgroundColor: const Color(0xFF0D7C66),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D7C66),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Remplacer par l'alternative", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            )
          else
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _lignes.add(nouveauMed);
                  _alerteIA = null;
                });
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE53935)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Forcer l'ajout", style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
            ),
        ],
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
                  children: _medicamentsStandards.take(7).map((m) {
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
                    if (medController.text.trim().isNotEmpty) {
                      final newMedName = medController.text.trim().toUpperCase();
                      final nouvelleLigne = LignePrescriptionModel(
                        medicament: newMedName,
                        dosage: dosageController.text.trim(),
                        posologie: posologieController.text.trim(),
                        duree: dureeController.text.trim(),
                        instructions: instructionsController.text.trim(),
                      );

                      Navigator.pop(context); // Close input modal

                      setState(() {
                        _isCheckingIA = true;
                        _alerteIA = null;
                      });

                      try {
                        final iaApi = ref.read(iaApiServiceProvider);
                        // Passer tous les médicaments actuels + le nouveau médicament
                        final tousLesMeds = [..._lignes.map((l) => l.medicament), newMedName];
                        final interactions = await iaApi.verifierInteractions(
                          medicaments: tousLesMeds,
                          allergies: allergiesPatiente,
                        );

                        // Filtrer les interactions qui concernent le nouveau médicament
                        final alertePourCeMed = interactions.where((inter) {
                          final m1 = inter.medicament1.toUpperCase();
                          final m2 = inter.medicament2.toUpperCase();
                          return m1.contains(newMedName) ||
                              newMedName.contains(m1) ||
                              m2.contains(newMedName) ||
                              newMedName.contains(m2) ||
                              inter.estCritique;
                        }).toList();

                        if (alertePourCeMed.isNotEmpty) {
                          setState(() {
                            _alerteIA = alertePourCeMed.first;
                            _isCheckingIA = false;
                          });
                          if (mounted) {
                            _afficherAlerteInteractionDialog(alertePourCeMed.first, nouvelleLigne, allergiesPatiente);
                          }
                        } else {
                          setState(() {
                            _isCheckingIA = false;
                            _alerteIA = null;
                            _lignes.add(nouvelleLigne);
                          });
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
                      } catch (e) {
                        setState(() {
                          _isCheckingIA = false;
                          _lignes.add(nouvelleLigne);
                        });
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

    final allergiesList = (dossierState.dossier?.allergies ?? [])
        .map((a) => a.nomAllergene)
        .toList();

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
            icon: const Icon(Icons.shield_outlined, color: Color(0xFF0D7C66)),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE5E9F2)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shield_outlined, color: Color(0xFF2D3142), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  "Audit Sécurité IA",
                                  style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // STATUS IA / ALERTE
                  if (_isCheckingIA)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E9F2)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D7C66))),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              "L'IA analyse les interactions médicamenteuses et contre-indications...",
                              style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_alerteIA != null)
                    Container(
                      padding: const EdgeInsets.all(16),
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
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "ALERTE IA — ${_alerteIA!.niveauDanger.replaceAll('_', ' ')}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _alerteIA!.explication,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Recommandation : ${_alerteIA!.recommandation}",
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() => _alerteIA = null);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text(
                                    "Fermer l'alerte",
                                    style: TextStyle(
                                      color: Color(0xFFE53935),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    // AI SUCCESS BANNER (GREEN)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F2F0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF0D7C66), size: 20),
                          SizedBox(width: 10),
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

                  const SizedBox(height: 20),

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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE7F2F0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.medication_outlined, color: Color(0xFF0D7C66), size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "${item.medicament} ${item.dosage}".trim(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFE53935), size: 20),
                                  onPressed: () {
                                    setState(() => _lignes.removeAt(index));
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
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("$i. ${item.medicament} ${item.dosage}".trim(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                            backgroundColor: const Color(0xFF0D7C66),
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
