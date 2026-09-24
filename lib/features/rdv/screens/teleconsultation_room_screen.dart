import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/rendez_vous_model.dart';
import '../services/jitsi_teleconsultation_service.dart';
import '../services/rdv_api_service.dart';

class TeleconsultationRoomScreen extends ConsumerStatefulWidget {
  final dynamic rdvData; // RendezVousModel ou Map<String, dynamic>

  const TeleconsultationRoomScreen({super.key, required this.rdvData});

  @override
  ConsumerState<TeleconsultationRoomScreen> createState() => _TeleconsultationRoomScreenState();
}

class _TeleconsultationRoomScreenState extends ConsumerState<TeleconsultationRoomScreen> {
  late JitsiTeleconsultationService _jitsiService;
  bool _isConnecting = false;
  bool _isConferenceActive = false;

  @override
  void initState() {
    super.initState();
    _jitsiService = JitsiTeleconsultationService(RdvApiService());
  }

  @override
  void dispose() {
    _jitsiService.meQuitterVisio();
    super.dispose();
  }

  RendezVousModel _parseRdv() {
    if (widget.rdvData is RendezVousModel) {
      return widget.rdvData as RendezVousModel;
    } else if (widget.rdvData is Map<String, dynamic>) {
      return RendezVousModel.fromJson(widget.rdvData as Map<String, dynamic>);
    }
    return RendezVousModel(
      id: 'rdv_demo',
      patientId: 'patient_demo',
      medecinId: 'medecin_demo',
      medecinNom: 'Dr. Médecin Praticien',
      medecinSpecialite: 'Téléconsultation',
      dateHeure: DateTime.now(),
      motif: 'Téléconsultation Médicale',
    );
  }

  Future<void> _lancerVisio(RendezVousModel rdv) async {
    final user = ref.read(authProvider).user;
    final userId = user?.id ?? '';
    final isDoctor = user?.isMedecin == true || user?.role == 'MEDECIN';
    final userDisplayName = user?.fullName.isNotEmpty == true
        ? (isDoctor ? "Dr. ${user!.fullName}" : user!.fullName)
        : (isDoctor ? "Dr. Praticien" : "Patient Diam-Yaraam");

    setState(() {
      _isConnecting = true;
    });

    await _jitsiService.rejoindreVisio(
      rdvId: rdv.id,
      userId: userId,
      displayName: userDisplayName,
      onError: (errorMessage) {
        if (mounted) {
          setState(() {
            _isConnecting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text(errorMessage, style: const TextStyle(fontSize: 12.5))),
                ],
              ),
              backgroundColor: const Color(0xFFD97706),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      onJoined: () {
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _isConferenceActive = true;
          });
        }
      },
      onTerminated: () {
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _isConferenceActive = false;
          });
          final user = ref.read(authProvider).user;
          final isDoctor = user?.isMedecin == true || user?.role == 'MEDECIN';
          if (!isDoctor) {
            _afficherDialogueAvis(rdv);
          }
        }
      },
    );

    if (mounted) {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  void _afficherDialogueAvis(RendezVousModel rdv) {
    double noteDonnee = 5.0;
    final commentaireCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
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
                child: Text("Votre avis compte !", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Votre téléconsultation avec ${rdv.medecinNom ?? 'votre médecin'} est terminée. Comment évaluez-vous cette consultation ?",
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
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
                          size: 34,
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentaireCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Partagez votre avis (qualité d'écoute, ponctualité, clarté des explications...)",
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
              onPressed: () {
                Navigator.pop(ctx);
                if (mounted) Navigator.pop(context);
              },
              child: const Text("Passer", style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Merci infiniment pour votre avis !"),
                    backgroundColor: Color(0xFF0D7C66),
                  ),
                );
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D7C66),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Publier mon avis", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rdv = _parseRdv();
    final user = ref.watch(authProvider).user;
    final isDoctor = user?.isMedecin == true || user?.role == 'MEDECIN';

    final interlocuteurNom = isDoctor
        ? (rdv.patientNom ?? "Patient Diam-Yaraam")
        : (rdv.medecinNom ?? "Dr. Médecin Praticien");
    final interlocuteurRole = isDoctor ? "Patient" : (rdv.medecinSpecialite ?? "Médecin Spécialiste");
    final dateFormatted = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(rdv.dateHeure);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Salon de Téléconsultation",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // BANDEAU SÉCURITÉ CRYPTAGE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D7C66).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.35)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: Color(0xFF0D7C66), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "SESSIONS MÉDICALES SÉCURISÉES JITSI",
                            style: TextStyle(color: Color(0xFF0D7C66), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Canal vidéo chiffré réservé exclusivement au médecin et au patient.",
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // CARTE INTERLOCUTEUR (PRATICIEN OU PATIENT)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: const Color(0xFF0D7C66).withValues(alpha: 0.2),
                      child: Icon(
                        isDoctor ? Icons.person_rounded : Icons.medical_services_rounded,
                        color: const Color(0xFF0D7C66),
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      interlocuteurNom,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D7C66).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        interlocuteurRole,
                        style: const TextStyle(color: Color(0xFF0D7C66), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),

                    // DETAIL HORAIRE ET MOTIF
                    Row(
                      children: [
                        const Icon(Icons.event_rounded, color: Colors.white54, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dateFormatted,
                            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.assignment_outlined, color: Colors.white54, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Motif : ${rdv.motif}",
                            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // BOUTON PRINCIPAL D'ACTION REJOINDRE JITSI MEET
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isConnecting
                      ? null
                      : () => _lancerVisio(rdv),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D7C66),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  icon: _isConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Icon(
                          _isConferenceActive ? Icons.videocam_rounded : Icons.video_call_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                  label: Text(
                    _isConnecting
                        ? "Vérification des accès backend..."
                        : (_isConferenceActive ? "Rejoindre à nouveau la Visio" : "Rejoindre la Téléconsultation"),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ETAT & EXPLICATION DE LA FENÊTRE D'ACCÈS
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.white38, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "L'accès est ouvert 15 minutes avant le rendez-vous. Le backend vérifie l'authenticité et les droits d'accès avant chaque connexion.",
                        style: TextStyle(color: Colors.white54, fontSize: 11.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
