import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final nomComplet = user != null && user.fullName.trim().isNotEmpty
        ? (user.role == 'MEDECIN' ? "Dr. ${user.fullName}" : user.fullName)
        : "Utilisateur";
    final telephone = user?.telephone ?? "Non renseigné";
    final email = user?.email ?? "Non renseigné";
    final role = user?.roleNom ?? "Utilisateur";
    final isDoctor = user?.isMedecin == true || user?.role == 'MEDECIN';

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
          "Mon Profil",
          style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF00A884), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00A884).withValues(alpha: 0.15),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/default_avatar.png',
                                    fit: BoxFit.cover,
                                    width: 90,
                                    height: 90,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00A884),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          nomComplet,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7F3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF00A884), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildInfoTile(Icons.phone_outlined, "Téléphone", telephone),
                        _buildInfoTile(Icons.email_outlined, "Email", email),
                        _buildInfoTile(Icons.badge_outlined, "Statut du compte", "Vérifié & Sécurisé (OTP)"),
                        const SizedBox(height: 16),
                        _buildMenuTile(Icons.settings_outlined, "Paramètres du compte", () => context.push('/account-settings')),
                        _buildMenuTile(Icons.folder_shared_outlined, "Mon Dossier Médical", () => context.push('/medical-record', extra: {'isSelf': true})),
                        _buildMenuTile(Icons.family_restroom, "Ma Famille / Mes Proches", () => context.push('/family')),
                        _buildMenuTile(Icons.account_balance_wallet_outlined, "Mon Portefeuille Santé", () => context.push('/wallet')),
                        _buildMenuTile(Icons.calendar_month_outlined, isDoctor ? "Rendez-vous Patients & Téléconsultations" : "Mes Rendez-vous Médicaux", () => context.push('/appointments')),
                        _buildMenuTile(Icons.qr_code_rounded, "Mon QR Code Urgence Vital", () => context.push('/qr-scanner', extra: {'tab': 0})),
                        if (isDoctor) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "ESPACE PRATICIEN",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00A884),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildMenuTile(Icons.calendar_today_outlined, "Mon Agenda & Disponibilités", () => context.push('/doctor-agenda')),
                          _buildMenuTile(Icons.people_outline, "Gestion des Patients Suivis", () => context.push('/medical-record', extra: {'isDoctor': true})),
                          _buildMenuTile(Icons.qr_code_scanner, "Scanner le QR d'un Patient", () => context.push('/qr-scanner', extra: {'tab': 1, 'isMedecin': true})),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE2E2),
                      foregroundColor: const Color(0xFFEF4444),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text("Se déconnecter", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00A884), size: 18),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF475569), size: 18),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E293B))),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }
}
