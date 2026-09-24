import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../patient/models/medecin_consent_model.dart';
import '../../patient/providers/consent_provider.dart';
import '../../rdv/providers/rdv_provider.dart';
import '../models/allergie_model.dart';
import '../models/antecedent_model.dart';
import '../models/consultation_model.dart';
import '../models/prescription_model.dart';
import '../models/vaccination_model.dart';
import '../providers/dossier_provider.dart';

class EcranDossierMedical extends ConsumerStatefulWidget {
  final Map<String, dynamic>? patientCible;

  const EcranDossierMedical({super.key, this.patientCible});

  @override
  ConsumerState<EcranDossierMedical> createState() => _EcranDossierMedicalState();
}

class _EcranDossierMedicalState extends ConsumerState<EcranDossierMedical> {
  int _indexOngletActuel = 0;
  final TextEditingController _rechercheCtrl = TextEditingController();
  Map<String, dynamic>? _patientSelectionne;
  bool _voirMonPropreDossier = false;

  final List<String> _onglets = ["Résumé", "Consultations", "Ordonnances", "Allergies & Antécédents", "Vaccins", "Accès Médecins 🛡️"];

  // Liste des patients ayant pris RDV avec le médecin (avec données de démonstration enrichies pour la soutenance)
  final List<Map<String, dynamic>> _patientsFixes = [
    {
      "id": "PAT-8821",
      "nom": "Fatou SOW",
      "telephone": "+221 77 123 45 67",
      "groupeSanguin": "A+",
      "poids": 68.0,
      "taille": 172.0,
      "totalRdv": 3,
      "dernierRdv": "Il y a 4 jours",
      "motifDernierRdv": "Suivi tensionnel & Bilan annuel",
      "typeDernierRdv": "TÉLÉCONSULTATION",
    },
    {
      "id": "PAT-4432",
      "nom": "Mamadou DIOP",
      "telephone": "+221 78 456 78 90",
      "groupeSanguin": "O+",
      "poids": 79.5,
      "taille": 182.0,
      "totalRdv": 2,
      "dernierRdv": "Il y a 2 semaines",
      "motifDernierRdv": "Contrôle cardiologique",
      "typeDernierRdv": "PRÉSENTIEL",
    },
    {
      "id": "PAT-1990",
      "nom": "Astou NDIAYE",
      "telephone": "+221 70 987 65 43",
      "groupeSanguin": "B+",
      "poids": 62.0,
      "taille": 165.0,
      "totalRdv": 4,
      "dernierRdv": "Il y a 1 mois",
      "motifDernierRdv": "Rhinite & Bilan respiratoire",
      "typeDernierRdv": "TÉLÉCONSULTATION",
    },
    {
      "id": "PAT-3310",
      "nom": "Ibrahima FALL",
      "telephone": "+221 76 234 56 78",
      "groupeSanguin": "AB+",
      "poids": 84.0,
      "taille": 180.0,
      "totalRdv": 1,
      "dernierRdv": "Hier à 10:30",
      "motifDernierRdv": "Consultation générale & Certificat",
      "typeDernierRdv": "PRÉSENTIEL",
    },
  ];

