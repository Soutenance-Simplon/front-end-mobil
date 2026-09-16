import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class EcgPulseLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  EcgPulseLinePainter({
    required this.color,
    this.strokeWidth = 1.6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final h = size.height;
    final mid = h / 2;
    final w = size.width;

    // L'onde ECG se situe vers le tiers droit avant le QR code
    final pStart = (w * 0.68).clamp(0.0, w);
    final pWidth = (w * 0.28).clamp(0.0, w - pStart);

    path.moveTo(0, mid);
    path.lineTo(pStart, mid);

    // Onde ECG : P -> Q -> R (pic haut) -> S (creux bas) -> T
    path.lineTo(pStart + pWidth * 0.15, mid - h * 0.18);
    path.lineTo(pStart + pWidth * 0.25, mid);
    path.lineTo(pStart + pWidth * 0.35, mid + h * 0.25);
    path.lineTo(pStart + pWidth * 0.50, mid - h * 0.90);
    path.lineTo(pStart + pWidth * 0.65, mid + h * 0.65);
    path.lineTo(pStart + pWidth * 0.80, mid - h * 0.20);
    path.lineTo(pStart + pWidth * 0.90, mid);
    path.lineTo(w, mid);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CartePassVitalWidget extends StatelessWidget {
  final String nomComplet;
  final String telephone;
  final String jetonQr;
  final String contactUrgence;
  final String groupeSanguin;
  final String qrPayload;
  final VoidCallback? onQrTap;
  final bool compact;

  const CartePassVitalWidget({
    super.key,
    required this.nomComplet,
    required this.telephone,
    required this.jetonQr,
    required this.contactUrgence,
    required this.groupeSanguin,
    required this.qrPayload,
    this.onQrTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayBloodGroup = groupeSanguin.trim().isNotEmpty ? groupeSanguin.trim() : "O+";
    final displayName = nomComplet.trim().isNotEmpty ? nomComplet.trim() : "Patient Diam-Yaraam";
    final displayPhone = telephone.trim().isNotEmpty ? telephone.trim() : "77 555 66 77";
    final displayToken = jetonQr.trim().isNotEmpty ? jetonQr.trim() : "QR-A4020B38A2824372847C4765A4C18C1F";
    final displayIce = contactUrgence.trim().isNotEmpty ? contactUrgence.trim() : "77 ................";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF032B22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00D09C).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(compact ? 14 : 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== EN-TÊTE : LOGO + TITRE + GROUPE SANGUIN ====================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/diamyaraam_tree_icon.png',
                    height: compact ? 34 : 42,
                    width: compact ? 34 : 42,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DIAM-YARAAM",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: compact ? 13.5 : 16,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        "Carte Médicale d'Urgence",
                        style: TextStyle(
                          color: const Color(0xFF00D09C),
                          fontSize: compact ? 9.5 : 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // BADGE GROUPE SANGUIN (PILULE BLANCHE SIGNATURE)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 14,
                  vertical: compact ? 3 : 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  displayBloodGroup,
                  style: TextStyle(
                    color: const Color(0xFF007A60),
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 13 : 16,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 10 : 14),

          // ==================== CORPS : INFOS PATIENT À GAUCHE & QR CODE À DROITE ====================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // COLONNE GAUCHE (DONNÉES DU PATIENT)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Prenom & Nom",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: TextStyle(
                        color: const Color(0xFF00D09C),
                        fontSize: compact ? 17 : 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // LIGNE PULSATION CARDIAQUE (ECG)
                    CustomPaint(
                      size: const Size(double.infinity, 20),
                      painter: EcgPulseLinePainter(
                        color: const Color(0xFF00D09C).withValues(alpha: 0.65),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // LIGNE 1 : NUMÉRO TÉLÉPHONE
                    _buildInfoRow(
                      icon: Icons.badge_outlined,
                      label: "Numero telephone",
                      value: displayPhone,
                      compact: compact,
                    ),

                    SizedBox(height: compact ? 6 : 8),

                    // LIGNE 2 : JETON QR SÉCURISÉ
                    _buildInfoRow(
                      icon: Icons.shield_rounded,
                      label: "Jeton QR Sécurisé",
                      value: displayToken,
                      isToken: true,
                      compact: compact,
                    ),

                    SizedBox(height: compact ? 6 : 8),

                    // LIGNE 3 : CONTACT D'URGENCE (ICE)
                    _buildInfoRow(
                      icon: Icons.phone_in_talk_rounded,
                      label: "Contact D'urgence",
                      value: displayIce,
                      compact: compact,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // COLONNE DROITE : LE CONTENEUR QR CODE (ARRONDI BLANC)
              GestureDetector(
                onTap: onQrTap,
                child: Container(
                  padding: EdgeInsets.all(compact ? 6 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrPayload,
                    version: QrVersions.auto,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                    size: compact ? 104.0 : 124.0,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF00A884),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF032B22),
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isToken = false,
    bool compact = false,
  }) {
    return Row(
      children: [
        Container(
          width: compact ? 28 : 32,
          height: compact ? 28 : 32,
          decoration: BoxDecoration(
            color: const Color(0xFF0E4337),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: const Color(0xFF00D09C).withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF00D09C),
            size: compact ? 14 : 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: compact ? 9.5 : 10.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: TextStyle(
                  color: const Color(0xFF00D09C),
                  fontSize: isToken ? (compact ? 8.5 : 9.5) : (compact ? 11.5 : 12.5),
                  fontWeight: FontWeight.bold,
                  letterSpacing: isToken ? 0.3 : 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
