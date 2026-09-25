import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/rendez_vous_model.dart';
import '../services/livekit_teleconsultation_service.dart';
import '../services/rdv_api_service.dart';

class TeleconsultationRoomScreen extends ConsumerStatefulWidget {
  final dynamic rdvData; // RendezVousModel ou Map<String, dynamic>

  const TeleconsultationRoomScreen({super.key, required this.rdvData});

  @override
  ConsumerState<TeleconsultationRoomScreen> createState() =>
      _TeleconsultationRoomScreenState();
}

class _TeleconsultationRoomScreenState
    extends ConsumerState<TeleconsultationRoomScreen> {
  late LiveKitTeleconsultationService _lkService;

  // État de la salle
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _errorMessage;

  // Contrôles A/V
  bool _micOn = true;
  bool _cameraOn = true;

  // Tracks vidéo
  VideoTrack? _localVideoTrack;
  final Map<String, VideoTrack?> _remoteVideoTracks = {};

  // Listener pour les événements de la salle
  EventsListener<RoomEvent>? _roomListener;

  @override
  void initState() {
    super.initState();
    _lkService = LiveKitTeleconsultationService(RdvApiService());
  }

  @override
  void dispose() {
    _roomListener?.dispose();
    _lkService.quitter();
    super.dispose();
  }

  RendezVousModel _parseRdv() {
    if (widget.rdvData is RendezVousModel) return widget.rdvData as RendezVousModel;
    if (widget.rdvData is Map<String, dynamic>) {
      return RendezVousModel.fromJson(widget.rdvData as Map<String, dynamic>);
    }
    return RendezVousModel(
      id: 'rdv_demo',
      patientId: '',
      medecinId: '',
      medecinNom: 'Dr. Médecin Praticien',
      medecinSpecialite: 'Téléconsultation',
      dateHeure: DateTime.now(),
      motif: 'Téléconsultation',
    );
  }

  Future<void> _rejoindreVisio(RendezVousModel rdv) async {
    final user = ref.read(authProvider).user;
    final isDoctor = user?.role == 'MEDECIN';
    final displayName = (user?.fullName.isNotEmpty == true)
        ? (isDoctor ? 'Dr. ${user!.fullName}' : user!.fullName)
        : (isDoctor ? 'Dr. Praticien' : 'Patient');

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final room = await _lkService.rejoindre(
        rdvId: rdv.id,
        userId: user?.id,
        displayName: displayName,
      );

      // Configurer le listener des événements de la salle
      _roomListener = room.createListener();

      _roomListener!
        ..on<TrackSubscribedEvent>((event) {
          if (event.track is VideoTrack) {
            setState(() {
              _remoteVideoTracks[event.participant.identity] =
                  event.track as VideoTrack;
            });
          }
        })
        ..on<TrackUnsubscribedEvent>((event) {
          setState(() {
            _remoteVideoTracks.remove(event.participant.identity);
          });
        })
        ..on<ParticipantDisconnectedEvent>((event) {
          setState(() {
            _remoteVideoTracks.remove(event.participant.identity);
          });
        })
        ..on<RoomDisconnectedEvent>((_) {
          if (mounted) {
            setState(() {
              _isConnected = false;
              _isConnecting = false;
            });
            _afficherDialogueAvis(rdv, isDoctor: isDoctor);
          }
        });

      // Récupérer le track vidéo local
      final localVideoPublication = room.localParticipant?.videoTrackPublications.firstOrNull;
      final localTrack = localVideoPublication?.track;

      setState(() {
        _isConnecting = false;
        _isConnected = true;
        _localVideoTrack = localTrack is VideoTrack ? localTrack : null;
        _micOn = room.localParticipant?.isMicrophoneEnabled() ?? true;
        _cameraOn = room.localParticipant?.isCameraEnabled() ?? true;
      });
    } on TeleconsultationException catch (te) {
      setState(() {
        _isConnecting = false;
        _errorMessage = te.message;
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Erreur de connexion LiveKit : ${e.toString()}';
      });
    }
  }

  Future<void> _toggleMicro() async {
    await _lkService.toggleMicro();
    setState(() {
      _micOn = _lkService.room?.localParticipant?.isMicrophoneEnabled() ?? _micOn;
    });
  }

  Future<void> _toggleCamera() async {
    await _lkService.toggleCamera();
    setState(() {
      _cameraOn = _lkService.room?.localParticipant?.isCameraEnabled() ?? _cameraOn;
    });
  }

  Future<void> _quitter(RendezVousModel rdv, bool isDoctor) async {
    await _lkService.quitter();
    setState(() {
      _isConnected = false;
      _localVideoTrack = null;
      _remoteVideoTracks.clear();
    });
    _afficherDialogueAvis(rdv, isDoctor: isDoctor);
  }

  void _afficherDialogueAvis(RendezVousModel rdv, {required bool isDoctor}) {
    if (!mounted) return;
    if (isDoctor) {
      Navigator.of(context).pop();
      return;
    }
    double note = 5.0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.star_rounded, color: Color(0xFF0D7C66), size: 28),
              SizedBox(width: 10),
              Expanded(child: Text('Votre avis compte !', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Comment évaluez-vous votre téléconsultation avec ${rdv.medecinNom ?? 'votre médecin'} ?',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final e = i + 1;
                  return IconButton(
                    icon: Icon(
                      e <= note ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 34,
                    ),
                    onPressed: () => setDialogState(() => note = e.toDouble()),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
              child: const Text('Passer', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Merci pour votre avis !'), backgroundColor: Color(0xFF0D7C66)),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D7C66),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Envoyer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final rdv = _parseRdv();
    final user = ref.watch(authProvider).user;
    final isDoctor = user?.role == 'MEDECIN';
    final interlocuteur = isDoctor
        ? (rdv.patientNom ?? 'Patient')
        : (rdv.medecinNom ?? 'Dr. Médecin');
    final interlocuteurRole = isDoctor ? 'Patient' : (rdv.medecinSpecialite ?? 'Médecin');
    final dateFormatted = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(rdv.dateHeure);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => _isConnected
              ? _quitter(rdv, isDoctor)
              : Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isConnected)
              Container(
                width: 8, height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.6), blurRadius: 6)],
                ),
              ),
            Text(
              _isConnected ? 'En cours — LiveKit' : 'Salon de Téléconsultation',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isConnected ? _buildSalleActive(rdv, isDoctor) : _buildEcranPreJoin(rdv, interlocuteur, interlocuteurRole, dateFormatted, isDoctor),
    );
  }

  // ─── ÉCRAN PRÉ-CONNEXION ─────────────────────────────────────────────────────

  Widget _buildEcranPreJoin(RendezVousModel rdv, String interlocuteur, String role, String date, bool isDoctor) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Badge sécurité LiveKit
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
                          'SESSION MÉDICALE SÉCURISÉE — LIVEKIT CLOUD',
                          style: TextStyle(color: Color(0xFF0D7C66), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Canal vidéo chiffré de bout en bout. Token JWT signé par le backend.',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Carte interlocuteur
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
                  Text(interlocuteur,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D7C66).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(role, style: const TextStyle(color: Color(0xFF0D7C66), fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.event_rounded, color: Colors.white54, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(date, style: const TextStyle(color: Colors.white70, fontSize: 12.5))),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.assignment_outlined, color: Colors.white54, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Motif : ${rdv.motif}', style: const TextStyle(color: Colors.white70, fontSize: 12.5))),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Erreur
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Bouton rejoindre
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isConnecting ? null : () => _rejoindreVisio(rdv),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D7C66),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                icon: _isConnecting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.video_call_rounded, color: Colors.white, size: 26),
                label: Text(
                  _isConnecting ? 'Connexion à LiveKit...' : 'Rejoindre la Téléconsultation',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info fenêtre accès
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
                      'L\'accès est ouvert 15 minutes avant le rendez-vous. Le backend vérifie les droits avant chaque connexion LiveKit.',
                      style: TextStyle(color: Colors.white54, fontSize: 11.5, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SALLE ACTIVE (EN COURS DE CONSULTATION) ─────────────────────────────────

  Widget _buildSalleActive(RendezVousModel rdv, bool isDoctor) {
    final hasRemote = _remoteVideoTracks.isNotEmpty;
    final remoteTrack = hasRemote ? _remoteVideoTracks.values.first : null;

    return SafeArea(
      child: Column(
        children: [
          // Vue principale : vidéo du participant distant
          Expanded(
            child: Stack(
              children: [
                // Vidéo distante (grande)
                if (remoteTrack != null)
                  Positioned.fill(
                    child: VideoTrackRenderer(
                      remoteTrack,
                      fit: VideoViewFit.cover,
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: const Color(0xFF0D7C66).withValues(alpha: 0.2),
                          child: Icon(
                            isDoctor ? Icons.person_rounded : Icons.medical_services_rounded,
                            color: const Color(0xFF0D7C66),
                            size: 54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isDoctor
                              ? (rdv.patientNom ?? 'Patient en attente...')
                              : (rdv.medecinNom ?? 'Médecin en attente...'),
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'En attente de la connexion de l\'autre participant...',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                // Vidéo locale (petite, en haut à droite)
                if (_localVideoTrack != null && _cameraOn)
                  Positioned(
                    top: 16, right: 16,
                    width: 110, height: 150,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF0D7C66), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: VideoTrackRenderer(
                          _localVideoTrack!,
                          fit: VideoViewFit.cover,
                        ),
                      ),
                    ),
                  )
                else
                  Positioned(
                    top: 16, right: 16,
                    width: 110, height: 150,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 32),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Barre de contrôles
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            color: const Color(0xFF0F1520),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Micro
                _buildControlButton(
                  icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                  label: _micOn ? 'Micro' : 'Muet',
                  color: _micOn ? Colors.white : Colors.redAccent,
                  bgColor: _micOn ? Colors.white12 : Colors.redAccent.withValues(alpha: 0.2),
                  onTap: _toggleMicro,
                ),

                // Caméra
                _buildControlButton(
                  icon: _cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                  label: _cameraOn ? 'Caméra' : 'Caméra off',
                  color: _cameraOn ? Colors.white : Colors.redAccent,
                  bgColor: _cameraOn ? Colors.white12 : Colors.redAccent.withValues(alpha: 0.2),
                  onTap: _toggleCamera,
                ),

                // Raccrocher
                _buildControlButton(
                  icon: Icons.call_end_rounded,
                  label: 'Terminer',
                  color: Colors.white,
                  bgColor: Colors.red,
                  onTap: () => _quitter(rdv, isDoctor),
                  isLarge: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    final size = isLarge ? 64.0 : 52.0;
    final iconSize = isLarge ? 28.0 : 22.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size, height: size,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 10)),
      ],
    );
  }
}
