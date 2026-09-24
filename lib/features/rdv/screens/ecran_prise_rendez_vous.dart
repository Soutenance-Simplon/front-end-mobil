import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/planning_provider.dart';
import '../providers/rdv_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../medecin/models/creneau_model.dart';
import '../../profile/models/membre_famille_model.dart';
import '../../patient/services/patient_api_service.dart';
import '../../wallet/providers/wallet_provider.dart';

class EcranPriseRendezVous extends ConsumerStatefulWidget {
  final Map<String, dynamic> medecin;

  const EcranPriseRendezVous({super.key, required this.medecin});

  @override
  ConsumerState<EcranPriseRendezVous> createState() => _EcranPriseRendezVousState();
}

class _EcranPriseRendezVousState extends ConsumerState<EcranPriseRendezVous> {
  DateTime _dateSelectionnee = DateTime.now();
  late List<DateTime> _joursDisponibles;

  String _periodeSelectionnee = "Matin";
  CreneauModel? _creneauSelectionne;
  String _modeConsultationSelectionne = "TELECONSULTATION"; // TELECONSULTATION ou DOMICILE

  final TextEditingController _controleurAdresse = TextEditingController();
  final TextEditingController _controleurMotif = TextEditingController();

  List<MembreFamille> _membresFamille = [];
  MembreFamille? _membreSelectionne;

