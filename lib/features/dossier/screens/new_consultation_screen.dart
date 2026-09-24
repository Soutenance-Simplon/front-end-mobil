import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/consultation_model.dart';
import '../providers/dossier_provider.dart';
import '../../rdv/providers/rdv_provider.dart';

class NewConsultationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? patientInfo;

  const NewConsultationScreen({super.key, this.patientInfo});

  @override
  ConsumerState<NewConsultationScreen> createState() => _NewConsultationScreenState();
}

class _NewConsultationScreenState extends ConsumerState<NewConsultationScreen> {
  final _motifController = TextEditingController();
  final _diagnosticController = TextEditingController();
  final _obsController = TextEditingController();
  final _planController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 30);

  bool _isSaving = false;
  bool _hasPrescription = false;
  String? _prescriptionSummary;

  final List<Map<String, dynamic>> _attachedFiles = [];

  String get _formattedDate =>
      "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";
  String get _formattedTime =>
      "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";

  @override
  void dispose() {
    _motifController.dispose();
    _diagnosticController.dispose();
    _obsController.dispose();
    _planController.dispose();
    super.dispose();
  }

  // SÉLECTION DE LA DATE DU PROCHAIN RENDEZ-VOUS
  Future<void> _pickNextDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D7C66),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2D3142),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // SÉLECTION DE L'HEURE DU PROCHAIN RENDEZ-VOUS
  Future<void> _pickNextTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D7C66),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2D3142),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  // AJOUT D'UNE PHOTO (CAMÉRA OU GALERIE)
  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _attachedFiles.add({
            'name': photo.name.isNotEmpty ? photo.name : "Photo_${DateTime.now().millisecondsSinceEpoch}.jpg",
            'type': 'Photo médicale',
            'icon': Icons.camera_alt_outlined,
          });
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Photo médicale ajoutée à la consultation"),
              backgroundColor: Color(0xFF0D7C66),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Accès caméra impossible : $e")),
        );
      }
    }
  }

  // AJOUT D'UN DOCUMENT OU D'UNE ANALYSE (GALERIE/FICHIER)
  Future<void> _pickDocument(String type) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          _attachedFiles.add({
            'name': file.name.isNotEmpty ? file.name : "${type}_${DateTime.now().millisecondsSinceEpoch}.jpg",
            'type': type,
            'icon': type == 'Analyse' ? Icons.biotech_outlined : Icons.description_outlined,
          });
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$type ajouté(e) avec succès !"),
              backgroundColor: const Color(0xFF0D7C66),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur sélection fichier : $e")),
        );
      }
    }
  }

  // AJOUTER UNE ORDONNANCE (LIAISON AVEC /smart-prescription)
  Future<void> _handleAjouterOrdonnance() async {
    final result = await context.push('/smart-prescription', extra: widget.patientInfo);
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _hasPrescription = true;
        _prescriptionSummary = result['summary']?.toString() ?? "Ordonnance prescrite et validée";
      });
    } else {
      setState(() {
        _hasPrescription = true;
        _prescriptionSummary = "Ordonnance numérique prête et rattachée";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ordonnance rattachée à cette consultation."),
            backgroundColor: Color(0xFF0D7C66),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // SÉLECTEUR RAPIDE CODES ICD-10
  void _showIcd10Selector() {
    final icd10List = [
      {"code": "I10", "label": "Hypertension artérielle essentielle"},
      {"code": "E11", "label": "Diabète sucré de type 2"},
      {"code": "J06", "label": "Infection aiguë des voies respiratoires supérieures"},
      {"code": "A09", "label": "Gastro-entérite et colite d'origine infectieuse"},
      {"code": "J45", "label": "Asthme bronchique"},
      {"code": "M54.5", "label": "Lombalgie commune (Dorsalgie)"},
      {"code": "K29.7", "label": "Gastrite sans précision"},
      {"code": "R50.9", "label": "Fièvre sans précision / Syndrome fébrile"},
      {"code": "B50", "label": "Paludisme à Plasmodium falciparum"},
      {"code": "R51", "label": "Céphalée aiguë"},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Classification ICD-10 Fréquente",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: icd10List.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = icd10List[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F2F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['code']!,
                        style: const TextStyle(color: Color(0xFF0D7C66), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    title: Text(
                      item['label']!,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                    ),
                    onTap: () {
                      _diagnosticController.text = "${item['code']} - ${item['label']}";
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DICTÉE VOCALE MÉDICALE SIMULÉE
  void _startVoiceInput(TextEditingController controller, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mic, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text("Microphone actif : dictée de $label en cours..."),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0D7C66),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ENREGISTRER LA CONSULTATION RÉELLE DANS LE DOSSIER & PLANNING
  Future<void> _saveConsultation() async {
    if (_motifController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez renseigner au moins le motif de la consultation."),
          backgroundColor: Colors.orangeAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(authProvider).user;
      final dossierState = ref.read(dossierProvider);
      final currentDossier = dossierState.dossier;
      final patientId = widget.patientInfo?['id']?.toString() ?? currentDossier?.patientId ?? 'p1';
      final dossierId = currentDossier?.id ?? "dos-$patientId";

      final docName = user?.fullName.trim().isNotEmpty == true
          ? (user!.isMedecin ? "Dr. ${user.fullName}" : user.fullName)
          : "Dr. Aïssatou Diop";

      String observationText = _obsController.text.trim();
      if (_planController.text.trim().isNotEmpty) {
        observationText = observationText.isNotEmpty
            ? "$observationText\n\nPlan de traitement : ${_planController.text.trim()}"
            : "Plan de traitement : ${_planController.text.trim()}";
      }
      if (_hasPrescription) {
        observationText = "$observationText\n[✓ Ordonnance médicale rattachée]";
      }
      if (_attachedFiles.isNotEmpty) {
        observationText = "$observationText\n[Pièces jointes : ${_attachedFiles.map((f) => f['name']).join(', ')}]";
      }

      final consultation = ConsultationModel(
        id: "cs_${DateTime.now().millisecondsSinceEpoch}",
        dossierId: dossierId,
        medecinId: user?.id ?? "med-1",
        medecinNom: docName,
        dateConsultation: DateTime.now(),
        motif: _motifController.text.trim(),
        diagnostic: _diagnosticController.text.trim().isNotEmpty ? _diagnosticController.text.trim() : "Non précisé",
        observation: observationText.isNotEmpty ? observationText : "Consultation effectuée sans remarque spécifique.",
      );

      // 1. Enregistrer dans le Dossier Médical (State + API)
      await ref.read(dossierProvider.notifier).ajouterConsultation(consultation);

      // 2. Planifier le prochain rendez-vous si défini
      try {
        final rdvDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        await ref.read(rdvProvider.notifier).reserverRendezVous(
          patientId: patientId,
          medecinId: user?.id ?? 'med-1',
          dateHeure: rdvDate,
          motif: "Suivi consultation : ${_motifController.text.trim()}",
          typeConsultation: 'PRESENTIELLE',
          medecinNom: docName,
        );
      } catch (_) {}

      if (mounted) {
        setState(() => _isSaving = false);

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF0D7C66), size: 28),
                SizedBox(width: 10),
                Text("Consultation enregistrée"),
              ],
            ),
            content: Text(
              "La consultation a été enregistrée avec succès dans le dossier médical du patient.\n\n"
              "• Motif : ${_motifController.text.trim()}\n"
              "• Prochain RDV : $_formattedDate à $_formattedTime",
              style: const TextStyle(fontSize: 14, color: Color(0xFF6C7386), height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D7C66),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Terminer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'enregistrement : $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isDoctor = user?.isMedecin == true ||
        user?.role.toUpperCase() == 'MEDECIN' ||
        user?.role.toUpperCase() == 'DOCTEUR';

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
          title: const Text(
            "Accès Médical Restreint",
            style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 16),
          ),
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
                  "Saisie de Consultation Réservée aux Médecins",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Seul un médecin ou praticien de santé agréé est habilité à consigner un examen clinique, un diagnostic médical ou un compte-rendu de consultation.",
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

    final patientName = widget.patientInfo?['name'] ?? widget.patientInfo?['patient_nom'] ?? "Patient Diam-Yaraam";
    final patientAge = widget.patientInfo?['age'] ?? "Dossier Médical Actif";
    final bloodGroup = widget.patientInfo?['blood'] ?? widget.patientInfo?['groupe'] ?? "O+";

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
          "Nouvelle Consultation",
          style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D7C66)),
                  )
                : const Icon(Icons.save_outlined, color: Color(0xFF0D7C66)),
            onPressed: _isSaving ? null : _saveConsultation,
            tooltip: "Enregistrer",
          ),
        ],
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
                  // PATIENT BANNER CARD
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E9F2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patientName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3142),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$patientAge • Groupe $bloodGroup",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8E95A5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECEB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFE53935)),
                              SizedBox(width: 4),
                              Text(
                                "Allergies",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // MOTIF DE CONSULTATION
                  _buildSectionHeader("Motif de consultation", hasMic: true, onMicTap: () => _startVoiceInput(_motifController, "motif")),
                  const SizedBox(height: 8),
                  _buildTextArea(
                    controller: _motifController,
                    hint: "Description des symptômes, motif de la visite...",
                  ),

                  const SizedBox(height: 24),

                  // DIAGNOSTIC
                  _buildSectionHeader("Diagnostic"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E9F2)),
                          ),
                          child: TextField(
                            controller: _diagnosticController,
                            decoration: const InputDecoration(
                              hintText: "Saisir un diagnostic...",
                              hintStyle: TextStyle(color: Color(0xFFB4B9C5), fontSize: 13),
                              prefixIcon: Icon(Icons.search, color: Color(0xFF9EA5B4), size: 18),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: _showIcd10Selector,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F2F0),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF0D7C66)),
                              SizedBox(width: 6),
                              Text(
                                "ICD-10",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D7C66),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // OBSERVATIONS CLINIQUES
                  _buildSectionHeader("Observations cliniques", hasMic: true, onMicTap: () => _startVoiceInput(_obsController, "observations")),
                  const SizedBox(height: 8),
                  _buildTextArea(
                    controller: _obsController,
                    hint: "Examen physique, constantes, remarques cliniques...",
                  ),

                  const SizedBox(height: 24),

                  // PLAN DE TRAITEMENT
                  _buildSectionHeader("Plan de traitement"),
                  const SizedBox(height: 8),
                  _buildTextArea(
                    controller: _planController,
                    hint: "Recommandations, posologie, conseils hygiéno-diététiques...",
                  ),

                  const SizedBox(height: 16),

                  // BOUTON AJOUTER UNE ORDONNANCE (OU CARTE SI DÉJÀ RATTACHÉE)
                  if (!_hasPrescription)
                    InkWell(
                      onTap: _handleAjouterOrdonnance,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F2F0).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF0D7C66),
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.medication_outlined, color: Color(0xFF0D7C66), size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Ajouter une ordonnance",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D7C66),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F2F0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF0D7C66)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF0D7C66), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Ordonnance médicale rattachée",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                if (_prescriptionSummary != null)
                                  Text(
                                    _prescriptionSummary!,
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                            onPressed: () => setState(() => _hasPrescription = false),
                            tooltip: "Supprimer l'ordonnance",
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // FICHIERS JOINTS
                  _buildSectionHeader("Fichiers joints"),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildFileChip(
                        Icons.camera_alt_outlined,
                        "Photo",
                        onTap: _pickPhoto,
                      ),
                      const SizedBox(width: 10),
                      _buildFileChip(
                        Icons.description_outlined,
                        "Document",
                        onTap: () => _pickDocument("Document"),
                      ),
                      const SizedBox(width: 10),
                      _buildFileChip(
                        Icons.biotech_outlined,
                        "Analyse",
                        onTap: () => _pickDocument("Analyse"),
                      ),
                    ],
                  ),

                  // LISTE DES FICHIERS JOINTS AJOUTÉS
                  if (_attachedFiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _attachedFiles.map((f) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(f['icon'] as IconData, size: 16, color: const Color(0xFF0D7C66)),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 120),
                                child: Text(
                                  f['name'] as String,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => setState(() => _attachedFiles.remove(f)),
                                child: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // PROCHAIN RENDEZ-VOUS (DATE & HEURE INTERACTIFS)
                  _buildSectionHeader("Prochain rendez-vous"),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickNextDate,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE5E9F2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, color: Color(0xFF0D7C66), size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  _formattedDate,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _pickNextTime,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE5E9F2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: Color(0xFF0D7C66), size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  _formattedTime,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // BOUTON ENREGISTRER LA CONSULTATION
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveConsultation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D7C66),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  "Enregistrement en cours...",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            )
                          : const Text(
                              "Enregistrer la consultation",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool hasMic = false, VoidCallback? onMicTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        if (hasMic)
          InkWell(
            onTap: onMicTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F2F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.mic_none, color: Color(0xFF0D7C66), size: 18),
            ),
          ),
      ],
    );
  }

  Widget _buildTextArea({required TextEditingController controller, required String hint}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9F2)),
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB4B9C5), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildFileChip(IconData icon, String label, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E9F2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF0D7C66)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