  @override
  void initState() {
    super.initState();
    final isSelf = widget.patientCible?['isSelf'] == true;
    if (isSelf) {
      _voirMonPropreDossier = true;
      _patientSelectionne = null;
    } else if (widget.patientCible != null && widget.patientCible!.isNotEmpty) {
      _patientSelectionne = widget.patientCible;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      final isDoctor = user?.isMedecin == true || user?.role == 'MEDECIN';
      final isFamilyMember = widget.patientCible?['isFamilyMember'] == true;

      if (_voirMonPropreDossier) {
        final pId = user?.id.isNotEmpty == true ? user!.id : 'med-1';
        ref.read(dossierProvider.notifier).loadDossier(patientId: pId);
      } else if (isFamilyMember) {
        final pId = widget.patientCible?['id']?.toString().trim().isNotEmpty == true
            ? widget.patientCible!['id'].toString().trim()
            : 'FAM-1';
        ref.read(dossierProvider.notifier).loadDossier(patientId: pId);
      } else if (isDoctor) {
        ref.read(rdvProvider.notifier).loadAgendaMedecin(medecinId: user?.id ?? 'med-1');
        if (_patientSelectionne != null) {
          final pId = _patientSelectionne!['id'] ?? 'PAT-8821';
          ref.read(dossierProvider.notifier).loadDossier(
                patientId: pId,
                defaultGroupe: _patientSelectionne!['groupeSanguin'],
                defaultPoids: (_patientSelectionne!['poids'] as num?)?.toDouble(),
                defaultTaille: (_patientSelectionne!['taille'] as num?)?.toDouble(),
              );
        }
      } else {
        final patientId = widget.patientCible != null
            ? widget.patientCible!['id']
            : (user?.id.isNotEmpty == true ? user!.id : 'p1');
        ref.read(dossierProvider.notifier).loadDossier(patientId: patientId);
      }
    });
  }

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    super.dispose();
  }

  void _selectionnerPatient(Map<String, dynamic> patient) {
    setState(() {
      _patientSelectionne = patient;
      _indexOngletActuel = 0;
    });

    ref.read(dossierProvider.notifier).loadDossier(
          patientId: patient['id'] ?? 'PAT-8821',
          defaultGroupe: patient['groupeSanguin'],
          defaultPoids: (patient['poids'] as num?)?.toDouble(),
          defaultTaille: (patient['taille'] as num?)?.toDouble(),
        );
  }

  void _ouvrirModalModifierConstantes(String currentGroupe, double currentPoids, double currentTaille) {
    String selectedGroupe = currentGroupe;
    final poidsCtrl = TextEditingController(text: currentPoids.toStringAsFixed(1));
    final tailleCtrl = TextEditingController(text: currentTaille.toStringAsFixed(0));
    final groupes = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 24,
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
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.monitor_weight_outlined, color: Color(0xFF0D7C66), size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Modifier les Constantes Vitales",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "Ces constantes médicales sont enregistrées et synchronisées avec le Pass Santé du patient.",
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),

              // GROUPE SANGUIN
              const Text("Groupe Sanguin", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedGroupe,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
                items: groupes.map((g) {
                  return DropdownMenuItem(
                    value: g,
                    child: Text(g, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D7C66))),
                  );
                }).toList(),
                onChanged: (val) => setModalState(() => selectedGroupe = val ?? selectedGroupe),
              ),
              const SizedBox(height: 14),

              // POIDS ET TAILLE
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Poids (kg)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: poidsCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            suffixText: "kg",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Taille (cm)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: tailleCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            suffixText: "cm",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final poids = double.tryParse(poidsCtrl.text) ?? currentPoids;
                    final taille = double.tryParse(tailleCtrl.text) ?? currentTaille;
                    ref.read(dossierProvider.notifier).mettreAJourConstantes(
                          groupeSanguin: selectedGroupe,
                          poidsKg: poids,
                          tailleCm: taille,
                        );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Constantes médicales mises à jour avec succès !"),
                        backgroundColor: Color(0xFF0D7C66),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D7C66),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Enregistrer les modifications", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _ouvrirModalAjouterAllergie() {
    final nomCtrl = TextEditingController();
    final reactionCtrl = TextEditingController();
    String severite = 'SEVERE';
    String type = 'MEDICAMENTEUSE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 24,
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
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 18),
              const Text("Ajouter une Allergie", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              TextField(
                controller: nomCtrl,
                decoration: InputDecoration(
                  labelText: "Nom de l'allergène (ex: Pénicilline, Arachides)",
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: severite,
                decoration: InputDecoration(
                  labelText: "Niveau de sévérité",
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'SEVERE', child: Text("Sévère (Urgence vitale / Choc)")),
                  DropdownMenuItem(value: 'MOYENNE', child: Text("Moyenne (Œdème / Éruptions)")),
                  DropdownMenuItem(value: 'FAIBLE', child: Text("Faible (Gêne modérée)")),
                ],
                onChanged: (val) => setModalState(() => severite = val ?? 'SEVERE'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reactionCtrl,
                decoration: InputDecoration(
                  labelText: "Réaction observée (ex: Démangeaisons, Gêne respiratoire)",
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (nomCtrl.text.trim().isNotEmpty) {
                      ref.read(dossierProvider.notifier).ajouterAllergieDirect(
                            nomAllergene: nomCtrl.text.trim(),
                            severite: severite,
                            type: type,
                            reaction: reactionCtrl.text.trim().isNotEmpty ? reactionCtrl.text.trim() : null,
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Allergie ajoutée au dossier médical !"), backgroundColor: Color(0xFF0D7C66)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Ajouter au Dossier", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDoctor = user?.isMedecin == true || user?.role == 'MEDECIN';

    // CAS 1 : Médecin connecté qui consulte la liste de ses patients ayant pris RDV
    if (isDoctor && !_voirMonPropreDossier && _patientSelectionne == null) {
      return _buildDoctorPatientsListScreen(user);
    }

    // CAS 2 : Consultation du dossier médical détaillé (soit par le patient pour lui-même, soit par le médecin pour son patient ou pour son propre dossier)
    return _buildDetailedMedicalRecordScreen(user, isDoctor);
  }

  // =========================================================================
  // VUE 1 : RÉPERTOIRE EXCLUSIF DES PATIENTS DU MÉDECIN (CONTRÔLE D'ACCÈS RDV)
  // =========================================================================
  Widget _buildDoctorPatientsListScreen(dynamic doctorUser) {
    final doctorName = doctorUser?.fullName.trim().isNotEmpty == true ? "Dr. ${doctorUser!.fullName}" : "Docteur";
    final query = _rechercheCtrl.text.trim().toLowerCase();

    // Filtre des patients
    final patientsFiltres = _patientsFixes.where((p) {
      final nom = (p['nom'] ?? '').toString().toLowerCase();
      final id = (p['id'] ?? '').toString().toLowerCase();
      final tel = (p['telephone'] ?? '').toString().toLowerCase();
      return nom.contains(query) || id.contains(query) || tel.contains(query);
    }).toList();

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
          "Dossiers de Mes Patients",
          style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0D7C66)),
            tooltip: "Scanner Pass Urgence",
            onPressed: () => context.push('/qr-scanner', extra: {'tab': 1, 'isMedecin': true}),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BANNIÈRE DOCTEUR & SÉCURITÉ MÉDICALE
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D7C66), Color(0xFF0D7C66)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D7C66).withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doctorName,
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Text(
                                        "Praticien Agréé ONMS • Espace Médical",
                                        style: TextStyle(color: Colors.white70, fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D7C66),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${_patientsFixes.length} Patients Suivis",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_rounded, color: Colors.white70, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Règle de Secret Médical : Vous n'avez accès qu'aux dossiers des patients ayant pris rendez-vous dans votre cabinet.",
                                style: TextStyle(color: Colors.white, fontSize: 11, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // BANDEAU : UN MÉDECIN EST AUSSI UN PATIENT (ACCÈS DOSSIER PERSONNEL)
                Container(
                  margin: const EdgeInsets.only(top: 14, bottom: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.25), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F2F0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFF0D7C66), size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Mon Dossier Médical Personnel",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Un médecin est aussi un patient : accédez à votre carnet, vos constantes, vos antécédents et votre QR Code vital.",
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _voirMonPropreDossier = true;
                            _patientSelectionne = null;
                          });
                          ref.read(dossierProvider.notifier).loadDossier(
                                patientId: doctorUser?.id ?? 'med-1',
                              );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D7C66),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text("Mon Dossier", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // BARRE DE RECHERCHE PATIENT
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _rechercheCtrl,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: "Rechercher parmi mes patients (Nom, ID, Téléphone)...",
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D7C66)),
                      suffixIcon: _rechercheCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                              onPressed: () {
                                _rechercheCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // TITRE SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        "Mes Patients Récents (Avec RDV Actif)",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${patientsFiltres.length} résultat(s)",
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // LISTE DES PATIENTS
                Expanded(
                  child: patientsFiltres.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_search_rounded, size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 10),
                              const Text("Aucun patient trouvé avec ce critère", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              const Text("Seuls vos patients ayant pris rendez-vous sont répertoriés.", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: patientsFiltres.length,
                          itemBuilder: (context, index) {
                            final p = patientsFiltres[index];
                            final initiales = (p['nom'] as String).split(' ').map((e) => e[0]).take(2).join();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE7F2F0),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          initiales,
                                          style: const TextStyle(color: Color(0xFF0D7C66), fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  p['nom'],
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFEE2E2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    p['groupeSanguin'],
                                                    style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 11),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              "ID: ${p['id']} • Tél: ${p['telephone']}",
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Dernier RDV : ${p['dernierRdv']}",
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              "${p['motifDernierRdv']} (${p['typeDernierRdv']})",
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF0D7C66)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _selectionnerPatient(p),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0D7C66),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        icon: const Icon(Icons.folder_shared_rounded, color: Colors.white, size: 15),
                                        label: const Text("Ouvrir Dossier", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // VUE 2 : DOSSIER MÉDICAL DÉTAILLÉ DU PATIENT
  // =========================================================================
  Widget _buildDetailedMedicalRecordScreen(dynamic user, bool isDoctor) {
    final dossierState = ref.watch(dossierProvider);
    final dossier = dossierState.dossier;

    // Nom et informations du patient consulté
    final isFamilyMember = widget.patientCible?['isFamilyMember'] == true ||
        (!isDoctor && widget.patientCible != null && !_voirMonPropreDossier);

    String nomPatient;
    if (_voirMonPropreDossier) {
      nomPatient = (user?.fullName.trim().isNotEmpty == true
          ? user!.fullName
          : "Dr. ${user?.firstName ?? ''} ${user?.lastName ?? ''}".trim());
    } else if (widget.patientCible?['nom'] != null &&
        widget.patientCible!['nom'].toString().trim().isNotEmpty) {
      nomPatient = widget.patientCible!['nom'].toString().trim();
    } else if (_patientSelectionne?['nom'] != null &&
        _patientSelectionne!['nom'].toString().trim().isNotEmpty) {
      nomPatient = _patientSelectionne!['nom'].toString().trim();
    } else if (isFamilyMember) {
      final prenom = widget.patientCible?['prenom']?.toString().trim() ?? '';
      final nomFamille = widget.patientCible?['nomFamille']?.toString().trim() ?? '';
      final fullName = "$prenom $nomFamille".trim();
      nomPatient = fullName.isNotEmpty ? fullName : "Membre de la famille";
    } else if (user?.fullName.trim().isNotEmpty == true) {
      nomPatient = user!.fullName.trim();
    } else if (dossier != null && dossier.patientId.isNotEmpty) {
      nomPatient = "Patient #${dossier.patientId}";
    } else {
      nomPatient = "Patient Diam-Yaraam";
    }

    final String idPatient = (widget.patientCible?['id']?.toString().trim().isNotEmpty == true)
        ? widget.patientCible!['id'].toString().trim()
        : (_patientSelectionne?['id']?.toString().trim().isNotEmpty == true
            ? _patientSelectionne!['id'].toString().trim()
            : (_voirMonPropreDossier
                ? (user?.id.isNotEmpty == true ? user!.id : 'MED-001')
                : (user?.id.isNotEmpty == true ? user!.id : 'DY-8829')));

    final String initiales = nomPatient.trim().isNotEmpty
        ? nomPatient
            .trim()
            .split(' ')
            .where((e) => e.trim().isNotEmpty)
            .map((e) => e.trim()[0])
            .take(2)
            .join()
            .toUpperCase()
        : "PT";

    final groupeSanguin = dossier?.groupeSanguin ?? (_patientSelectionne?['groupeSanguin'] ?? "O+");
    final double poids = dossier?.poidsKg ?? ((_patientSelectionne?['poids'] as num?)?.toDouble() ?? 72.5);
    final double taille = dossier?.tailleCm ?? ((_patientSelectionne?['taille'] as num?)?.toDouble() ?? 178.0);

    // Calcul IMC
    final double tailleMetres = (taille > 0) ? (taille / 100.0) : 1.75;
    final double imc = (poids > 0 && tailleMetres > 0) ? (poids / (tailleMetres * tailleMetres)) : 22.5;
    String statutImc = "Normal";
    if (imc < 18.5) {
      statutImc = "Poids insuffisant";
    } else if (imc >= 25.0 && imc < 30.0) {
      statutImc = "Surpoids";
    } else if (imc >= 30.0) {
      statutImc = "Obésité";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D3142), size: 18),
          onPressed: () {
            if (isDoctor && widget.patientCible == null) {
              setState(() {
                _patientSelectionne = null;
                _voirMonPropreDossier = false;
              });
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          _voirMonPropreDossier
              ? "Mon Dossier Personnel"
              : (isFamilyMember
                  ? "Dossier de $nomPatient"
                  : (isDoctor ? "Dossier de $nomPatient" : "Mon Dossier Médical")),
          style: const TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF0D7C66)),
            tooltip: "Voir le Pass Santé",
            onPressed: () => context.push('/qr-scanner'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BANNIÈRE DE RETOUR MÉDECIN
                if (isDoctor && widget.patientCible == null && (_patientSelectionne != null || _voirMonPropreDossier)) ...[
                  InkWell(
                    onTap: () => setState(() {
                      _patientSelectionne = null;
                      _voirMonPropreDossier = false;
                    }),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F2F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back, size: 14, color: Color(0xFF0D7C66)),
                          const SizedBox(width: 6),
                          Text(
                            _voirMonPropreDossier
                                ? "Retourner à l'espace praticien (Mes Patients)"
                                : "Revenir au répertoire de mes patients",
                            style: const TextStyle(color: Color(0xFF0D7C66), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // CARTE PATIENT DYNAMIQUE
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: (isDoctor && !_voirMonPropreDossier)
                          ? [const Color(0xFF0D7C66), const Color(0xFF0D7C66)]
                          : [const Color(0xFF0D7C66), const Color(0xFF0D7C66)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D7C66).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white30, width: 2),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initiales,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nomPatient,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _voirMonPropreDossier
                                            ? "Praticien & Patient Diam-Yaraam • Dossier Personnel"
                                            : (isFamilyMember
                                                ? "Dossier Médical de Proche (${widget.patientCible?['lienParente'] ?? 'Famille'})"
                                                : (isDoctor ? "Patient suivi en consultation" : "ID : $idPatient • Profil Certifié")),
                                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bloodtype, color: Color(0xFFEF4444), size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  groupeSanguin,
                                  style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // BANDEAU CONSTANTES ET IMC
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text("Poids", style: TextStyle(color: Colors.white70, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text("${poids.toStringAsFixed(1)} kg", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            Container(width: 1, height: 24, color: Colors.white24),
                            Column(
                              children: [
                                const Text("Taille", style: TextStyle(color: Colors.white70, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text("${taille.toStringAsFixed(0)} cm", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                            Container(width: 1, height: 24, color: Colors.white24),
                            Column(
                              children: [
                                const Text("Indice IMC", style: TextStyle(color: Colors.white70, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  "${imc.toStringAsFixed(1)} ($statutImc)",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // BOUTON MODIFIER LES CONSTANTES
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () => _ouvrirModalModifierConstantes(groupeSanguin, poids, taille),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text("Mettre à jour les constantes", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (isFamilyMember) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      context.push('/doctors', extra: {
                        'id': idPatient,
                        'nom': nomPatient,
                        'prenom': widget.patientCible?['prenom'] ?? '',
                        'nomFamille': widget.patientCible?['nomFamille'] ?? '',
                        'lienParente': widget.patientCible?['lienParente'] ?? 'Famille',
                        'isFamilyMember': true,
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.3)),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7F2F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF0D7C66), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Prendre un rendez-vous pour $nomPatient",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3142)),
                                ),
                                const Text(
                                  "Trouver un praticien et réserver un créneau",
                                  style: TextStyle(fontSize: 11, color: Color(0xFF8D99AE)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF0D7C66)),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ONGLETS DYNAMIQUES
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _onglets.length,
                    itemBuilder: (context, index) {
                      final onglet = _onglets[index];
                      final estSelectionne = _indexOngletActuel == index;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _indexOngletActuel = index),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: estSelectionne ? const Color(0xFF0D7C66) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: estSelectionne ? const Color(0xFF0D7C66) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              onglet,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: estSelectionne ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // CONTENU DES ONGLETS
                Expanded(
                  child: dossierState.isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D7C66)))
                      : RefreshIndicator(
                          onRefresh: () async {
                            final pId = idPatient;
                            await ref.read(dossierProvider.notifier).loadDossier(patientId: pId);
                          },
                          color: const Color(0xFF0D7C66),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_indexOngletActuel == 0) _buildResumeTab(dossier),
                                if (_indexOngletActuel == 1) _buildConsultationsTab(dossier),
                                if (_indexOngletActuel == 2) _buildOrdonnancesTab(dossier),
                                if (_indexOngletActuel == 3) _buildAllergiesTab(dossier, isDoctor),
                                if (_indexOngletActuel == 4) _buildVaccinsTab(dossier),
                                if (_indexOngletActuel == 5) _buildAccesMedecinsTab(),
                              ],
                            ),
                          ),
                        ),
                ),

                // BOUTONS D'ACTIONS RAPIDES (RÉSERVÉS AU MÉDECIN)
                const SizedBox(height: 12),
                if (isDoctor)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/new-consultation', extra: {
                            'patient_id': idPatient,
                            'patient_nom': nomPatient,
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D7C66),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.add, color: Colors.white, size: 18),
                          label: const Text("Nouvelle consultation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/smart-prescription', extra: {
                            'patient_id': idPatient,
                            'patient_nom': nomPatient,
                            'groupe': groupeSanguin,
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D7C66),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                          label: const Text("Ordonnance IA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D7C66).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: Color(0xFF0D7C66), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Dossier médical certifié : Seul un médecin agréé est habilité à prescrire des ordonnances, consigner des diagnostics ou enregistrer des antécédents médicaux.",
                            style: TextStyle(fontSize: 11, color: Color(0xFF0D7C66), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumeTab(dynamic dossier) {
    final consultations = (dossier?.consultations as List<ConsultationModel>?) ?? [];
    final allergies = (dossier?.allergies as List<AllergieModel>?) ?? [];
    final prescriptions = (dossier?.prescriptions as List<PrescriptionModel>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (allergies.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Alerte Allergies & Contre-indications", style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        allergies.map((a) => "${a.nomAllergene} (${a.severite})").join(' • '),
                        style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text("Dernière Consultation", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        if (consultations.isNotEmpty) ...[
          _buildConsultationCard(consultations.first),
        ] else ...[
          _buildEmptyState("Aucune consultation enregistrée"),
        ],
        const SizedBox(height: 16),
        const Text("Dernière Ordonnance Médicale", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        if (prescriptions.isNotEmpty) ...[
          _buildPrescriptionCard(prescriptions.first),
        ] else ...[
          _buildEmptyState("Aucune ordonnance récente"),
        ],
      ],
    );
  }

  Widget _buildConsultationsTab(dynamic dossier) {
    final consultations = (dossier?.consultations as List<ConsultationModel>?) ?? [];
    if (consultations.isEmpty) return _buildEmptyState("Aucune consultation dans l'historique");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${consultations.length} consultation(s) enregistrée(s)", style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...consultations.map((c) => _buildConsultationCard(c)),
      ],
    );
  }

  Widget _buildOrdonnancesTab(dynamic dossier) {
    final prescriptions = (dossier?.prescriptions as List<PrescriptionModel>?) ?? [];
    if (prescriptions.isEmpty) return _buildEmptyState("Aucune prescription disponible");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${prescriptions.length} ordonnance(s) sécurisée(s)", style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...prescriptions.map((p) => _buildPrescriptionCard(p)),
      ],
    );
  }

  Widget _buildAllergiesTab(dynamic dossier, bool isDoctor) {
    final allergies = (dossier?.allergies as List<AllergieModel>?) ?? [];
    final antecedents = (dossier?.antecedents as List<AntecedentModel>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Allergies Connues", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            if (isDoctor)
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF0D7C66), size: 22),
                tooltip: "Ajouter une allergie",
                onPressed: _ouvrirModalAjouterAllergie,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (allergies.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergies.map((a) {
              final isSevere = a.severite == 'SEVERE';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSevere ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSevere ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: isSevere ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Text("${a.nomAllergene} (${a.severite})", style: TextStyle(color: isSevere ? const Color(0xFFDC2626) : const Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ),
        ] else ...[
          _buildEmptyState("Aucune allergie renseignée"),
        ],
        const SizedBox(height: 20),
        const Text("Antécédents Médicaux & Chirurgicaux", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 10),
        if (antecedents.isNotEmpty) ...[
          ...antecedents.map((ant) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F2F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.history_edu_rounded, color: Color(0xFF0D7C66), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ant.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                        Text("Type: ${ant.typeAntecedent} • Année/Date: ${ant.dateEvenement ?? 'Non précisée'}", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ] else ...[
          _buildEmptyState("Aucun antécédent répertorié"),
        ],
      ],
    );
  }

  Widget _buildVaccinsTab(dynamic dossier) {
    final vaccins = (dossier?.vaccinations as List<VaccinationModel>?) ?? [];
    if (vaccins.isEmpty) return _buildEmptyState("Aucun vaccin renseigné");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Calendrier Vaccinal & Rappels", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 10),
        ...vaccins.map((v) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F2F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.vaccines_rounded, color: Color(0xFF0D7C66), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.nomVaccin, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                      Text("Administré le : ${v.dateAdministration.day}/${v.dateAdministration.month}/${v.dateAdministration.year}", style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      if (v.dateRappel != null)
                        Text("Prochain rappel : ${v.dateRappel!.day}/${v.dateRappel!.month}/${v.dateRappel!.year}", style: const TextStyle(fontSize: 11, color: Color(0xFF0D7C66), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F2F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("À jour ✔", style: TextStyle(color: Color(0xFF0D7C66), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildConsultationCard(ConsultationModel c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F2F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${c.dateConsultation.day}/${c.dateConsultation.month}/${c.dateConsultation.year}",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D7C66)),
                ),
              ),
              Text(
                c.medecinNom ?? "Dr. Praticien Agréé",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(c.motif, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          if (c.diagnostic != null && c.diagnostic!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
              child: Text("Diagnostic : ${c.diagnostic}", style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(PrescriptionModel p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ordonnance du ${p.datePrescription.day}/${p.datePrescription.month}/${p.datePrescription.year}",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const Icon(Icons.verified, color: Color(0xFF0D7C66), size: 16),
            ],
          ),
          const SizedBox(height: 6),
          ...p.lignes.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Color(0xFF0D7C66)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${l.medicament} (${l.dosage}) • ${l.posologie}",
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.folder_open_rounded, size: 36, color: Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAccesMedecinsTab() {
    final consentState = ref.watch(consentProvider);
    final medecins = consentState.medecins;
    final totalAutorises = medecins.where((m) => m.estAutorise).length;
    
    final user = ref.watch(authProvider).user;
    final isDoctor = user?.isMedecin == true || user?.role == 'MEDECIN';
    final canManageAccess = !isDoctor || _voirMonPropreDossier;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BANDEAU EXPLICATIF DE CONFIDENTIALITÉ ET POUVOIR DU PATIENT
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE7F2F0), Color(0xFFE7F2F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D7C66),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Consentement & Sécurité du Dossier",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Vous contrôlez à tout instant l'accès de chaque praticien.",
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D7C66).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "$totalAutorises / ${medecins.length} Actif(s)",
                      style: const TextStyle(
                        color: Color(0xFF0D7C66),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "Règle de protection : Un médecin peut scanner votre Pass Vital uniquement si vous lui accordez l'accès. S'il est révoqué, votre dossier complet reste scellé et seules vos données d'urgence vitale (Groupe sanguin, allergies) sont consultables.",
                style: TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // EN-TÊTE SECTION MÉDECINS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Praticiens Autorisés & Révoqués",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            if (canManageAccess)
              TextButton.icon(
                onPressed: () => _ouvrirModalDemanderAcces(),
                icon: const Icon(Icons.person_add_alt_1, size: 16, color: Color(0xFF0D7C66)),
                label: const Text(
                  "Ajouter",
                  style: TextStyle(color: Color(0xFF0D7C66), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        if (medecins.isEmpty)
          _buildEmptyState("Aucun praticien répertorié pour le moment.")
        else
          ...medecins.map((med) => _buildMedecinConsentCard(med, canManageAccess: canManageAccess)),
      ],
    );
  }

  Widget _buildMedecinConsentCard(MedecinConsentModel med, {bool canManageAccess = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: med.estAutorise ? const Color(0xFF0D7C66).withValues(alpha: 0.35) : const Color(0xFFEF4444).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: med.estAutorise ? const Color(0xFFE7F2F0) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  med.estAutorise ? Icons.medical_services_rounded : Icons.person_off_rounded,
                  color: med.estAutorise ? const Color(0xFF0D7C66) : const Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            med.nom,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1E293B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: med.estAutorise ? const Color(0xFFE7F2F0) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: med.estAutorise ? const Color(0xFF0D7C66) : const Color(0xFFEF4444),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                med.estAutorise ? Icons.check_circle : Icons.cancel,
                                size: 11,
                                color: med.estAutorise ? const Color(0xFF0D7C66) : const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                med.estAutorise ? "ACCÈS AUTORISÉ" : "ACCÈS RÉVOQUÉ",
                                style: TextStyle(
                                  color: med.estAutorise ? const Color(0xFF0D7C66) : const Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      med.specialite,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.local_hospital_outlined, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "${med.hopital} • ${med.telephone}",
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // MOTIF & ACTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  med.motif ?? (med.estAutorise ? "Autorisation active" : "Accès révoqué"),
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: med.estAutorise ? const Color(0xFF475569) : const Color(0xFFDC2626),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canManageAccess) ...[
                const SizedBox(width: 8),
                if (med.estAutorise)
                  OutlinedButton.icon(
                    onPressed: () => _confirmerRevocation(med),
                    icon: const Icon(Icons.lock_outline, size: 14, color: Color(0xFFEF4444)),
                    label: const Text("Révoquer", style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(consentProvider.notifier).accorderAcces(med.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Accès au dossier médical accordé au ${med.nom}"),
                          backgroundColor: const Color(0xFF0D7C66),
                        ),
                      );
                    },
                    icon: const Icon(Icons.lock_open_rounded, size: 14, color: Colors.white),
                    label: const Text("Accorder l'Accès", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D7C66),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _confirmerRevocation(MedecinConsentModel med) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "Révoquer l'accès ?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          "Voulez-vous retirer l'accès à votre dossier médical complet pour ${med.nom} ?\n\nEn cas de scan par ce médecin, votre dossier restera verrouillé et un avertissement d'urgence lui sera présenté.",
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler", style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(consentProvider.notifier).revoquerAcces(med.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Accès révoqué pour ${med.nom}. Dossier scellé."),
                  backgroundColor: const Color(0xFFEF4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Confirmer la révocation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _ouvrirModalDemanderAcces() {
    final nomCtrl = TextEditingController();
    final hopitalCtrl = TextEditingController();
    final specCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          top: 24,
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
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            const Text("Autoriser un Nouveau Médecin", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 4),
            const Text("Accordez les droits de consultation de votre dossier médical à un praticien certifié.", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            TextField(
              controller: nomCtrl,
              decoration: InputDecoration(
                labelText: "Nom du Médecin (ex: Dr. Amadou Kane)",
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: specCtrl,
              decoration: InputDecoration(
                labelText: "Spécialité (ex: Pédiatrie, Dermatologie)",
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hopitalCtrl,
              decoration: InputDecoration(
                labelText: "Hôpital / Clinique (ex: Hôpital Dantec)",
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (nomCtrl.text.trim().isEmpty) return;
                  final nouveauMed = MedecinConsentModel(
                    id: 'med-${DateTime.now().millisecondsSinceEpoch}',
                    nom: nomCtrl.text.trim(),
                    specialite: specCtrl.text.trim().isNotEmpty ? specCtrl.text.trim() : "Médecine Générale",
                    hopital: hopitalCtrl.text.trim().isNotEmpty ? hopitalCtrl.text.trim() : "Cabinet Médical",
                    telephone: "+221 77 000 00 00",
                    estAutorise: true,
                    dateModification: DateTime.now(),
                    motif: "Autorisation accordée par le patient",
                  );
                  ref.read(consentProvider.notifier).ajouterMedecin(nouveauMed);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Accès accordé au ${nomCtrl.text.trim()} !"),
                      backgroundColor: const Color(0xFF0D7C66),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D7C66),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Valider l'autorisation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