  @override
  void initState() {
    super.initState();
    // 1. Récupération de la date pré-sélectionnée depuis l'écran précédent
    if (widget.medecin['dateSelectionnee'] is DateTime) {
      _dateSelectionnee = widget.medecin['dateSelectionnee'] as DateTime;
    }
    // 2. Récupération du créneau pré-sélectionné
    if (widget.medecin['creneauSelectionne'] is CreneauModel) {
      _creneauSelectionne = widget.medecin['creneauSelectionne'] as CreneauModel;
    }
    // 3. Réglage de la période (Matinée ou Après-midi/Soir) selon le créneau
    if (widget.medecin['periode'] != null) {
      _periodeSelectionnee = widget.medecin['periode'].toString();
    } else if (_creneauSelectionne != null) {
      _periodeSelectionnee = _creneauSelectionne!.dateHeureDebut.hour >= 13 ? "Soir" : "Matin";
    }
    // 4. Mode de consultation
    if (widget.medecin['typeConsultation'] != null) {
      _modeConsultationSelectionne = widget.medecin['typeConsultation'].toString();
    }

    _calculerJoursSemaine();
    _chargerMembresFamille();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planningProvider.notifier).chargerCreneauxDuMedecin(_medecinId);
      final user = ref.read(authProvider).user;
      if (user != null && user.id.isNotEmpty) {
        ref.read(walletProvider.notifier).loadUserWallet(user.id);
      }
    });
  }

  void _chargerMembresFamille() async {
    final user = ref.read(authProvider).user;
    if (user != null && user.id.isNotEmpty) {
      try {
        final membres = await PatientApiService().getMembresFamille(user.id);
        if (mounted) {
          setState(() {
            _membresFamille = membres;
            final beneficiaire = widget.medecin['beneficiaire'] as Map<String, dynamic>?;
            final benefId = widget.medecin['beneficiaireId'] ?? beneficiaire?['id'] ?? beneficiaire?['enfantUserId'];
            if (benefId != null) {
              final match = membres.where((m) =>
                  m.enfantUserId == benefId.toString() ||
                  m.id == benefId.toString() ||
                  "${m.prenom} ${m.nom}".trim().toLowerCase() == beneficiaire?['nom']?.toString().trim().toLowerCase()
              ).toList();
              if (match.isNotEmpty) {
                _membreSelectionne = match.first;
              }
            }
          });
        }
      } catch (_) {}
    }
  }

  void _calculerJoursSemaine() {
    final now = DateTime.now();
    _joursDisponibles = List.generate(14, (index) => now.add(Duration(days: index)));
  }

  String get _medecinId {
    return widget.medecin['id']?.toString() ??
        widget.medecin['userId']?.toString() ??
        widget.medecin['user_id']?.toString() ??
        "med-1";
  }

  String get _medecinUserId {
    final uid = widget.medecin['user_id']?.toString() ?? widget.medecin['userId']?.toString();
    if (uid != null && uid.isNotEmpty && uid != "null") {
      return uid;
    }
    return widget.medecin['id']?.toString() ?? _medecinId;
  }

  @override
  void dispose() {
    _controleurAdresse.dispose();
    _controleurMotif.dispose();
    super.dispose();
  }

  void _geolocaliserPatient() {
    setState(() {
      _controleurAdresse.text = "Dakar, Sacré-Cœur 3, Villa N° 45B (Position GPS détectée)";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Position GPS actuelle ajoutée avec succès"),
        backgroundColor: Color(0xFF00A884),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmerPriseRendezVous() async {
    if (_creneauSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner un créneau disponible ouvert par le médecin."),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final estDomicile = _modeConsultationSelectionne == "DOMICILE";

    if (_controleurMotif.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez renseigner le motif de votre consultation médicale."),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (estDomicile && _controleurAdresse.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez renseigner votre adresse pour la visite à domicile."),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Informations du patient et utilisateur connecté
    final currentUser = ref.read(authProvider).user;
    final estPourMembre = _membreSelectionne != null;
    final patientCibleNom = estPourMembre
        ? "${_membreSelectionne!.prenom} ${_membreSelectionne!.nom}".trim()
        : (currentUser?.fullName.trim().isNotEmpty == true ? currentUser!.fullName.trim() : "Patient");
    final patientCibleId = estPourMembre
        ? (_membreSelectionne!.enfantUserId.trim().isNotEmpty
            ? _membreSelectionne!.enfantUserId.trim()
            : "FAM-${_membreSelectionne!.id}")
        : (currentUser?.id.isNotEmpty == true ? currentUser!.id : 'PAT-1');

    // Vérification du solde du Portefeuille Santé avant confirmation
    final double montantVal = estDomicile
        ? 20000.0
        : ((widget.medecin['tarifConsultation'] is num)
            ? (widget.medecin['tarifConsultation'] as num).toDouble()
            : 15000.0);

    final soldeDisponible = ref.read(walletProvider).portefeuille?.solde ?? 0.0;
    if (currentUser != null && soldeDisponible < montantVal) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFEF4444), size: 26),
              SizedBox(width: 8),
              Text("Solde insuffisant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Votre Portefeuille Santé dispose actuellement de ${soldeDisponible.toStringAsFixed(0)} FCFA.\nLe tarif de la consultation est de ${montantVal.toStringAsFixed(0)} FCFA.",
                style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142)),
              ),
              const SizedBox(height: 12),
              const Text(
                "Pour confirmer ce rendez-vous, veuillez recharger votre portefeuille via Wave / Orange Money :",
                style: TextStyle(fontSize: 12, color: Color(0xFF8E95A5)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler", style: TextStyle(color: Color(0xFF8E95A5))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(walletProvider.notifier).recharger(
                  montant: 50000,
                  moyenPaiement: 'WAVE',
                  numeroTelephone: currentUser.telephone.isNotEmpty ? currentUser.telephone : '770000000',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Portefeuille Santé rechargé (+50 000 FCFA Wave). Vous pouvez confirmer votre rendez-vous."),
                      backgroundColor: Color(0xFF00A884),
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A884),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Recharger (+50 000 F)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    // CONTRÔLE DE DÉLAI : Un rendez-vous doit être pris au moins 30 minutes à l'avance
    if (_creneauSelectionne!.dateHeureDebut.isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text("Un rendez-vous doit être pris au moins 30 minutes à l'avance.")),
            ],
          ),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Réserver le créneau dans le planning global pour qu'il ne soit plus disponible
    ref.read(planningProvider.notifier).reserverCreneau(creneauId: _creneauSelectionne!.id);

    final rawNom = widget.medecin['nom'] ?? widget.medecin['nomComplet'] ?? '';
    final prenom = widget.medecin['prenom'] ?? '';
    final nomMedecin = (prenom.isNotEmpty)
        ? "Dr. $prenom $rawNom".trim()
        : (rawNom.toString().startsWith("Dr.") ? rawNom.toString() : "Dr. $rawNom".trim());

    if (currentUser != null) {
      final motifSaisi = _controleurMotif.text.trim();
      final motifFinal = estPourMembre
          ? "[Bénéficiaire : $patientCibleNom (${_membreSelectionne!.lienParente})] ${motifSaisi.isNotEmpty ? motifSaisi : 'Consultation médicale'}".trim()
          : (motifSaisi.isNotEmpty ? motifSaisi : "Consultation médicale");

      ref.read(rdvProvider.notifier).reserverRendezVous(
        patientId: patientCibleId,
        medecinId: _medecinId,
        medecinNom: nomMedecin,
        medecinSpecialite: widget.medecin['specialite'] ?? widget.medecin['speciality'] ?? 'Médecin Spécialiste',
        dateHeure: _creneauSelectionne!.dateHeureDebut,
        motif: motifFinal,
        typeConsultation: estDomicile ? 'DOMICILE' : 'TELECONSULTATION',
        montant: montantVal,
      );

      // Règlement immédiat de la consultation via le Portefeuille Santé Diam Yaraam :
      // Débit du patient et Crédit instantané du médecin
      final descPaiement = estPourMembre
          ? "Règlement consultation pour $patientCibleNom ($nomMedecin)"
          : "Règlement consultation avec $nomMedecin";
      await ref.read(walletProvider.notifier).payerConsultation(
        userId: currentUser.id,
        montant: montantVal,
        rdvId: "RDV-${DateTime.now().millisecondsSinceEpoch}",
        medecinId: _medecinUserId,
        description: descPaiement,
      );
    }

    final tarif = estDomicile ? "20 000 FCFA" : "${widget.medecin['tarifConsultation'] ?? 15000} FCFA";
    final modeTexte = estDomicile ? "Consultation à Domicile" : "Téléconsultation Vidéo";
    final dateTexte = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_dateSelectionnee);
    final heureDebut = DateFormat('HH:mm').format(_creneauSelectionne!.dateHeureDebut);
    final heureFin = DateFormat('HH:mm').format(_creneauSelectionne!.dateHeureFin);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF00A884), size: 28),
            SizedBox(width: 10),
            Text("Confirmation de RDV", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Votre rendez-vous a été confirmé auprès de $nomMedecin sur son créneau disponible.",
              style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7F3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(estPourMembre ? Icons.family_restroom : Icons.person, color: const Color(0xFF00A884), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            estPourMembre
                                ? "Patient : $patientCibleNom (${_membreSelectionne!.lienParente})"
                                : "Patient : Moi-même (Dossier personnel)",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF00A884)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(estDomicile ? Icons.home_work_rounded : Icons.videocam_rounded,
                          color: const Color(0xFF00A884), size: 18),
                      const SizedBox(width: 8),
                      Text(modeTexte, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text("📅 Date : $dateTexte", style: const TextStyle(fontSize: 12, color: Color(0xFF5A607F))),
                  Text("🕒 Créneau Réservé : $heureDebut - $heureFin", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00A884))),
                  Text("💰 Tarif Consultation : $tarif", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D3142))),
                  if (estDomicile) ...[
                    const SizedBox(height: 6),
                    Text("📍 Adresse : ${_controleurAdresse.text.trim()}", style: const TextStyle(fontSize: 12, color: Color(0xFF5A607F))),
                  ],
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7F3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00A884).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF00A884), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Paiement validé : $tarif débité de votre portefeuille et versé à $nomMedecin.",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF00896C)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/mes-rendez-vous');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A884),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text("Voir mes rendez-vous", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    // Récupération dynamique des créneaux que le médecin a définis comme DISPONIBLES
    ref.watch(planningProvider);

    final tousCreneauxDuJour = ref.read(planningProvider.notifier).getCreneauxDisponibles(
      medecinId: _medecinId,
      date: _dateSelectionnee,
    );
    final creneauxMatin = tousCreneauxDuJour.where((c) => c.dateHeureDebut.hour < 13).toList();
    final creneauxSoir = tousCreneauxDuJour.where((c) => c.dateHeureDebut.hour >= 13).toList();

    // Auto-ajustement intelligent de la période (Matin / Soir)
    if (_creneauSelectionne != null) {
      final periodeCreneau = _creneauSelectionne!.dateHeureDebut.hour >= 13 ? "Soir" : "Matin";
      if (_periodeSelectionnee != periodeCreneau) {
        _periodeSelectionnee = periodeCreneau;
      }
    } else {
      if (_periodeSelectionnee == "Matin" && creneauxMatin.isEmpty && creneauxSoir.isNotEmpty) {
        _periodeSelectionnee = "Soir";
      } else if (_periodeSelectionnee == "Soir" && creneauxSoir.isEmpty && creneauxMatin.isNotEmpty) {
        _periodeSelectionnee = "Matin";
      }
    }

    final creneauxDisponibles = _periodeSelectionnee == "Matin" ? creneauxMatin : creneauxSoir;

    final rawNom = widget.medecin['nom'] ?? widget.medecin['nomComplet'] ?? '';
    final prenom = widget.medecin['prenom'] ?? '';
    final nomMedecin = (prenom.isNotEmpty)
        ? "Dr. $prenom $rawNom".trim()
        : (rawNom.toString().startsWith("Dr.") ? rawNom.toString() : "Dr. $rawNom".trim());
    final specialite = widget.medecin['specialite'] ?? "Médecine Générale";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BARRE D'EN-TETE
                Row(
                  children: [
                    InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: Color(0xFF5A607F),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        nomMedecin,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CARTE MEDECIN RESUMEE
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE5E9F2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F7F3),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.person, color: Color(0xFF00A884), size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nomMedecin,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3142)),
                                    ),
                                    Text(
                                      specialite,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF00A884), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F7F3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.verified, color: Color(0xFF00A884), size: 12),
                                    SizedBox(width: 4),
                                    Text("Agréé ONMS", style: TextStyle(fontSize: 10, color: Color(0xFF00A884), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // SECTION : POUR QUI EST CE RENDEZ-VOUS ?
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Bénéficiaire de la consultation",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                            if (_membreSelectionne != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F7F3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Pour : ${_membreSelectionne!.prenom}",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00A884)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildSelecteurBeneficiaire(currentUser),

                        const SizedBox(height: 20),

                        // CHOIX DU MODE DE CONSULTATION
                        const Text(
                          "Mode de Consultation",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildCarteModeConsultation(
                                identifiant: "TELECONSULTATION",
                                titre: "Téléconsultation",
                                sousTitre: "Visio Sécurisée",
                                icone: Icons.videocam_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildCarteModeConsultation(
                                identifiant: "DOMICILE",
                                titre: "À Domicile",
                                sousTitre: "Visite Médicale",
                                icone: Icons.home_work_rounded,
                              ),
                            ),
                          ],
                        ),

                        if (_modeConsultationSelectionne == "DOMICILE") ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F7F3),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFF00A884).withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.location_on, color: Color(0xFF00A884), size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          "Adresse de Consultation",
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF134E3F)),
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: _geolocaliserPatient,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00A884),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.my_location, color: Colors.white, size: 12),
                                            SizedBox(width: 4),
                                            Text("GPS Actuel", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _controleurAdresse,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText: "Ex: Dakar, Mermoz Pyrotechnie, Rue MZ-12...",
                                    hintStyle: const TextStyle(color: Color(0xFF8E95A5), fontSize: 13),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                    ),
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // MOTIF DE LA CONSULTATION
                        const Text(
                          "Motif de la Consultation",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Suggestions rapides de motifs
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              "Consultation générale",
                              "Fièvre & Céphalées",
                              "Renouvellement ordonnance",
                              "Avis médical spécialisé",
                              "Suivi régulier",
                            ].map((suggestion) {
                              final estChoisi = _controleurMotif.text == suggestion;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _controleurMotif.text = suggestion;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: estChoisi ? const Color(0xFF00A884) : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: estChoisi ? const Color(0xFF00A884) : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Text(
                                      suggestion,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: estChoisi ? Colors.white : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),

                        TextField(
                          controller: _controleurMotif,
                          maxLines: 2,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: "Décrivez la raison de votre rendez-vous (ex: maux de tête persistants, fièvre, toux...)",
                            hintStyle: const TextStyle(color: Color(0xFF8E95A5), fontSize: 13),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF00A884), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // SÉLECTION DE LA DATE
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Date du Rendez-vous",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dateSelectionnee,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 90)),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _dateSelectionnee = picked;
                                    _creneauSelectionne = null;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.calendar_month, size: 14, color: Color(0xFF00A884)),
                                    SizedBox(width: 4),
                                    Text("Calendrier", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5A607F))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // DÉFILEMENT DES JOURS
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _joursDisponibles.length,
                            itemBuilder: (context, index) {
                              final jour = _joursDisponibles[index];
                              final estSelectionne = jour.year == _dateSelectionnee.year &&
                                  jour.month == _dateSelectionnee.month &&
                                  jour.day == _dateSelectionnee.day;
                              final nomJour = DateFormat('EEE', 'fr_FR').format(jour).toUpperCase();
                              final numJour = DateFormat('d').format(jour);

                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _dateSelectionnee = jour;
                                      _creneauSelectionne = null;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 58,
                                    decoration: BoxDecoration(
                                      color: estSelectionne ? const Color(0xFF00A884) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: estSelectionne ? const Color(0xFF00A884) : const Color(0xFFE5E9F2),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          nomJour,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: estSelectionne ? Colors.white70 : const Color(0xFFB4B9C5),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          numJour,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: estSelectionne ? Colors.white : const Color(0xFF5A607F),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        // CHOIX DE LA PÉRIODE (MATIN / SOIR)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Créneaux Ouverts par le Médecin",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F7F3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${tousCreneauxDuJour.length} disponible(s)",
                                style: const TextStyle(color: Color(0xFF00A884), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildOngletPeriode(
                                identifiant: "Matin",
                                titre: "Matinée (${creneauxMatin.length})",
                                icone: Icons.wb_sunny_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildOngletPeriode(
                                identifiant: "Soir",
                                titre: "Après-midi / Soir (${creneauxSoir.length})",
                                icone: Icons.cloud_outlined,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // AFFICHAGE DES CRÉNEAUX DISPONIBLES
                        if (creneauxDisponibles.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E9F2)),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.event_busy_rounded, color: Color(0xFFEF4444), size: 36),
                                const SizedBox(height: 8),
                                Text(
                                  tousCreneauxDuJour.isNotEmpty
                                      ? "Créneau disponible dans l'autre période"
                                      : "Aucun créneau ouvert par ce médecin",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tousCreneauxDuJour.isNotEmpty
                                      ? (_periodeSelectionnee == 'Matin'
                                          ? "$nomMedecin a ${creneauxSoir.length} créneau(x) ouvert(s) l'après-midi pour cette date."
                                          : "$nomMedecin a ${creneauxMatin.length} créneau(x) ouvert(s) en matinée pour cette date.")
                                      : "$nomMedecin n'a défini aucun créneau disponible pour cette date. Veuillez sélectionner une autre date.",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF8E95A5)),
                                ),
                                if (tousCreneauxDuJour.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _periodeSelectionnee = _periodeSelectionnee == 'Matin' ? 'Soir' : 'Matin';
                                        _creneauSelectionne = null;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00A884),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
                                    icon: Icon(
                                      _periodeSelectionnee == 'Matin' ? Icons.cloud_outlined : Icons.wb_sunny_outlined,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    label: Text(
                                      _periodeSelectionnee == 'Matin'
                                          ? "Voir l'après-midi (${creneauxSoir.length} créneau)"
                                          : "Voir la matinée (${creneauxMatin.length} créneau)",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: creneauxDisponibles.map((creneau) {
                              final heureStr = DateFormat('HH:mm').format(creneau.dateHeureDebut);
                              final estSelectionne = _creneauSelectionne?.id == creneau.id;

                              return InkWell(
                                onTap: () => setState(() => _creneauSelectionne = creneau),
                                borderRadius: BorderRadius.circular(14),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 95,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: estSelectionne ? const Color(0xFF00A884) : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: estSelectionne ? const Color(0xFF00A884) : const Color(0xFFE5E9F2),
                                      width: estSelectionne ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      if (estSelectionne)
                                        BoxShadow(
                                          color: const Color(0xFF00A884).withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        heureStr,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: estSelectionne ? Colors.white : const Color(0xFF2D3142),
                                        ),
                                      ),
                                      Text(
                                        "Disponible",
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: estSelectionne ? Colors.white70 : const Color(0xFF00A884),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),

                // BOUTON DE VALIDATION
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _creneauSelectionne != null ? _confirmerPriseRendezVous : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      disabledBackgroundColor: const Color(0xFFCBD5E1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(
                      _creneauSelectionne != null
                          ? "Confirmer le RDV à ${DateFormat('HH:mm').format(_creneauSelectionne!.dateHeureDebut)}"
                          : "Sélectionnez un créneau disponible",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarteModeConsultation({
    required String identifiant,
    required String titre,
    required String sousTitre,
    required IconData icone,
  }) {
    final estSelectionne = _modeConsultationSelectionne == identifiant;

    return InkWell(
      onTap: () => setState(() => _modeConsultationSelectionne = identifiant),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: estSelectionne ? const Color(0xFFE6F7F3) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: estSelectionne ? const Color(0xFF00A884) : const Color(0xFFE5E9F2),
            width: estSelectionne ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icone, color: estSelectionne ? const Color(0xFF00A884) : const Color(0xFF8E95A5), size: 28),
            const SizedBox(height: 8),
            Text(
              titre,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: estSelectionne ? const Color(0xFF00A884) : const Color(0xFF2D3142),
              ),
            ),
            Text(
              sousTitre,
              style: const TextStyle(fontSize: 11, color: Color(0xFF8E95A5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOngletPeriode({
    required String identifiant,
    required String titre,
    required IconData icone,
  }) {
    final estSelectionne = _periodeSelectionnee == identifiant;

    return InkWell(
      onTap: () {
        setState(() {
          _periodeSelectionnee = identifiant;
          _creneauSelectionne = null;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: estSelectionne ? const Color(0xFF00A884) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: estSelectionne ? const Color(0xFF00A884) : const Color(0xFFE5E9F2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 16, color: estSelectionne ? Colors.white : const Color(0xFF8E95A5)),
            const SizedBox(width: 6),
            Text(
              titre,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: estSelectionne ? Colors.white : const Color(0xFF5A607F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelecteurBeneficiaire(dynamic currentUser) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Option 1 : Moi-même
          _buildItemBeneficiaire(
            titre: "Moi-même",
            sousTitre: (currentUser?.fullName.toString().trim().isNotEmpty == true)
                ? currentUser!.fullName.toString().trim()
                : "Dossier personnel",
            icone: Icons.person_rounded,
            estSelectionne: _membreSelectionne == null,
            onTap: () => setState(() => _membreSelectionne = null),
          ),
          // Option pour chaque membre de la famille
          ..._membresFamille.map((membre) {
            final estSelectionne = _membreSelectionne?.id == membre.id ||
                (_membreSelectionne?.enfantUserId.isNotEmpty == true &&
                    _membreSelectionne?.enfantUserId == membre.enfantUserId);
            return _buildItemBeneficiaire(
              titre: "${membre.prenom} ${membre.nom}".trim(),
              sousTitre: membre.lienParente,
              icone: membre.genre == 'Femme' ? Icons.face_3 : Icons.face,
              estSelectionne: estSelectionne,
              onTap: () => setState(() => _membreSelectionne = membre),
            );
          }),
          // Bouton Ajouter un proche
          InkWell(
            onTap: () async {
              await context.push('/add-family-member');
              _chargerMembresFamille();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Color(0xFF00A884), size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Nouveau proche",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF00A884)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemBeneficiaire({
    required String titre,
    required String sousTitre,
    required IconData icone,
    required bool estSelectionne,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: estSelectionne ? const Color(0xFF00A884) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: estSelectionne ? const Color(0xFF00A884) : const Color(0xFFE2E8F0),
            width: estSelectionne ? 1.5 : 1,
          ),
          boxShadow: estSelectionne
              ? [
                  BoxShadow(
                    color: const Color(0xFF00A884).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: estSelectionne ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE6F7F3),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: estSelectionne ? Colors.white : const Color(0xFF00A884), size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titre,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: estSelectionne ? Colors.white : const Color(0xFF2D3142),
                  ),
                ),
                Text(
                  sousTitre,
                  style: TextStyle(
                    fontSize: 10,
                    color: estSelectionne ? Colors.white70 : const Color(0xFF8D99AE),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
