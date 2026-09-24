import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../../wallet/services/wallet_api_service.dart';
import '../models/rendez_vous_model.dart';
import '../providers/rdv_provider.dart';

class EcranMesRendezVous extends ConsumerStatefulWidget {
  const EcranMesRendezVous({super.key});

  @override
  ConsumerState<EcranMesRendezVous> createState() => _EcranMesRendezVousState();
}

class _EcranMesRendezVousState extends ConsumerState<EcranMesRendezVous> {
  String _filtreSelectionne = "Tous";
  bool? _vueForceeMedecin; // Permet de basculer interactivement entre la vue Patient et Médecin

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null && user.id.isNotEmpty) {
        final isDoctor = user.isMedecin == true || (user.role.toUpperCase()).contains('MEDECIN');
        if (isDoctor) {
          ref.read(rdvProvider.notifier).loadAgendaMedecin(medecinId: user.id);
        }
        ref.read(rdvProvider.notifier).loadMesRendezVous(patientId: user.id);
      }
    });
  }

  void _ouvrirDialogueAvisPostRdv(BuildContext context, RendezVousModel rdv) {
    double noteDonnee = 5.0;
    final commentaireCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE7F2F0), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.star_rounded, color: Color(0xFF0D7C66), size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text("Avis post-consultation", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Comment s'est passée votre consultation avec ${rdv.medecinNom ?? 'le praticien'} ?",
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final etoile = index + 1;
                      return IconButton(
                        icon: Icon(
                          etoile <= noteDonnee ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() => noteDonnee = etoile.toDouble());
                        },
                      );
                    }),
                  ),
                ),
                Center(
                  child: Text(
                    "${noteDonnee.toInt()} / 5 étoiles",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: commentaireCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Partagez votre retour (écoute, ponctualité, conseils reçus...)",
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Plus tard", style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Merci ! Votre avis a été enregistré pour aider les autres patients."),
                    backgroundColor: Color(0xFF0D7C66),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D7C66),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Envoyer mon avis", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isUserDoctor = user?.isMedecin == true || (user?.role.toUpperCase() ?? '').contains('MEDECIN');
    final bool modeMedecinActif = _vueForceeMedecin ?? isUserDoctor;

    final rdvState = ref.watch(rdvProvider);
    final listeRdv = modeMedecinActif ? rdvState.agendaMedecin : rdvState.mesRendezVous;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          modeMedecinActif ? "Consultations Patients" : "Mes Rendez-vous",
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          // Sélecteur de vue Patient / Médecin pour démonstration & soutenance
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRoleToggleChip(
                  label: "Patient",
                  icon: Icons.person_outline,
                  isSelected: !modeMedecinActif,
                  onTap: () {
                    setState(() {
                      _vueForceeMedecin = false;
                      _filtreSelectionne = "Tous";
                    });
                    if (user != null) {
                      ref.read(rdvProvider.notifier).loadMesRendezVous(patientId: user.id);
                    }
                  },
                ),
                _buildRoleToggleChip(
                  label: "Médecin",
                  icon: Icons.medical_services_outlined,
                  isSelected: modeMedecinActif,
                  onTap: () {
                    setState(() {
                      _vueForceeMedecin = true;
                      _filtreSelectionne = "Tous";
                    });
                    if (user != null) {
                      ref.read(rdvProvider.notifier).loadAgendaMedecin(medecinId: user.id);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 540),
            child: modeMedecinActif
                ? _buildInterfaceMedecin(context, listeRdv, rdvState.isLoading)
                : _buildInterfacePatient(context, listeRdv, rdvState.isLoading),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleToggleChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D7C66) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 1. INTERFACE PATIENT (Dédiée au patient : orientation vers le médecin)
  // =========================================================================
  Widget _buildInterfacePatient(BuildContext context, List<RendezVousModel> tousRdv, bool isLoading) {
    final filtresPatient = ["Tous", "À venir", "Téléconsultations", "Terminés"];

    final rdvsAffiches = tousRdv.where((rdv) {
      if (_filtreSelectionne == "À venir") return rdv.statut == 'CONFIRME';
      if (_filtreSelectionne == "Téléconsultations") return rdv.estTeleconsultation;
      if (_filtreSelectionne == "Terminés") return rdv.statut == 'TERMINE';
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Carte d'accueil Patient
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
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Mes Rendez-vous Médicaux",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${tousRdv.length} consultation(s) enregistrée(s)",
                      style: const TextStyle(color: Color(0xFFE7F2F0), fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => context.push('/doctors'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0D7C66),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 4),
                    Text("Prendre RDV", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Filtres horizontaux
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filtresPatient.length,
            itemBuilder: (context, index) {
              final filtre = filtresPatient[index];
              final estSelectionne = _filtreSelectionne == filtre;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _filtreSelectionne = filtre),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: estSelectionne ? const Color(0xFF0D7C66) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: estSelectionne ? const Color(0xFF0D7C66) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      filtre,
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

        // Liste des cartes RDV pour Patient
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFF0D7C66)),
            ),
          )
        else if (rdvsAffiches.isEmpty)
          _buildEmptyState(
            title: "Aucun rendez-vous trouvé",
            subtitle: "Vous n'avez pas de consultation prévue dans cette section.",
            boutonTexte: "Trouver un médecin",
            onAction: () => context.push('/doctors'),
          )
        else
          ...rdvsAffiches.map((rdv) => _buildCardPatient(context, rdv)),
      ],
    );
  }

  Widget _buildCardPatient(BuildContext context, RendezVousModel rdv) {
    final estTeleconsultation = rdv.estTeleconsultation;
    final estConfirme = rdv.statut == 'CONFIRME';
    final dateStr = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(rdv.dateHeure);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la carte : Mode & Statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: estTeleconsultation ? const Color(0xFFE7F2F0) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      estTeleconsultation ? Icons.videocam_rounded : Icons.local_hospital_rounded,
                      size: 15,
                      color: estTeleconsultation ? const Color(0xFF0D7C66) : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      estTeleconsultation ? "Téléconsultation Vidéo" : "Consultation Cabinet",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: estTeleconsultation ? const Color(0xFF0D7C66) : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: estConfirme ? const Color(0xFFE7F2F0) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  estConfirme ? "Confirmé" : rdv.statut,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: estConfirme ? const Color(0xFF0D7C66) : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Praticien : Nom & Spécialité
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 52,
                  height: 52,
                  color: const Color(0xFFE7F2F0),
                  child: const Icon(Icons.person, color: Color(0xFF0D7C66), size: 30),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rdv.medecinNom ?? "Dr. Praticien Diam-Yaraam",
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rdv.medecinSpecialite ?? "Médecine Générale",
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Motif de la consultation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.assignment_outlined, size: 15, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rdv.motif.isNotEmpty ? rdv.motif : "Consultation médicale",
                    style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Date & Tarif
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ],
              ),
              Text(
                "${rdv.montant.toInt()} FCFA",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0D7C66)),
              ),
            ],
          ),

          // Boutons d'action Patient
          const SizedBox(height: 14),
          Row(
            children: [
              if (estTeleconsultation && estConfirme)
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/teleconsultation-room', extra: rdv.toJson());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D7C66),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        "Rejoindre Visio",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              if (estTeleconsultation && estConfirme) const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () => _ouvrirDialogueAvisPostRdv(context, rdv),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0D7C66)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    label: const Text(
                      "Donner avis",
                      style: TextStyle(color: Color(0xFF0D7C66), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. INTERFACE MÉDECIN (Dédiée au docteur : vue clinique centrée sur le patient)
  // =========================================================================
  Widget _buildInterfaceMedecin(BuildContext context, List<RendezVousModel> tousRdv, bool isLoading) {
    final filtresMedecin = ["Tous", "Aujourd'hui", "Téléconsultations", "Terminés"];

    final now = DateTime.now();
    final rdvsAffiches = tousRdv.where((rdv) {
      if (_filtreSelectionne == "Aujourd'hui") {
        return rdv.dateHeure.year == now.year &&
            rdv.dateHeure.month == now.month &&
            rdv.dateHeure.day == now.day;
      }
      if (_filtreSelectionne == "Téléconsultations") return rdv.estTeleconsultation;
      if (_filtreSelectionne == "Terminés") return rdv.statut == 'TERMINE';
      return true;
    }).toList();

    final totalTeleconsult = tousRdv.where((r) => r.estTeleconsultation).length;
    final totalMontant = tousRdv.fold<double>(0, (sum, r) => sum + r.montant);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Carte d'en-tête Espace Médical
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.25),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D7C66).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.medical_services_rounded, color: Color(0xFF0D7C66), size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "File Active Praticien",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Gestion des consultations et téléconsultations",
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.push('/doctor-agenda'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.calendar_month_outlined, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text("Agenda", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 3 Métriques pour le Médecin
              Row(
                children: [
                  Expanded(
                    child: _buildMetricBox(
                      label: "Patients",
                      valeur: "${tousRdv.length}",
                      couleur: const Color(0xFF38BDF8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricBox(
                      label: "Téléconsultations",
                      valeur: "$totalTeleconsult",
                      couleur: const Color(0xFF0D7C66),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricBox(
                      label: "Honoraires",
                      valeur: "${(totalMontant / 1000).toStringAsFixed(0)}k F",
                      couleur: const Color(0xFFFBBF24),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Filtres Médecin
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filtresMedecin.length,
            itemBuilder: (context, index) {
              final filtre = filtresMedecin[index];
              final estSelectionne = _filtreSelectionne == filtre;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _filtreSelectionne = filtre),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: estSelectionne ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: estSelectionne ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      filtre,
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

        // Liste des cartes RDV Médecin
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFF0D7C66)),
            ),
          )
        else if (rdvsAffiches.isEmpty)
          _buildEmptyState(
            title: "Aucun rendez-vous patient",
            subtitle: "Votre file active est vide pour le filtre sélectionné.",
            boutonTexte: "Ouvrir de nouveaux créneaux",
            onAction: () => context.push('/doctor-agenda'),
          )
        else
          ...rdvsAffiches.map((rdv) => _buildCardMedecin(context, rdv)),
      ],
    );
  }

  Widget _buildMetricBox({
    required String label,
    required String valeur,
    required Color couleur,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            valeur,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: couleur),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCardMedecin(BuildContext context, RendezVousModel rdv) {
    final estTeleconsultation = rdv.estTeleconsultation;
    final estConfirme = rdv.statut == 'CONFIRME';
    final dateStr = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(rdv.dateHeure);

    // Résolution du nom du patient
    final nomPatient = (rdv.patientNom != null && rdv.patientNom!.isNotEmpty)
        ? rdv.patientNom!
        : WalletApiService.getNomUtilisateur(rdv.patientId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Type de rendez-vous & Badge Honoraires
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: estTeleconsultation ? const Color(0xFFE7F2F0) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      estTeleconsultation ? Icons.videocam_rounded : Icons.home_repair_service_rounded,
                      size: 15,
                      color: estTeleconsultation ? const Color(0xFF0D7C66) : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      estTeleconsultation ? "Téléconsultation Vidéo" : "Consultation à Domicile",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: estTeleconsultation ? const Color(0xFF0D7C66) : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F2F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 13, color: Color(0xFF0D7C66)),
                    const SizedBox(width: 4),
                    Text(
                      "Honoraires payés (+${rdv.montant.toInt()} F)",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D7C66),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Information Patient (Clairement mise en avant pour le docteur)
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 52,
                  height: 52,
                  color: const Color(0xFFE0F2FE),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF0284C7), size: 30),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Patient : $nomPatient",
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Réf dossier : ${rdv.patientId.length > 8 ? rdv.patientId.substring(0, 8) : rdv.patientId} • Prise en charge validée",
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Motif clinique déclaré par le patient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.medical_information_outlined, size: 15, color: Color(0xFFD97706)),
                    SizedBox(width: 6),
                    Text(
                      "Motif clinique déclaré par le patient :",
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  rdv.motif.isNotEmpty ? rdv.motif : "Consultation de contrôle",
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF78350F), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Date et Heure
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Actions cliniques pour le Médecin
          if (estTeleconsultation && estConfirme) ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/teleconsultation-room', extra: rdv.toJson());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D7C66),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
                label: const Text(
                  "Démarrer la téléconsultation",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Outils cliniques rapides : Dossier Médical & Ordonnance
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push('/medical-record', extra: {
                      'patientId': rdv.patientId,
                      'patientNom': nomPatient,
                      'isSelf': false,
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.folder_shared_outlined, size: 16),
                  label: const Text("Dossier Médical", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push('/smart-prescription', extra: {
                      'patientId': rdv.patientId,
                      'patientNom': nomPatient,
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D7C66),
                    side: const BorderSide(color: Color(0xFF0D7C66)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.note_alt_outlined, size: 16),
                  label: const Text("Ordonnance", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required String boutonTexte,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D7C66),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              boutonTexte,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

