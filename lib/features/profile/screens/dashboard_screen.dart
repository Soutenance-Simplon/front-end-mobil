import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dossier/providers/dossier_provider.dart';
import '../../medecin/providers/medecin_provider.dart';
import '../../notification/providers/notification_provider.dart';
import '../../patient/providers/patient_provider.dart';
import '../../patient/services/pass_vital_helper.dart';
import '../../rdv/providers/planning_provider.dart';
import '../../rdv/providers/rdv_provider.dart';
import '../../wallet/providers/wallet_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentNavIndex = 0;
  int _doctorModeIndex = 0; // 0 = Espace Praticien, 1 = Espace Patient & Santé
  bool _showBalance = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    await ref.read(authProvider.notifier).checkCurrentUser();
    final user = ref.read(authProvider).user;
    if (user != null) {
      // Charger le profil du patient et le dossier médical
      ref.read(patientProvider.notifier).loadProfile(patientId: user.id);
      ref.read(dossierProvider.notifier).loadDossier(patientId: user.id);

      final role = user.role.toUpperCase();
      if (role == 'MEDECIN') {
        ref.read(planningProvider.notifier).chargerCreneauxDuMedecin(user.id);
        ref.read(rdvProvider.notifier).loadAgendaMedecin(medecinId: user.id);
        ref.read(rdvProvider.notifier).loadMesRendezVous(patientId: user.id);
        ref.read(walletProvider.notifier).loadUserWallet(user.id);
      } else if (role == 'PATIENT') {
        ref.read(rdvProvider.notifier).loadMesRendezVous(patientId: user.id);
        ref.read(walletProvider.notifier).loadUserWallet(user.id);
      }
      ref.read(notificationProvider.notifier).chargerNotifications(userId: user.id);
      ref.read(medecinProvider.notifier).searchMedecins();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final role = (user?.role.toUpperCase() ?? 'PATIENT').trim();
    final notifState = ref.watch(notificationProvider);
    final walletState = ref.watch(walletProvider);
    final solde = walletState.portefeuille?.solde ?? 0.0;
    final nonLues = notifState.nonLuesCount;

    return Scaffold(
      backgroundColor: const Color(0xFF00A884),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/assistant-ia'),
        backgroundColor: const Color(0xFF0F172A), // Dark color to contrast with the green background
        tooltip: 'Assistant IA',
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            color: const Color(0xFFF8FAF9),
            child: Column(
              children: [
                _buildWaveTopHeader(solde, nonLues),
                if (role == 'MEDECIN') _buildDoctorModeSwitcher(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadDashboardData,
                    color: const Color(0xFF00A884),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: _buildRoleContent(role, user),
                    ),
                  ),
                ),
                _buildBottomNav(role),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // EN-TÊTE SUPÉRIEUR INSPIRÉ DE WAVE (#00A884)
  // ==========================================
  Widget _buildWaveTopHeader(double solde, int nonLues) {
    return Container(
      color: const Color(0xFF00A884),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bouton Paramètres / Profil (icône roue crantée à gauche)
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.settings, color: Colors.white, size: 26),
            tooltip: "Paramètres & Profil",
          ),

          // Solde Santé Masquable avec l'œil au centre (Signature Wave)
          InkWell(
            onTap: () {
              setState(() => _showBalance = !_showBalance);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_showBalance)
                    const Text(
                      "••••••••",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  else
                    Text(
                      "${solde.toStringAsFixed(0)} F",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 19,
                  ),
                ],
              ),
            ),
          ),

          // Cloche Notifications avec badge
          InkWell(
            onTap: () => context.push('/notifications'),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
                  if (nonLues > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "$nonLues",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SWITCHER MODE MÉDECIN / PATIENT (STYLE SEGMENTÉ WAVE)
  // ==========================================
  Widget _buildDoctorModeSwitcher() {
    return Container(
      color: const Color(0xFF00A884),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _doctorModeIndex = 0),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _doctorModeIndex == 0 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _doctorModeIndex == 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_services_rounded,
                        size: 15,
                        color: _doctorModeIndex == 0 ? const Color(0xFF00A884) : Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Espace Praticien",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: _doctorModeIndex == 0 ? const Color(0xFF00A884) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _doctorModeIndex = 1),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _doctorModeIndex == 1 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _doctorModeIndex == 1
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 15,
                        color: _doctorModeIndex == 1 ? const Color(0xFF00A884) : Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Espace Patient",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: _doctorModeIndex == 1 ? const Color(0xFF00A884) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CARTE QR SANTÉ FLOTTANTE (STYLE WAVE SÉNÉGAL)
  // ==========================================
  Widget _buildWaveFloatingHealthCard(dynamic user, {required bool isDoctor}) {
    final userModel = user is UserModel ? user : null;
    final dossier = ref.watch(dossierProvider).dossier;
    final patient = ref.watch(patientProvider).patient;

    // UN SEUL ET UNIQUE QR CODE PAR UTILISATEUR (STRICTEMENT IDENTIQUE EN PRATICIEN ET PATIENT)
    final qrData = PassVitalHelper.buildCanonicalQrPayload(
      user: userModel,
      dossier: dossier,
      patient: patient,
    );

    final civilName = PassVitalHelper.getCivilFullName(userModel, patient: patient);
    final displayName = userModel != null && userModel.isMedecin
        ? "Dr. $civilName"
        : civilName;
    final bloodGroup = (dossier != null && dossier.groupeSanguin.isNotEmpty && dossier.groupeSanguin != 'Non renseigné')
        ? dossier.groupeSanguin
        : "O+";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A884), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A884).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Disques décoratifs géométriques en arrière-plan
            Positioned(
              right: -35,
              top: -35,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ligne supérieure de la carte
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isDoctor ? "BADGE MÉDICAL ONMS" : "CARTE SANTÉ CITOYENNE",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          isDoctor ? "AGRÉÉ ONMS" : "GROUPE $bloodGroup",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Conteneur Blanc avec UNIQUEMENT le QR Code (Signature Wave)
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => context.push('/qr-scanner', extra: {'tab': 0, 'isMedecin': isDoctor}),
                          child: QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 120.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF00A884),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => context.push(
                            '/qr-scanner',
                            extra: {'tab': isDoctor ? 1 : 0, 'isMedecin': isDoctor},
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDoctor ? const Color(0xFFF1F5F9) : const Color(0xFFE6F7F3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDoctor ? const Color(0xFFE2E8F0) : const Color(0xFF00A884).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isDoctor ? Icons.camera_alt_rounded : Icons.badge_outlined,
                                  color: isDoctor ? const Color(0xFF0F172A) : const Color(0xFF00A884),
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isDoctor ? "Scanner" : "Voir ma Carte Complète",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isDoctor ? const Color(0xFF0F172A) : const Color(0xFF00A884),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Ligne inférieure avec Nom et Mascotte Diam-Yaraam
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.verified, color: Colors.white, size: 15),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mascotte / Sceau Diam-Yaraam Santé
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.favorite, color: Color(0xFF34D399), size: 13),
                            SizedBox(width: 4),
                            Text(
                              "Diam-Yaraam",
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // GRILLE DES 8 ACTIONS CIRCULAIRES UNIVERSELLES (ACCESSIBILITÉ ANALPHABÈTE)
  // ==========================================
  Widget _buildUniversalActionGrid({required bool isDoctor}) {
    final List<Map<String, dynamic>> items = isDoctor
        ? [
            {
              "title": "Patients",
              "icon": Icons.folder_shared_rounded,
              "bg": const Color(0xFFE6F7F3),
              "color": const Color(0xFF00A884),
              "route": "/medical-record",
            },
            {
              "title": "Mon Agenda",
              "icon": Icons.calendar_month_rounded,
              "bg": const Color(0xFFFEF3C7),
              "color": const Color(0xFFD97706),
              "route": "/doctor-agenda",
            },
            {
              "title": "Prescrire",
              "icon": Icons.auto_awesome,
              "bg": const Color(0xFFCCFBF1),
              "color": const Color(0xFF0D9488),
              "route": "/smart-prescription",
            },
            {
              "title": "Consulter",
              "icon": Icons.medical_information_rounded,
              "bg": const Color(0xFFFCE7F3),
              "color": const Color(0xFFE11D48),
              "route": "/new-consultation",
            },
            {
              "title": "Garde SAMU",
              "icon": Icons.emergency_rounded,
              "bg": const Color(0xFFFEE2E2),
              "color": const Color(0xFFDC2626),
              "route": "/qr-scanner",
              "extra": {"tab": 1, "isMedecin": true},
            },
            {
              "title": "Honoraires",
              "icon": Icons.account_balance_wallet_rounded,
              "bg": const Color(0xFFDCFCE7),
              "color": const Color(0xFF16A34A),
              "route": "/wallet",
            },
            {
              "title": "Téléconsult.",
              "icon": Icons.video_camera_front_rounded,
              "bg": const Color(0xFFEDE9FE),
              "color": const Color(0xFF7C3AED),
              "route": "/appointments",
            },
            {
              "title": "Mon Dossier",
              "icon": Icons.health_and_safety_rounded,
              "bg": const Color(0xFFE0E7FF),
              "color": const Color(0xFF4F46E5),
              "route": "/medical-record",
              "extra": {"isSelf": true},
            },
          ]
        : [
            {
              "title": "Docteur",
              "icon": Icons.medical_services_rounded,
              "bg": const Color(0xFFE6F7F3),
              "color": const Color(0xFF00A884),
              "route": "/doctors",
            },
            {
              "title": "Rendez-vous",
              "icon": Icons.calendar_month_rounded,
              "bg": const Color(0xFFFEF3C7),
              "color": const Color(0xFFD97706),
              "route": "/appointments",
            },
            {
              "title": "Médicaments",
              "icon": Icons.medication_rounded,
              "bg": const Color(0xFFCCFBF1),
              "color": const Color(0xFF0D9488),
              "route": "/medical-record",
            },
            {
              "title": "Mon Carnet",
              "icon": Icons.monitor_heart_rounded,
              "bg": const Color(0xFFFCE7F3),
              "color": const Color(0xFFE11D48),
              "route": "/medical-record",
              "extra": {"isSelf": true},
            },
            {
              "title": "Urgence 15",
              "icon": Icons.emergency_rounded,
              "bg": const Color(0xFFFEE2E2),
              "color": const Color(0xFFDC2626),
              "route": "/qr-scanner",
              "extra": {"tab": 0},
            },
            {
              "title": "Paiement",
              "icon": Icons.account_balance_wallet_rounded,
              "bg": const Color(0xFFDCFCE7),
              "color": const Color(0xFF16A34A),
              "route": "/wallet",
            },
            {
              "title": "Téléconsult.",
              "icon": Icons.videocam_rounded,
              "bg": const Color(0xFFEDE9FE),
              "color": const Color(0xFF7C3AED),
              "route": "/appointments",
            },
            {
              "title": "Famille",
              "icon": Icons.family_restroom_rounded,
              "bg": const Color(0xFFE0E7FF),
              "color": const Color(0xFF4F46E5),
              "route": "/family",
            },
          ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 14,
          crossAxisSpacing: 8,
          childAspectRatio: 0.84,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () {
              final route = item['route'] as String;
              if (route == '/smart-prescription' || route == '/new-consultation') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Veuillez d'abord sélectionner le patient concerné dans votre répertoire.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: Color(0xFFE11D48),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 4),
                  ),
                );
                context.push('/medical-record');
              } else {
                context.push(route, extra: item['extra']);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: item['bg'] as Color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (item['color'] as Color).withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['title'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // FIL D'ACTIVITÉS RÉCENTES (STYLE TRANSACTIONS WAVE)
  // ==========================================
  Widget _buildWaveRecentActivityFeed() {
    final walletState = ref.watch(walletProvider);
    final rdvState = ref.watch(rdvProvider);
    final txs = walletState.transactions;
    final rdvs = rdvState.mesRendezVous;

    final List<Map<String, dynamic>> activities = [];

    // Transactions de portefeuille réelles
    for (final tx in txs.take(4)) {
      final isCredit = tx.estCredit;
      final dateStr = DateFormat('dd MMM, HH:mm').format(tx.dateTransaction);
      activities.add({
        "titre": tx.description.isNotEmpty ? tx.description : "Transaction Portefeuille",
        "date": dateStr,
        "montant": "${isCredit ? '+' : '-'}${tx.montant.toStringAsFixed(0)}F",
        "isCredit": isCredit,
        "icone": isCredit ? Icons.add_circle_outline : Icons.payment_rounded,
        "route": "/wallet",
      });
    }

    // Rendez-vous médicaux récents
    for (final r in rdvs.take(2)) {
      final dateStr = DateFormat('dd MMM, HH:mm').format(r.dateHeure);
      final docName = r.medecinNom?.isNotEmpty == true ? r.medecinNom! : 'Médecin';
      activities.add({
        "titre": "Consultation $docName",
        "date": dateStr,
        "montant": r.statut == 'CONFIRME' ? "Confirmé" : (r.statut == 'TERMINE' ? "Terminé" : r.statut),
        "isCredit": false,
        "isStatus": true,
        "icone": Icons.event_available_rounded,
        "route": "/appointments",
      });
    }

    // Exemples réalistes Diam-Yaraam par défaut
    if (activities.isEmpty) {
      activities.addAll([
        {
          "titre": "Consultation Cabinet Dr. Cheikh Fall",
          "date": "02 sept., 20:16",
          "montant": "-5.000F",
          "isCredit": false,
          "icone": Icons.medical_services_outlined,
          "route": "/appointments",
        },
        {
          "titre": "Recharge Portefeuille Santé Wave",
          "date": "02 sept., 20:09",
          "montant": "+15.000F",
          "isCredit": true,
          "icone": Icons.account_balance_wallet_outlined,
          "route": "/wallet",
        },
        {
          "titre": "Ordonnance Médicale Validée",
          "date": "01 sept., 21:32",
          "montant": "Validé",
          "isCredit": false,
          "isStatus": true,
          "icone": Icons.medication_outlined,
          "route": "/medical-record",
        },
        {
          "titre": "Téléconsultation Dr. Aïssatou Diop",
          "date": "01 sept., 20:45",
          "montant": "-3.500F",
          "isCredit": false,
          "icone": Icons.videocam_outlined,
          "route": "/appointments",
        },
      ]);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Dernières Activités & Soins",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              InkWell(
                onTap: () => context.push('/wallet'),
                child: const Text(
                  "Voir tout",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00A884),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 0.8,
                color: Color(0xFFF1F5F9),
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final act = activities[index];
                final isCredit = act['isCredit'] == true;
                final isStatus = act['isStatus'] == true;

                return InkWell(
                  onTap: () => context.push(act['route'] as String),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                act['titre'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                act['date'] as String,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (isStatus)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F7F3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              act['montant'] as String,
                              style: const TextStyle(
                                color: Color(0xFF00A884),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        else
                          Text(
                            act['montant'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isCredit ? const Color(0xFF00A884) : const Color(0xFF0F172A),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleContent(String role, dynamic user) {
    switch (role) {
      case 'MEDECIN':
        if (_doctorModeIndex == 0) {
          return _buildDoctorDashboard(user);
        } else {
          return _buildDoctorAsPatientDashboard(user);
        }
      case 'ADMIN':
      case 'SUPERUSER':
        return _buildAdminDashboard(user);
      case 'PATIENT':
      default:
        return _buildPatientDashboard(user);
    }
  }

  // ==========================================
  // 1. DASHBOARD PATIENT (INSPIRÉ DE WAVE)
  // ==========================================
  Widget _buildPatientDashboard(dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWaveFloatingHealthCard(user, isDoctor: false),
        _buildUniversalActionGrid(isDoctor: false),
        _buildWaveRecentActivityFeed(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildDoctorsListSection(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ==========================================
  // DASHBOARD DU MÉDECIN EN MODE PATIENT
  // ==========================================
  Widget _buildDoctorAsPatientDashboard(dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWaveFloatingHealthCard(user, isDoctor: false),
        _buildUniversalActionGrid(isDoctor: false),
        _buildWaveRecentActivityFeed(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildDoctorsListSection(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ==========================================
  // 2. DASHBOARD MÉDECIN (MODE PRATICIEN)
  // ==========================================
  Widget _buildDoctorDashboard(dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWaveFloatingHealthCard(user, isDoctor: true),
        _buildUniversalActionGrid(isDoctor: true),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildDoctorStatsCard(),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildDoctorUpcomingAppointments(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ==========================================
  // 3. DASHBOARD ADMINISTRATEUR
  // ==========================================
  Widget _buildAdminDashboard(dynamic user) {
    final displayName = user != null && user.fullName.toString().trim().isNotEmpty
        ? user.fullName
        : "Admin Diam Yaraam";

    final notifState = ref.watch(notificationProvider);
    final nonLues = notifState.nonLuesCount;

    final List<Map<String, dynamic>> adminActions = [
      {
        "titre": "Agrément ONMS",
        "sousTitre": "Vérification Identité",
        "icone": Icons.verified_user_rounded,
        "route": "/upload-id",
        "accentColor": const Color(0xFF00A884),
      },
      {
        "titre": "Annuaire Médical",
        "sousTitre": "Gestion Praticiens",
        "icone": Icons.medical_services_rounded,
        "route": "/doctors",
        "accentColor": const Color(0xFF00A884),
      },
      {
        "titre": "Supervision RDV",
        "sousTitre": "Flux Téléconsultations",
        "icone": Icons.monitor_heart_rounded,
        "route": "/appointments",
        "accentColor": const Color(0xFF00A884),
      },
      {
        "titre": "Audit Financier",
        "sousTitre": "Transactions & Wallets",
        "icone": Icons.receipt_long_rounded,
        "route": "/wallet",
        "accentColor": const Color(0xFF00A884),
      },
      {
        "titre": "Assistant IA",
        "sousTitre": "Triage & Diagnostics",
        "icone": Icons.auto_awesome,
        "route": "/assistant-ia",
        "accentColor": const Color(0xFF00A884),
      },
      {
        "titre": "Notifications",
        "sousTitre": "Alertes Globales",
        "icone": Icons.campaign_rounded,
        "route": "/notifications",
        "accentColor": const Color(0xFF00A884),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          avatarColor: const Color(0xFF00A884),
          badgeText: "Administration Centrale",
          badgeColor: const Color(0xFF00A884),
          displayName: displayName,
          nonLues: nonLues,
        ),
        const SizedBox(height: 18),
        _buildAdminStatusCard(),
        const SizedBox(height: 24),
        _buildSectionTitle("Supervision & Administration"),
        const SizedBox(height: 12),
        _buildServiceGrid(adminActions),
        const SizedBox(height: 24),
        _buildAdminLogsSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  // ==========================================
  // WIDGETS COMMUNS ET COMPOSANTS
  // ==========================================
  Widget _buildHeader({
    required Color avatarColor,
    required String badgeText,
    required Color badgeColor,
    required String displayName,
    required int nonLues,
  }) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE6F7F3), Color(0xFFCCF2E7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00A884).withValues(alpha: 0.25), width: 1.5),
              ),
              child: const Icon(Icons.person, color: Color(0xFF00A884), size: 28),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF00A884),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, size: 16, color: Color(0xFF00A884)),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00A884).withValues(alpha: 0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 6, color: Color(0xFF00A884)),
                    const SizedBox(width: 5),
                    Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF00A884),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () => context.push('/notifications'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_outlined,
                  color: Color(0xFF475569),
                  size: 22,
                ),
                if (nonLues > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "$nonLues",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildDoctorStatsCard() {
    final rdvState = ref.watch(rdvProvider);
    final planningState = ref.watch(planningProvider);

    final now = DateTime.now();
    final rdvAujourdhui = rdvState.agendaMedecin.where((r) {
      return r.dateHeure.year == now.year &&
          r.dateHeure.month == now.month &&
          r.dateHeure.day == now.day &&
          r.statut != 'ANNULE';
    }).length;

    final teleconsultations = rdvState.agendaMedecin.where((r) {
      return r.typeConsultation == 'TELECONSULTATION' && r.statut != 'ANNULE';
    }).length;

    final creneauxLibres = planningState.tousLesCreneaux.where((c) {
      return c.statut == 'DISPONIBLE';
    }).length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A884), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A884).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -25,
              top: -25,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.medical_services_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            "Tableau de Garde Praticien",
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.30),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Color(0xFF34D399), size: 7),
                            SizedBox(width: 5),
                            Text("DISPONIBLE", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push('/doctor-agenda'),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$rdvAujourdhui",
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 2),
                                const Text("Aujourd'hui", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push('/appointments'),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$teleconsultations",
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 2),
                                const Text("Téléconsult.", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push('/doctor-agenda'),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$creneauxLibres",
                                  style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 24, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 2),
                                const Text("Créneaux", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/doctor-agenda'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF00A884),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: const Text("Gérer Créneaux", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/qr-scanner', extra: {'tab': 0, 'isMedecin': true}),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.18),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          icon: const Icon(Icons.qr_code_rounded, size: 16),
                          label: const Text("Mon QR Code", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A884), Color(0xFF053B2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A884).withValues(alpha: 0.20),
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
              const Text(
                'État Système & Microservices',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('MICROSERVICES ACTIFS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Tableau de bord administrateur',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Les statistiques en temps réel sont disponibles via les APIs de supervision.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/doctors'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF00A884),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            ),
            icon: const Icon(Icons.analytics_rounded, size: 18),
            label: const Text('Voir Annuaire Médical', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9F2)),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (val) => context.push('/doctors'),
        decoration: InputDecoration(
          hintText: "Rechercher médecin, cardiologue, pédiatre...",
          hintStyle: const TextStyle(color: Color(0xFFB4B9C5), fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF00A884)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF5A607F), size: 20),
            onPressed: () => context.push('/doctors'),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3142),
      ),
    );
  }

  Widget _buildServiceGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final action = items[index];
        final isDanger = action['isDanger'] == true;
        final Color accentColor = action['accentColor'] as Color? ?? const Color(0xFF00A884);
        final Color iconBg = isDanger ? const Color(0xFFFEE2E2) : const Color(0xFFE6F7F3);
        final Color iconColor = isDanger ? const Color(0xFFEF4444) : accentColor;

        return InkWell(
          onTap: () => context.push(action['route'] as String, extra: action['extra']),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDanger
                    ? const Color(0xFFFECACA)
                    : const Color(0xFF00A884).withValues(alpha: 0.12),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(action['icone'] as IconData, color: iconColor, size: 20),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAF9),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 9,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action['titre'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action['sousTitre'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorsListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Médecins Agréés ONMS",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            InkWell(
              onTap: () => context.push('/doctors'),
              child: const Text(
                "Voir tout",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A884),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildSearchBar(),
        const SizedBox(height: 14),
        if (ref.watch(medecinProvider).isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (ref.watch(medecinProvider).medecins.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text("Aucun médecin disponible pour le moment", style: TextStyle(color: Color(0xFF8E95A5))),
          )
        else
          ...ref.watch(medecinProvider).medecins.take(3).map((med) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                          "Dr. ${med.prenom} ${med.nom}".trim(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142)),
                        ),
                        Text(
                          "${med.specialite} - ${med.ville}",
                          style: const TextStyle(fontSize: 11, color: Color(0xFF8E95A5)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "${med.tarifConsultation.toInt()} FCFA",
                          style: const TextStyle(fontSize: 11, color: Color(0xFF00A884), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push('/book-appointment', extra: med),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    child: const Text("Prendre RDV", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildDoctorUpcomingAppointments() {
    final rdvState = ref.watch(rdvProvider);
    final now = DateTime.now();
    final rdvsDuJour = rdvState.agendaMedecin.where((r) {
      return r.dateHeure.year == now.year &&
          r.dateHeure.month == now.month &&
          r.dateHeure.day == now.day &&
          r.statut != 'ANNULE';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Consultations du Jour",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            InkWell(
              onTap: () => context.push('/doctor-agenda'),
              child: const Text(
                "Voir Agenda",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A884),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (rdvsDuJour.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E9F2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.event_available, color: Color(0xFF00A884), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Aucune consultation programmée pour aujourd'hui.",
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          )
        else
          ...rdvsDuJour.map((rdv) {
            final isVisio = rdv.typeConsultation == 'TELECONSULTATION';
            final heureStr = DateFormat('HH:mm').format(rdv.dateHeure);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E9F2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isVisio ? const Color(0xFFE6F7F3) : const Color(0xFFE6F7F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isVisio ? Icons.videocam_rounded : Icons.local_hospital_rounded,
                      color: isVisio ? const Color(0xFF00A884) : const Color(0xFF00A884),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rdv.motif.isNotEmpty ? rdv.motif : "Consultation Patient",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          "${isVisio ? 'Téléconsultation' : 'Cabinet'} • $heureStr",
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push('/appointments'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isVisio ? const Color(0xFF00A884) : const Color(0xFF00A884),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      isVisio ? "Rejoindre" : "Détails",
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAdminLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dernières Activités Plateforme',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3142),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E9F2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF00A884), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Journal d\'activité',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Text(
                      'Les activités récentes sont disponibles via l\'API d\'audit.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8E95A5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildBottomNav(String role) {
    switch (role) {
      case 'MEDECIN':
        if (_doctorModeIndex == 1) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_filled, route: '/dashboard'),
                _buildNavItem(1, Icons.calendar_month_outlined, route: '/appointments'),
                _buildNavItem(2, Icons.medical_services_outlined, route: '/doctors'),
                _buildNavItem(3, Icons.account_balance_wallet_outlined, route: '/wallet'),
                _buildNavItem(4, Icons.person_outline, route: '/profile'),
              ],
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_filled, route: '/dashboard'),
              _buildNavItem(1, Icons.calendar_month_rounded, route: '/doctor-agenda'),
              _buildNavItem(2, Icons.auto_awesome, route: '/smart-prescription'),
              _buildNavItem(3, Icons.qr_code_scanner_rounded, route: '/qr-scanner'),
              _buildNavItem(4, Icons.person_outline, route: '/profile'),
            ],
          ),
        );
      case 'ADMIN':
      case 'SUPERUSER':
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, route: '/dashboard'),
              _buildNavItem(1, Icons.medical_services_outlined, route: '/doctors'),
              _buildNavItem(2, Icons.receipt_long_rounded, route: '/wallet'),
              _buildNavItem(3, Icons.notifications_none_rounded, route: '/notifications'),
              _buildNavItem(4, Icons.person_outline, route: '/profile'),
            ],
          ),
        );
      case 'PATIENT':
      default:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_filled, route: '/dashboard'),
              _buildNavItem(1, Icons.calendar_month_outlined, route: '/appointments'),
              _buildNavItem(2, Icons.medical_services_outlined, route: '/doctors'),
              _buildNavItem(3, Icons.account_balance_wallet_outlined, route: '/wallet'),
              _buildNavItem(4, Icons.person_outline, route: '/profile'),
            ],
          ),
        );
    }
  }

  Widget _buildNavItem(int index, IconData icon, {required String route}) {
    final isSelected = _currentNavIndex == index;

    return InkWell(
      onTap: () {
        if (route == '/smart-prescription' || route == '/new-consultation') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Veuillez d'abord sélectionner le patient concerné dans votre répertoire.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Color(0xFFE11D48),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
          context.push('/medical-record');
          return;
        }

        setState(() => _currentNavIndex = index);
        if (route != '/dashboard') {
          context.push(route);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A884).withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF00A884) : const Color(0xFF8E95A5),
          size: 24,
        ),
      ),
    );
  }
}
