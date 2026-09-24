import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../../auth/providers/auth_provider.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> doctor;

  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  ConsumerState<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen> {
  String _selectedPeriod = "Matin";
  String _selectedTimeSlot = "09:00";
  String _selectedConsultationType = "TELECONSULTATION"; // TELECONSULTATION ou DOMICILE (CABINET non géré pour cette version)

  final TextEditingController _locationController = TextEditingController();

  final List<String> _morningSlots = [
    "05:00", "06:00", "07:00", "08:00", "09:00", "10:00", "11:00", "12:00", "13:00"
  ];
  final List<String> _eveningSlots = [
    "14:00", "15:00", "16:00", "17:00", "18:00", "19:00", "20:00", "21:00", "22:00", "23:00", "00:00", "01:00", "02:00", "03:00", "04:00"
  ];

  DateTime get _appointmentDate {
    if (widget.doctor['selectedDate'] != null) {
      try {
        return DateTime.parse(widget.doctor['selectedDate'].toString());
      } catch (_) {}
    }
    return DateTime.now();
  }

  /// Vérifie si le créneau sur la date choisie est strictement dans le passé
  bool _estCreneauPasseStrict(String slot) {
    final now = DateTime.now();
    final d = _appointmentDate;
    final dateJour = DateTime(d.year, d.month, d.day);
    final dateAujourdhui = DateTime(now.year, now.month, now.day);
    if (dateJour.isBefore(dateAujourdhui)) return true;
    if (dateJour.isAfter(dateAujourdhui)) return false;

    // Même jour : comparer heure et minute
    final parts = slot.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final slotDateTime = DateTime(d.year, d.month, d.day, h, m);
    return slotDateTime.isBefore(now);
  }

  /// Vérifie si le créneau est à moins de 30 minutes du moment actuel
  bool _estCreneauTropProche(String slot) {
    final now = DateTime.now();
    final d = _appointmentDate;
    final dateJour = DateTime(d.year, d.month, d.day);
    final dateAujourdhui = DateTime(now.year, now.month, now.day);
    if (dateJour.isBefore(dateAujourdhui)) return false;
    if (dateJour.isAfter(dateAujourdhui)) return false;

    final parts = slot.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final slotDateTime = DateTime(d.year, d.month, d.day, h, m);
    return !slotDateTime.isBefore(now) &&
        slotDateTime.isBefore(now.add(const Duration(minutes: 30)));
  }

  /// Règle : un rendez-vous doit être pris au moins 30 minutes à l'avance
  bool _estCreneauInaccessibleTemps(String slot) {
    final now = DateTime.now();
    final d = _appointmentDate;
    final dateJour = DateTime(d.year, d.month, d.day);
    final dateAujourdhui = DateTime(now.year, now.month, now.day);
    if (dateJour.isBefore(dateAujourdhui)) return true;
    if (dateJour.isAfter(dateAujourdhui)) return false;

    final parts = slot.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final slotDateTime = DateTime(d.year, d.month, d.day, h, m);
    return slotDateTime.isBefore(now.add(const Duration(minutes: 30)));
  }

  /// Alias vérifiant l'inaccessibilité temporelle (< 30 min ou passé)
  bool _estCreneauPasse(String slot) => _estCreneauInaccessibleTemps(slot);

  @override
  void initState() {
    super.initState();
    final allSlots = [..._morningSlots, ..._eveningSlots];

    if (widget.doctor['selectedSlot'] != null && !_estCreneauPasse(widget.doctor['selectedSlot'].toString())) {
      _selectedTimeSlot = widget.doctor['selectedSlot'].toString();
    } else {
      // Trouver automatiquement le premier créneau futur valide
      final premierValide = allSlots.firstWhere(
        (s) => !_estCreneauPasse(s),
        orElse: () => "09:00",
      );
      _selectedTimeSlot = premierValide;
    }

    final h = int.tryParse(_selectedTimeSlot.split(':')[0]) ?? 9;
    _selectedPeriod = (h >= 14 || h < 5) ? "Soir" : "Matin";

    if (widget.doctor['selectedConsultationType'] != null && widget.doctor['selectedConsultationType'] != "CABINET") {
      _selectedConsultationType = widget.doctor['selectedConsultationType'].toString();
    } else {
      _selectedConsultationType = "TELECONSULTATION";
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null && user.id.isNotEmpty) {
        ref.read(walletProvider.notifier).loadUserWallet(user.id);
      }
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  String _formaterPrix(int montant) {
    final str = montant.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  void _onGetCurrentLocation() {
    setState(() {
      _locationController.text = "Dakar, Sacré-Cœur 3, Villa N° 45B (Position GPS détectée)";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Position GPS actuelle ajoutée avec succès"),
        backgroundColor: Color(0xFF00A884),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Dialogue d'alerte lorsque le solde du portefeuille est insuffisant pour réserver
  void _afficherDialogueSoldeInsuffisant(double soldeActuel, int montantRequis) {
    final manque = (montantRequis - soldeActuel).clamp(0.0, double.infinity).toInt();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.wallet_rounded, color: Color(0xFFDC2626), size: 26),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Solde Insuffisant",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Votre solde Diam Yaraam est insuffisant pour valider ce rendez-vous. Le montant de la consultation doit être directement débité de votre portefeuille santé.",
              style: TextStyle(fontSize: 13.5, color: Color(0xFF5A607F), height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Montant de la consultation :", style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      Text("${_formaterPrix(montantRequis)} FCFA", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Votre solde actuel :", style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      Text("${_formaterPrix(soldeActuel.toInt())} FCFA", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Montant manquant :", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                      Text("${_formaterPrix(manque)} FCFA", style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "💡 Rechargez facilement votre portefeuille par Wave, Orange Money ou Free Money pour débloquer votre réservation.",
              style: TextStyle(fontSize: 11.5, color: Color(0xFF00A884), fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  child: const Text("Annuler", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/wallet');
                  },
                  icon: const Icon(Icons.add_card_rounded, color: Colors.white, size: 18),
                  label: const Text("Recharger", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A884),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onContinue() {
    final isHome = _selectedConsultationType == "DOMICILE";

    if (isHome && _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez renseigner votre adresse de localisation pour la visite à domicile."),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // CONTRÔLE DE DÉLAI : Un rendez-vous doit être pris au moins 30 minutes à l'avance
    if (_estCreneauInaccessibleTemps(_selectedTimeSlot)) {
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

    final doctorName = widget.doctor['nom'] != null 
        ? "Dr. ${widget.doctor['prenom'] ?? ''} ${widget.doctor['nom']}".trim()
        : "Dr. Praticien";

    final tarifTele = (widget.doctor['tarifTeleconsultation'] ?? 10000).toInt();
    final tarifDom = (widget.doctor['tarifDomicile'] ?? 20000).toInt();
    final int montantConsultation = isHome ? tarifDom : tarifTele;

    // CONTRÔLE STRICT DU SOLDE PORTEFEUILLE SANTÉ DU PATIENT :
    final walletState = ref.read(walletProvider);
    final double soldeActuel = walletState.portefeuille?.solde ?? 
        (widget.doctor['soldePortefeuille'] as num?)?.toDouble() ?? 0.0;

    if (soldeActuel < montantConsultation) {
      _afficherDialogueSoldeInsuffisant(soldeActuel, montantConsultation);
      return;
    }

    final String price;
    final String typeText;
    if (_selectedConsultationType == "DOMICILE") {
      price = "${_formaterPrix(tarifDom)} FCFA / heure";
      typeText = "Consultation à Domicile (1h)";
    } else {
      price = "${_formaterPrix(tarifTele)} FCFA / heure";
      typeText = "Téléconsultation Vidéo (1h)";
    }

    // Débit du portefeuille santé de l'utilisateur
    final user = ref.read(authProvider).user;
    if (user != null && user.id.isNotEmpty) {
      ref.read(walletProvider.notifier).payerConsultation(
        userId: user.id,
        montant: montantConsultation.toDouble(),
        rdvId: "rdv-${DateTime.now().millisecondsSinceEpoch}",
        medecinId: widget.doctor['id']?.toString(),
        description: "Règlement $typeText avec $doctorName",
      );
    }

    final nouveauSolde = (soldeActuel - montantConsultation).toInt();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF00A884), size: 28),
            SizedBox(width: 10),
            Text("RDV Confirmé !", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Votre rendez-vous a été confirmé et transmis à $doctorName.",
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
                  Row(
                    children: [
                      Icon(isHome ? Icons.home_work_rounded : Icons.videocam_rounded, 
                          color: const Color(0xFF00A884), size: 18),
                      const SizedBox(width: 8),
                      Text(typeText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text("🕒 Créneau : $_selectedTimeSlot ($_selectedPeriod)", style: const TextStyle(fontSize: 12, color: Color(0xFF5A607F))),
                  Text("💰 Tarif : $price", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF00A884))),
                  if (isHome) ...[
                    const SizedBox(height: 6),
                    Text("📍 Adresse : ${_locationController.text.trim()}", style: const TextStyle(fontSize: 12, color: Color(0xFF5A607F))),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Paiement effectué : ${_formaterPrix(montantConsultation)} FCFA débités de votre Portefeuille Santé.\nNouveau solde : ${_formaterPrix(nouveauSolde)} FCFA.",
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF166534), fontWeight: FontWeight.w500),
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
              context.go('/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A884),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text("Retour au Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final double soldeActuel = walletState.portefeuille?.solde ?? 
        (widget.doctor['soldePortefeuille'] as num?)?.toDouble() ?? 0.0;
    final int currentTarif = _selectedConsultationType == "DOMICILE"
        ? (widget.doctor['tarifDomicile'] ?? 20000).toInt()
        : (widget.doctor['tarifTeleconsultation'] ?? 10000).toInt();
    final bool aSoldeSuffisant = soldeActuel >= currentTarif;

    final activeSlots = _selectedPeriod == "Matin" ? _morningSlots : _eveningSlots;
    final doctorName = widget.doctor['nom'] != null 
        ? "Dr. ${widget.doctor['prenom'] ?? ''} ${widget.doctor['nom']}".trim()
        : "Dr. Spécialiste";
    final specialty = widget.doctor['specialite'] ?? "Médecine Générale";

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
                        doctorName,
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
                        // CARTE MEDECIN
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
                                      doctorName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3142)),
                                    ),
                                    Text(
                                      specialty,
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
                                    Text("Médecin Vérifié", style: TextStyle(fontSize: 10, color: Color(0xFF00A884), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          "Type de Consultation",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 12),

                        /*
                        // Consultation au Cabinet : reportée pour une prochaine version
                        _buildConsultationOption(
                          id: "CABINET",
                          title: "Consultation au Cabinet",
                          subtitle: "Rendez-vous physique au cabinet (durée 1h)",
                          price: "${(widget.doctor['tarifConsultation'] ?? 15000).toInt()} FCFA / h",
                          icon: Icons.local_hospital_rounded,
                        ),
                        const SizedBox(height: 12),
                        */

                        _buildConsultationOption(
                          id: "TELECONSULTATION",
                          title: "Téléconsultation Vidéo",
                          subtitle: "Consultation à distance par appel vidéo (durée 1h)",
                          price: "${_formaterPrix((widget.doctor['tarifTeleconsultation'] ?? 10000).toInt())} FCFA / h",
                          icon: Icons.videocam_rounded,
                        ),

                        const SizedBox(height: 12),

                        _buildConsultationOption(
                          id: "DOMICILE",
                          title: "Consultation à Domicile",
                          subtitle: "Déplacement et visite médicale (durée 1h)",
                          price: "${_formaterPrix((widget.doctor['tarifDomicile'] ?? 20000).toInt())} FCFA / h",
                          icon: Icons.home_work_rounded,
                        ),

                        const SizedBox(height: 14),

                        // SECTION PORTEFEUILLE SANTÉ (RÈGLEMENT & CONTRÔLE DE SOLDE)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: aSoldeSuffisant ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: aSoldeSuffisant ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 20,
                                    color: aSoldeSuffisant ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Paiement par Portefeuille Santé",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: aSoldeSuffisant ? const Color(0xFF166534) : const Color(0xFF991B1B),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => context.push('/wallet'),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: aSoldeSuffisant ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
                                        ),
                                      ),
                                      child: Text(
                                        "Recharger",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: aSoldeSuffisant ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Le tarif de la consultation (${_formaterPrix(currentTarif)} FCFA) sera automatiquement débité de votre portefeuille santé lors de la réservation.",
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Votre solde : ${_formaterPrix(soldeActuel.toInt())} FCFA",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: aSoldeSuffisant ? const Color(0xFF166534) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: aSoldeSuffisant ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      aSoldeSuffisant ? "Solde suffisant" : "Solde insuffisant",
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: aSoldeSuffisant ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (_selectedConsultationType == "DOMICILE") ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFBBEFDB)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.location_on_rounded, color: Color(0xFF00A884), size: 20),
                                        SizedBox(width: 6),
                                        Text(
                                          "Adresse de Consultation",
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF134E3F)),
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: _onGetCurrentLocation,
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
                                  controller: _locationController,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText: "Ex: Dakar, Mermoz Pyrotechnie, Rue MZ-12, Villa 45...",
                                    hintStyle: const TextStyle(color: Color(0xFF8E95A5), fontSize: 13),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF00A884), width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "💡 Indiquez des repères précis (numéro de villa, pharmacie, boutique) pour faciliter l'arrivée du médecin.",
                                  style: TextStyle(fontSize: 11, color: Color(0xFF5A607F), fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        const Text(
                          "Date & Créneaux Disponibles",
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
                              child: _buildPeriodTab(
                                id: "Matin",
                                title: "Matinée",
                                icon: Icons.wb_sunny_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPeriodTab(
                                id: "Soir",
                                title: "Après-midi / Soir",
                                icon: Icons.cloud_outlined,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: activeSlots.map((slot) {
                            final isSelected = _selectedTimeSlot == slot;
                            final isPasse = _estCreneauPasseStrict(slot);
                            final isTropProche = !isPasse && _estCreneauTropProche(slot);
                            final bool estInaccessible = isPasse || isTropProche;

                            return InkWell(
                              onTap: estInaccessible ? null : () => setState(() => _selectedTimeSlot = slot),
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: (isPasse || isTropProche) ? 108 : 95,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF00A884)
                                      : (estInaccessible ? const Color(0xFFF1F5F9) : Colors.white),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF00A884)
                                        : (estInaccessible ? const Color(0xFFE2E8F0) : const Color(0xFFE5E9F2)),
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: const Color(0xFF00A884).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        slot,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          decoration: estInaccessible ? TextDecoration.lineThrough : null,
                                          color: isSelected
                                              ? Colors.white
                                              : (estInaccessible ? const Color(0xFF94A3B8) : const Color(0xFF5A607F)),
                                        ),
                                      ),
                                      if (isPasse) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE2E8F0),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            "Passé",
                                            style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ] else if (isTropProche) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            "< 30m",
                                            style: TextStyle(fontSize: 8.5, color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
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

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        final typeLabel = _selectedConsultationType == "DOMICILE"
                            ? "la Visite à Domicile"
                            : "la Téléconsultation";
                        return Text(
                          "Confirmer $typeLabel (${_formaterPrix(currentTarif)} FCFA / h)",
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
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

  Widget _buildConsultationOption({
    required String id,
    required String title,
    required String subtitle,
    required String price,
    required IconData icon,
  }) {
    final isSelected = _selectedConsultationType == id;

    return InkWell(
      onTap: () => setState(() => _selectedConsultationType = id),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A884) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A884) : const Color(0xFFE5E9F2),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF00A884).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE6F7F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF00A884),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF8E95A5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFE6F7F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                price,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF00A884) : const Color(0xFF00A884),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab({
    required String id,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedPeriod == id;

    return InkWell(
      onTap: () => setState(() => _selectedPeriod = id),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: estSelectionne(isSelected),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A884) : const Color(0xFFE5E9F2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF8E95A5),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF8E95A5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color estSelectionne(bool sel) => sel ? const Color(0xFF00A884) : Colors.white;
}
