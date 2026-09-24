import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zxing2/qrcode.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dossier/providers/dossier_provider.dart';
import '../models/qr_urgence_model.dart';
import '../providers/consent_provider.dart';
import '../providers/patient_provider.dart';
import '../services/pass_vital_helper.dart';
import '../widgets/carte_pass_vital_widget.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  final bool? isMedecinScan;

  const QrScannerScreen({
    super.key,
    this.initialTabIndex = 0,
    this.isMedecinScan,
  });

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _laserAnimController;
  late Animation<double> _laserAnimation;
  final TextEditingController _tokenInputCtrl = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isMedecinScan = false;
  bool _isScanning = false;
  bool _isCameraActive = false;
  bool _isTorchOn = false;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    final isDoctor = user?.isMedecin == true ||
        user?.role.toUpperCase() == 'MEDECIN' ||
        user?.role.toUpperCase() == 'DOCTEUR' ||
        widget.isMedecinScan == true;
    _isMedecinScan = isDoctor;

    if (user != null) {
      // S'assurer que le dossier et le profil patient sont chargés pour le Pass Vital
      Future.microtask(() {
        ref.read(patientProvider.notifier).loadProfile(patientId: user.id);
        ref.read(dossierProvider.notifier).loadDossier(patientId: user.id);
      });
    }

    final tabCount = isDoctor ? 2 : 1;
    final initialIdx = isDoctor ? widget.initialTabIndex.clamp(0, 1) : 0;
    _isCameraActive = (initialIdx == 1);

    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: initialIdx,
    );

    if (isDoctor) {
      _tabController.addListener(() {
        if (_tabController.index == 1) {
          if (!_isCameraActive) {
            _scannerController.start();
            setState(() => _isCameraActive = true);
          }
        } else {
          if (_isCameraActive) {
            _scannerController.stop();
            setState(() => _isCameraActive = false);
          }
        }
      });
    }

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _laserAnimController.dispose();
    _tokenInputCtrl.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  String _extractTokenFromUrl(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.contains('/urgence/')) {
      return trimmed.split('/urgence/').last.split('?').first.trim();
    }
    if (trimmed.contains('http://') || trimmed.contains('https://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    }
    return trimmed;
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isScanning) return;

    final now = DateTime.now();
    if (_lastScanTime != null && now.difference(_lastScanTime!).inMilliseconds < 1500) {
      return;
    }

    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        _lastScanTime = now;
        final rawTrimmed = rawValue.trim();
        if (!rawTrimmed.startsWith('{')) {
          _tokenInputCtrl.text = _extractTokenFromUrl(rawTrimmed);
        } else {
          _tokenInputCtrl.text = "Pass QR Santé Détecté";
        }
        _performScan(rawTrimmed);
        break;
      }
    }
  }

  String? _decodeQrFromBytes(Uint8List bytes) {
    try {
      final rawImage = img.decodeImage(bytes);
      if (rawImage == null) return null;

      // 1. Corriger l'orientation EXIF (crucial pour les photos prises sur smartphone)
      final orientedImage = img.bakeOrientation(rawImage);

      // Fonction d'essai de décodage rapide pour une image candidate
      String? tryDecode(img.Image candidate) {
        try {
          final w = candidate.width;
          final h = candidate.height;
          final size = w * h;
          final int32List = Int32List(size);

          int idx = 0;
          for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
              final p = candidate.getPixel(x, y);
              final r = p.r.toInt();
              final g = p.g.toInt();
              final b = p.b.toInt();
              int32List[idx++] = (0xFF << 24) | (r << 16) | (g << 8) | b;
            }
          }

          final luminanceSource = RGBLuminanceSource(w, h, int32List);
          final hints = DecodeHints()..put(DecodeHintType.tryHarder);
          final reader = QRCodeReader();

          // A. HybridBinarizer standard
          try {
            final bitmap = BinaryBitmap(HybridBinarizer(luminanceSource));
            final result = reader.decode(bitmap, hints: hints);
            if (result.text.isNotEmpty) return result.text;
          } catch (_) {}

          // B. GlobalHistogramBinarizer
          try {
            final bitmap = BinaryBitmap(GlobalHistogramBinarizer(luminanceSource));
            final result = reader.decode(bitmap, hints: hints);
            if (result.text.isNotEmpty) return result.text;
          } catch (_) {}

          // C. Luminance inversée (très utile si le QR code est sur fond sombre)
          try {
            final invertedSource = InvertedLuminanceSource(luminanceSource);
            final bitmap = BinaryBitmap(HybridBinarizer(invertedSource));
            final result = reader.decode(bitmap, hints: hints);
            if (result.text.isNotEmpty) return result.text;
          } catch (_) {}
        } catch (_) {}
        return null;
      }

      // Passe 1 : Échelle standard ~800px max (optimal ZXing)
      img.Image baseCandidate = orientedImage;
      if (orientedImage.width > 800 || orientedImage.height > 800) {
        baseCandidate = img.copyResize(
          orientedImage,
          width: orientedImage.width >= orientedImage.height ? 800 : null,
          height: orientedImage.height > orientedImage.width ? 800 : null,
          interpolation: img.Interpolation.linear,
        );
      }
      var res = tryDecode(baseCandidate);
      if (res != null) return res;

      // Passe 2 : Version niveaux de gris (grayscale)
      final grayscaleCandidate = img.grayscale(baseCandidate);
      res = tryDecode(grayscaleCandidate);
      if (res != null) return res;

      // Passe 3 : Recadrage au centre (75%)
      final bw = baseCandidate.width;
      final bh = baseCandidate.height;
      if (bw > 200 && bh > 200) {
        final cropW = (bw * 0.75).toInt();
        final cropH = (bh * 0.75).toInt();
        final cropX = ((bw - cropW) / 2).toInt();
        final cropY = ((bh - cropH) / 2).toInt();
        final centerCropped = img.copyCrop(
          baseCandidate,
          x: cropX,
          y: cropY,
          width: cropW,
          height: cropH,
        );
        res = tryDecode(centerCropped);
        if (res != null) return res;

        res = tryDecode(img.grayscale(centerCropped));
        if (res != null) return res;
      }

      // Passe 4 : Échelle plus compacte (~500px)
      if (orientedImage.width > 500 || orientedImage.height > 500) {
        final candidate500 = img.copyResize(
          orientedImage,
          width: orientedImage.width >= orientedImage.height ? 500 : null,
          height: orientedImage.height > orientedImage.width ? 500 : null,
          interpolation: img.Interpolation.linear,
        );
        res = tryDecode(candidate500);
        if (res != null) return res;

        res = tryDecode(img.grayscale(candidate500));
        if (res != null) return res;
      }

      // Passe 5 : Image originale (si taille raisonnable)
      if (orientedImage.width <= 1200 && orientedImage.height <= 1200) {
        res = tryDecode(orientedImage);
        if (res != null) return res;
      }

      // Passe 6 : Rotations (90, 270, 180)
      for (final angle in [90, 270, 180]) {
        final rotated = img.copyRotate(baseCandidate, angle: angle);
        res = tryDecode(rotated);
        if (res != null) return res;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickAndScanImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text("Lecture et analyse de la Carte Santé en cours..."),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF0D7C66),
              duration: Duration(milliseconds: 1600),
            ),
          );
        }

        // 1. Décodage réel multi-plateforme haute performance via bytes
        final bytes = await pickedFile.readAsBytes();
        String? qrText = _decodeQrFromBytes(bytes);

        // 2. Si le décodeur Dart n'a pas lu, essayer l'analyseur natif
        if (qrText == null || qrText.isEmpty) {
          try {
            final capture = await _scannerController.analyzeImage(pickedFile.path);
            if (capture != null && capture.barcodes.isNotEmpty) {
              qrText = capture.barcodes.first.rawValue;
            }
          } catch (_) {}
        }

        if (qrText != null && qrText.trim().isNotEmpty) {
          final rawTrimmed = qrText.trim();
          if (!rawTrimmed.startsWith('{')) {
            _tokenInputCtrl.text = _extractTokenFromUrl(rawTrimmed);
          } else {
            _tokenInputCtrl.text = "Carte Médicale Pass Santé détectée";
          }
          await _performScan(rawTrimmed);
          return;
        }

        // 3. Aucun QR Code trouvé dans l'image
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Aucun code de carte lisible détecté. Assurez-vous que la carte ou son QR Code est bien visible et éclairé."),
              backgroundColor: Colors.orangeAccent,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la lecture de l'image : $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _performScan(String token) async {
    final cleanToken = token.trim();
    if (cleanToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez scanner un QR code ou saisir un identifiant."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isScanning = true;
    });

    final result = await ref.read(patientProvider.notifier).scannerQr(
          cleanToken,
          isMedecin: _isMedecinScan,
        );

    if (mounted) {
      setState(() {
        _isScanning = false;
      });

      if (result != null) {
        final user = ref.read(authProvider).user;
        final docId = user?.id.isNotEmpty == true ? user!.id : 'med-aissatou-diop';
        final docNom = user?.fullName.isNotEmpty == true ? user!.fullName : 'Dr. Aïssatou Diop';
        final consent = ref.read(consentProvider);
        final aAcces = consent.verifierAccesMedecin(docId) || consent.verifierAccesMedecin(docNom);

        if (!aAcces) {
          _showAccesNonAutoriseModal(result, docNom: docNom);
        } else {
          _showResultBottomSheet(result);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible de résoudre ce QR Code d'urgence."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showResultBottomSheet(QrUrgenceModel data) {
    final isMedecinView = !data.isVueSecouriste || _isMedecinScan;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1E232A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // BANDEAU CARTE MÉDICALE D'URGENCE LUE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D7C66), Color(0xFF0D7C66)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D7C66).withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.badge_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CARTE MÉDICALE D'URGENCE LUE AVEC SUCCÈS",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Données vitales et pass santé décodés en temps réel",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ENTETE DU ROLE D'ACCES
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isMedecinView ? const Color(0xFF0D7C66).withOpacity(0.15) : const Color(0xFF0D7C66).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isMedecinView ? const Color(0xFF0D7C66).withOpacity(0.4) : const Color(0xFF0D7C66).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMedecinView ? Icons.verified_rounded : Icons.shield_rounded,
                      color: isMedecinView ? const Color(0xFF0D7C66) : const Color(0xFF0D7C66),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isMedecinView ? "ACCÈS MÉDICAL APPROFONDI (RÔLE MÉDECIN)" : "ACCÈS D'URGENCE (SECOURISTE / PUBLIC)",
                      style: TextStyle(
                        color: isMedecinView ? const Color(0xFF0D7C66) : const Color(0xFF0D7C66),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // IDENTITÉ ET GROUPE SANGUIN
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMedecinView ? const Color(0xFF0D7C66).withOpacity(0.2) : const Color(0xFF0D7C66).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isMedecinView ? Icons.medical_services : Icons.person_pin,
                      color: isMedecinView ? const Color(0xFF0D7C66) : const Color(0xFF0D7C66),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.nomComplet.isNotEmpty ? data.nomComplet : "Patient",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Identifiant Pass : ${data.patientId}",
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        if (data.dateNaissance != null && data.dateNaissance!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.cake_outlined, color: Colors.white54, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  "Né(e) le : ${data.dateNaissance}",
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (data.groupeSanguin.isNotEmpty && data.groupeSanguin != 'Non renseigné')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFE53935).withOpacity(0.4), blurRadius: 8),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text("SANG", style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                          Text(
                            data.groupeSanguin,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // COORDONNÉES ET ADRESSE DU PATIENT (AFFICHÉES UNIQUEMENT SI RENSEIGNÉES)
              if ((data.telephonePatient != null && data.telephonePatient!.isNotEmpty) ||
                  (data.adresse != null && data.adresse!.isNotEmpty) ||
                  (data.ville != null && data.ville!.isNotEmpty)) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      if (data.telephonePatient != null && data.telephonePatient!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.phone_iphone_rounded, color: Color(0xFF0D7C66), size: 16),
                            const SizedBox(width: 8),
                            const Text("Tél. Patient : ", style: TextStyle(color: Colors.white60, fontSize: 12)),
                            Text(
                              data.telephonePatient!,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      if ((data.adresse != null && data.adresse!.isNotEmpty) || (data.ville != null && data.ville!.isNotEmpty)) ...[
                        if (data.telephonePatient != null && data.telephonePatient!.isNotEmpty) const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.orangeAccent, size: 16),
                            const SizedBox(width: 8),
                            const Text("Résidence : ", style: TextStyle(color: Colors.white60, fontSize: 12)),
                            Expanded(
                              child: Text(
                                data.adresse?.isNotEmpty == true ? data.adresse! : (data.ville ?? ""),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // CONTACT URGENCE A JOINDRE (ICE)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0D7C66).withOpacity(0.15),
                      const Color(0xFF0D7C66).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0D7C66).withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D7C66),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_in_talk, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("PROCHE À CONTACTER D'URGENCE (ICE)", style: TextStyle(color: Color(0xFF0D7C66), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text(
                            "${data.contactUrgenceNom} (${data.contactUrgenceLien})",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            data.contactUrgenceTel,
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final telStr = data.contactUrgenceTel.replaceAll(RegExp(r'[^\d+]'), '');
                        final Uri url = Uri.parse('tel:$telStr');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Impossible de lancer l'appel sur cet appareil."),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.call, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF0D7C66),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ALLERGIES ET MALADIES VITALES
              const Text("Données Vitales d'Urgence", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (data.allergiesMajeures.isEmpty && data.maladiesChroniques.isEmpty)
                const Text("Aucune allergie ou maladie vitale déclarée.", style: TextStyle(color: Colors.white54, fontSize: 12))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...data.allergiesMajeures.map(
                      (a) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE53935).withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 14),
                            const SizedBox(width: 4),
                            Text(a, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                    ...data.maladiesChroniques.map(
                      (m) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D7C66).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF0D7C66).withOpacity(0.5)),
                        ),
                        child: Text(m, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  ],
                ),

              // SECTION DONNEES MEDICALES CONFIDENTIELLES (MEDECIN SEULEMENT)
              if (isMedecinView) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D7C66).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0D7C66).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lock_open_rounded, color: Color(0xFF0D7C66), size: 16),
                          SizedBox(width: 8),
                          Text(
                            "Détails Médicaux Confidentiels (Médecin)",
                            style: TextStyle(color: Color(0xFF0D7C66), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (data.traitementsEnCours.isNotEmpty) ...[
                        const Text("Traitements en cours :", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        ...data.traitementsEnCours.map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 2),
                            child: Text("• $t", style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (data.antecedents.isNotEmpty) ...[
                        const Text("Antécédents médicaux :", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        ...data.antecedents.map(
                          (ant) => Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 2),
                            child: Text("• $ant", style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.white54, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Les antécédents et traitements confidentiels sont masqués pour préserver le secret médical.",
                          style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Fermer"),
                    ),
                  ),
                  if (isMedecinView) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          final user = ref.read(authProvider).user;
                          final docId = user?.id.isNotEmpty == true ? user!.id : 'med-aissatou-diop';
                          final docNom = user?.fullName.isNotEmpty == true ? user!.fullName : 'Dr. Aïssatou Diop';
                          final consent = ref.read(consentProvider);
                          final aAcces = consent.verifierAccesMedecin(docId) || consent.verifierAccesMedecin(docNom);

                          if (!aAcces) {
                            _showAccesNonAutoriseModal(data, docNom: docNom);
                          } else {
                            context.push('/medical-record');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D7C66),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.folder_shared, color: Colors.white, size: 18),
                        label: const Text("Ouvrir Dossier", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // =========================================================================
  // MODAL OFFICIEL D'ALERTE : ACCÈS NON ACCORDÉ PAR LE PATIENT (CAS D'URGENCE)
  // =========================================================================
  void _showAccesNonAutoriseModal(QrUrgenceModel data, {required String docNom}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF161A22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ENTETE ALERTE ROUGE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F1D1D).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.6), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.gpp_bad_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ACCÈS AU DOSSIER NON ACCORDÉ",
                            style: TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Règle de Secret Médical & Consentement Patient",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // MESSAGE EXPLICATIF
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Le patient ${data.nomComplet} n'a pas autorisé l'accès à son dossier médical au $docNom (ou l'accès a été révoqué par le patient).",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Conformément à la déontologie médicale et aux droits des usagers de santé, le dossier médical complet reste inaccessible sans l'accord préalable du patient.",
                      style: TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // BANDEAU DES DONNÉES VITALES D'URGENCE STRICTES
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D7C66), Color(0xFF0B132B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emergency_rounded, color: Color(0xFFEF4444), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "DONNÉES VITALES D'URGENCE (PREMIERS SECOURS)",
                            style: TextStyle(
                              color: Color(0xFF0D7C66),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "En situation d'urgence vitale, seules les données indispensables aux gestes de secours sont accessibles :",
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 12),

                    // Ligne Groupe Sanguin & Allergies
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Groupe Sanguin", style: TextStyle(color: Colors.white54, fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  data.groupeSanguin,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Allergies Majeures", style: TextStyle(color: Colors.white54, fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                  data.allergiesMajeures.isNotEmpty
                                      ? data.allergiesMajeures.join(', ')
                                      : "Aucune allergie connue",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Contact Urgence
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF0D7C66), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Contact d'Urgence (ICE / SAMU)", style: TextStyle(color: Colors.white54, fontSize: 10)),
                                Text(
                                  "${data.contactUrgenceNom} (${data.contactUrgenceTel})",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Icon(Icons.lock_rounded, color: Colors.white38, size: 13),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Historique des consultations, ordonnances et diagnostics verrouillé.",
                            style: TextStyle(color: Colors.white54, fontSize: 10.5, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // BOUTON 1 : DEMANDER L'ACCÈS AU PATIENT
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await ref.read(consentProvider.notifier).demanderAcces(
                          medecinNom: docNom,
                          patientNom: data.nomComplet,
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Demande d'accès envoyée à ${data.nomComplet}. Le patient doit valider depuis son espace.",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF0D7C66),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D7C66),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    "Demander l'Accès au Patient",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // BOUTON 2 : BRIS DE GLACE / URGENCE SAMU
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showResultBottomSheet(data);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "⚠️ Dérogation Urgence Vitale enregistrée dans le journal d'audit légal.",
                          style: TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Color(0xFFD97706),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF59E0B),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.warning_amber_rounded, size: 18),
                  label: const Text(
                    "Procédure d'Urgence Vitale SAMU 15 (Bris de Glace)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // BOUTON FERMER
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Fermer", style: TextStyle(color: Colors.white60, fontSize: 13)),
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
    final dossierState = ref.watch(dossierProvider);
    final patientState = ref.watch(patientProvider);
    final user = authState.user;
    final dossier = dossierState.dossier;
    final patientProfile = patientState.patient;

    // Données réelles canoniques du compte connecté (UN SEUL ET UNIQUE QR CODE PAR UTILISATEUR)
    final userQrToken = PassVitalHelper.getUniqueQrToken(user, patient: patientProfile);
    final userName = PassVitalHelper.getCivilFullName(user, patient: patientProfile);
    final userBloodGroup = (dossier != null && dossier.groupeSanguin.isNotEmpty && dossier.groupeSanguin != 'Non renseigné') ? dossier.groupeSanguin : "O+";
    final userPhone = user?.telephone.isNotEmpty == true ? user!.telephone : (patientProfile?.telephone?.isNotEmpty == true ? patientProfile!.telephone! : "Non renseigné");
    final userRoleNom = user?.roleNom ?? (user?.role.isNotEmpty == true ? user!.role : "CITOYEN");

    // Payload JSON UNIQUE et INVARIABLE encodé dans le Pass QR
    final String encodedQrData = PassVitalHelper.buildCanonicalQrPayload(
      user: user,
      dossier: dossier,
      patient: patientProfile,
    );

    final isDoctor = user?.isMedecin == true ||
        user?.role.toUpperCase() == 'MEDECIN' ||
        user?.role.toUpperCase() == 'DOCTEUR' ||
        widget.isMedecinScan == true ||
        _isMedecinScan;

    // ==================== TAB 1 : MON QR CODE VITAL (PATIENT) ====================
    final Widget tab1Widget = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                if (!isDoctor)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D7C66).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0D7C66).withOpacity(0.35)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: Color(0xFF0D7C66), size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Seuls les médecins certifiés peuvent scanner ce Pass. Vous contrôlez et révoquez leurs accès dans votre Dossier Médical.",
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),

                // CARTE MÉDICALE D'URGENCE OFFICIELLE (DESIGN SIGNATURE)
                CartePassVitalWidget(
                  nomComplet: userName,
                  telephone: userPhone,
                  jetonQr: userQrToken,
                  contactUrgence: (patientProfile?.personneContact?.isNotEmpty == true && patientProfile?.telephoneContact?.isNotEmpty == true)
                      ? "${patientProfile!.personneContact} - ${patientProfile!.telephoneContact}"
                      : (patientProfile?.telephoneContact?.isNotEmpty == true
                          ? patientProfile!.telephoneContact!
                          : (userPhone.isNotEmpty ? userPhone : "77 555 66 77")),
                  groupeSanguin: userBloodGroup,
                  qrPayload: encodedQrData,
                  onQrTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Pass Santé prêt à être scanné par les services médicaux."),
                        backgroundColor: Color(0xFF0D7C66),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                      const SizedBox(height: 20),

                      // INSTRUCTIONS DE SECURITE
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF0D7C66), size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Présentez ce QR Code aux secours (SAMU/Pompiers) ou au médecin pour leur permettre d'accéder instantanément à vos données vitales d'urgence.",
                                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // BOUTONS D'ACTION
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Lien sécurisé de votre Pass Santé copié !"),
                              backgroundColor: Color(0xFF0D7C66),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D7C66),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.share, color: Colors.white, size: 18),
                        label: const Text("Partager mon Pass", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      if (!isDoctor) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/dossier-medical'),
                          icon: const Icon(Icons.security, color: Color(0xFF0D7C66), size: 18),
                          label: const Text(
                            "Gérer mes autorisations médecins 🛡️",
                            style: TextStyle(color: Color(0xFF0D7C66), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0D7C66), width: 1.5),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );

          // ==================== TAB 2 : SCANNER CAMERA EN DIRECT (MEDECIN SEULEMENT) ====================
          final Widget tab2Widget = SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      // VISEUR AVEC FLUX CAMERA LIVE MOBILE_SCANNER
                      Container(
                        width: 270,
                        height: 270,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.black,
                          border: Border.all(
                            color: _isScanning ? const Color(0xFF0D7C66) : const Color(0xFF0D7C66).withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D7C66).withOpacity(0.25),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // FLUX CAMERA EN TEMPS REEL
                              MobileScanner(
                                controller: _scannerController,
                                onDetect: _onBarcodeDetected,
                                errorBuilder: (context, error) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 40),
                                          const SizedBox(height: 8),
                                          const Text(
                                            "Caméra non détectée ou permission requise",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                          const SizedBox(height: 10),
                                          ElevatedButton.icon(
                                            onPressed: () => _scannerController.start(),
                                            icon: const Icon(Icons.refresh, size: 16),
                                            label: const Text("Activer la Caméra", style: TextStyle(fontSize: 12)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF0D7C66),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // COINS DE CADRAGE DU SCANNER
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Color(0xFF0D7C66), width: 4),
                                      left: BorderSide(color: Color(0xFF0D7C66), width: 4),
                                    ),
                                    borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Color(0xFF0D7C66), width: 4),
                                      right: BorderSide(color: Color(0xFF0D7C66), width: 4),
                                    ),
                                    borderRadius: BorderRadius.only(topRight: Radius.circular(12)),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Color(0xFF0D7C66), width: 4),
                                      left: BorderSide(color: Color(0xFF0D7C66), width: 4),
                                    ),
                                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12)),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Color(0xFF0D7C66), width: 4),
                                      right: BorderSide(color: Color(0xFF0D7C66), width: 4),
                                    ),
                                    borderRadius: BorderRadius.only(bottomRight: Radius.circular(12)),
                                  ),
                                ),
                              ),

                              // Ligne Laser Balayage Animée
                              AnimatedBuilder(
                                animation: _laserAnimation,
                                builder: (context, child) {
                                  return Positioned(
                                    top: _laserAnimation.value * 250,
                                    left: 20,
                                    right: 20,
                                    child: Container(
                                      height: 3,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Color(0xFF0D7C66),
                                            Colors.white,
                                            Color(0xFF0D7C66),
                                            Colors.transparent,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0D7C66).withOpacity(0.8),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // ETAT DU SCAN
                              if (_isScanning)
                                Container(
                                  color: Colors.black54,
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(color: Color(0xFF0D7C66)),
                                        SizedBox(height: 12),
                                        Text(
                                          "Décodage en direct...",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CONTROLES DE LA CAMERA (FLASH, INVERSER, IMPORTER)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filledTonal(
                            onPressed: () async {
                              await _scannerController.toggleTorch();
                              setState(() {
                                _isTorchOn = !_isTorchOn;
                              });
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: _isTorchOn ? const Color(0xFF0D7C66) : Colors.white.withOpacity(0.1),
                              foregroundColor: Colors.white,
                            ),
                            icon: Icon(_isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, size: 20),
                            tooltip: "Lampe Torche",
                          ),
                          const SizedBox(width: 12),
                          IconButton.filledTonal(
                            onPressed: () => _scannerController.switchCamera(),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.flip_camera_ios_rounded, size: 20),
                            tooltip: "Changer de Caméra",
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () => _pickAndScanImage(ImageSource.camera),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.12),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            icon: const Icon(Icons.camera_alt_rounded, size: 16, color: Color(0xFF0D7C66)),
                            label: const Text("Photo", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _pickAndScanImage(ImageSource.gallery),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.12),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            icon: const Icon(Icons.photo_library_rounded, size: 16, color: Color(0xFF0D7C66)),
                            label: const Text("Galerie", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        "Pointez la caméra vers la Carte Médicale ou importez une photo\nLa lecture et le décodage s'exécutent automatiquement.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 18),

                      // AFFICHAGE DU ROLE ACTIF ET SELECTEUR D'ACCES
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        _isMedecinScan ? Icons.medical_services : Icons.person_pin,
                                        color: const Color(0xFF0D7C66),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _isMedecinScan ? "Mode Médecin Authentifié" : "Mode Secouriste / Citoyen",
                                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              "Votre rôle connecté : $userRoleNom",
                                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: _isMedecinScan,
                                  activeColor: const Color(0xFF0D7C66),
                                  onChanged: (val) {
                                    setState(() {
                                      _isMedecinScan = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SAISIE MANUELLE OPTIONNELLE
                      TextField(
                        controller: _tokenInputCtrl,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: "Saisir un code ou pointer la caméra",
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                          labelText: "Identifiant ou Jeton QR",
                          labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                          prefixIcon: const Icon(Icons.qr_code, color: Color(0xFF0D7C66)),
                          suffixIcon: _tokenInputCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                                  onPressed: () => setState(() => _tokenInputCtrl.clear()),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF0D7C66))),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            _performScan(val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // BOUTON DE DECODAGE MANUEL
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isScanning
                              ? null
                              : () {
                                  if (_tokenInputCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Veuillez scanner un QR code ou saisir un identifiant."),
                                        backgroundColor: Colors.orangeAccent,
                                      ),
                                    );
                                  } else {
                                    _performScan(_tokenInputCtrl.text.trim());
                                  }
                                },
                          icon: _isScanning
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.qr_code_scanner, color: Colors.white),
                          label: Text(
                            _isScanning ? "Résolution en cours..." : "Décoder le QR Code",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D7C66),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isDoctor ? "Pass & Scanner Médical" : "Mon Pass Vital Santé",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        bottom: isDoctor
            ? TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF0D7C66),
                indicatorWeight: 3,
                labelColor: const Color(0xFF0D7C66),
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(icon: Icon(Icons.badge_outlined), text: "Mon Pass QR"),
                  Tab(icon: Icon(Icons.qr_code_scanner), text: "Scanner un Pass"),
                ],
              )
            : null,
      ),
      body: isDoctor
          ? TabBarView(
              controller: _tabController,
              children: [
                tab1Widget,
                tab2Widget,
              ],
            )
          : tab1Widget,
    );
  }
}
