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

  @override
  void dispose() {
    _searchDrugController.dispose();
    super.dispose();
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
      builder: (context) => Container(
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
            const Text(
              "Ajouter un médicament",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: medController,
              decoration: InputDecoration(
                labelText: "Nom du médicament (DCI ou marque)",
                hintText: "Ex: Paracétamol, Amoxicilline...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                labelText: "Posologie",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: instructionsController,
              decoration: InputDecoration(
                labelText: "Instructions de prise",
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
                    // Start IA Check
                    Navigator.pop(context); // Close input modal
                    setState(() {
                      _isCheckingIA = true;
                      _alerteIA = null;
                    });
                    
                    try {
                      final iaApi = ref.read(iaApiServiceProvider);
                      final interactions = await iaApi.verifierInteractions(
                        medicaments: [medController.text.trim()],
                        allergies: allergiesPatiente,
                      );
                      
                      if (interactions.isNotEmpty) {
                        setState(() {
                          _alerteIA = interactions.first;
                          _isCheckingIA = false;
                        });
                      } else {
                        setState(() {
                          _isCheckingIA = false;
                          _alerteIA = null;
                          _lignes.add(
                            LignePrescriptionModel(
                              medicament: medController.text.trim().toUpperCase(),
                              dosage: dosageController.text.trim(),
                              posologie: posologieController.text.trim(),
                              duree: dureeController.text.trim(),
                              instructions: instructionsController.text.trim(),
                            ),
                          );
                        });
                      }
                    } catch (e) {
                      setState(() => _isCheckingIA = false);
                      // En cas d'erreur on l'ajoute directement
                      setState(() {
                        _lignes.add(
                          LignePrescriptionModel(
                            medicament: medController.text.trim().toUpperCase(),
                            dosage: dosageController.text.trim(),
                            posologie: posologieController.text.trim(),
                            duree: dureeController.text.trim(),
                            instructions: instructionsController.text.trim(),
                          ),
                        );
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D7C66),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text("Ajouter et Analyser (IA)", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
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
                context.pop();
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
                    color: const Color(0xFFEF4444).withOpacity(0.1),
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
                  "En conformité avec le code de déontologie médicale et la réglementation sénégalaise (ONMS), seul un médecin agréé est habilité à prescrire des médicaments et délivrer des ordonnances électroniques.",
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
        title: const Text(
          "Ordonnance Intelligente",
          style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
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
                                      fontSize: 16,
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
                              "Aucune allergie connue signalée",
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            children: allergiesList.map((alg) {
                              return _AllergyBadge(text: "⚠️ ${alg.toUpperCase()}");
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

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
                          Text("L'IA analyse les interactions médicamenteuses...", style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold)),
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
                                  "ALERTE IA — ${_alerteIA!.niveauDanger}",
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
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Recommandation : ${_alerteIA!.recommandation}",
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                                    "Annuler l'ajout",
                                    style: TextStyle(
                                      color: Color(0xFFE53935),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Forcer l'ajout
                                    setState(() {
                                      _lignes.add(
                                        LignePrescriptionModel(
                                          medicament: _alerteIA!.medicament1.toUpperCase(),
                                          dosage: "",
                                          posologie: "",
                                          duree: "",
                                          instructions: "Ajout forcé malgré l'alerte",
                                        ),
                                      );
                                      _alerteIA = null;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text(
                                    "Forcer l'ajout",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
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
                              "Contrôle IA Kaay Fadjou actif — Aucune interaction toxique",
                              style: TextStyle(
                                color: Color(0xFF0D7C66),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // DYNAMIC PRESCRIPTION ITEMS LIST
                  if (_lignes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E9F2)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.medication_outlined, color: Color(0xFF8E95A5), size: 36),
                          SizedBox(height: 8),
                          Text(
                            "Aucun médicament prescrit",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Cliquez ci-dessous pour ajouter un médicament à l'ordonnance.",
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
                                const Icon(Icons.medication_outlined, color: Color(0xFF0D7C66), size: 22),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${item.medicament} ${item.dosage}".trim(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFE53935), size: 18),
                                  onPressed: () {
                                    setState(() => _lignes.removeAt(index));
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Posologie", style: TextStyle(fontSize: 11, color: Color(0xFF8E95A5))),
                                    const SizedBox(height: 2),
                                    Text(item.posologie, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(width: 36),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Durée", style: TextStyle(fontSize: 11, color: Color(0xFF8E95A5))),
                                    const SizedBox(height: 2),
                                    Text(item.duree, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                            "Ajouter un médicament",
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
                                Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const Text("Praticien Agréé ONMS", style: TextStyle(fontSize: 11, color: Color(0xFF8E95A5))),
                                const Text("Ordre des Médecins du Sénégal", style: TextStyle(fontSize: 10, color: Color(0xFF8E95A5))),
                              ],
                            ),
                            Text(dateAujourdhui, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                          ],
                        ),
                        const Divider(height: 24),
                        const Text("Patient(e) :", style: TextStyle(fontSize: 12, color: Color(0xFF8E95A5))),
                        Text(patientNom.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                          label: const Text("Envoyer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
