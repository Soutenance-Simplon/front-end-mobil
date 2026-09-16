import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/membre_famille_model.dart';
import '../../patient/services/patient_api_service.dart';
import '../../../core/network/api_client.dart';
import '../../wallet/services/wallet_api_service.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final PatientApiService _apiService = PatientApiService();
  final WalletApiService _walletService = WalletApiService();
  List<MembreFamille> _membres = [];
  List<Map<String, dynamic>> _invitations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFamily();
    _loadInvitations();
  }

  Future<void> _loadFamily() async {
    setState(() => _isLoading = true);
    final patientId = await ApiClient().getUserId() ?? '';
    
    if (patientId.isNotEmpty) {
      final result = await _apiService.getMembresFamille(patientId);
      setState(() {
        _membres = result;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadInvitations() async {
    final patientId = await ApiClient().getUserId() ?? '';
    if (patientId.isNotEmpty) {
      final invitations = await _walletService.getInvitations(patientId);
      setState(() {
        _invitations = invitations;
      });
    }
  }

  Future<void> _handleInvitation(String invitationId, bool accepted) async {
    final action = accepted ? "ACCEPTER" : "REJETER";
    final success = await _walletService.repondreInvitation(invitationId, action);
    if (success) {
      await _loadInvitations();
      if (accepted) await _loadFamily();
    }
  }

  // Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(String membreId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le lien de parenté'),
        content: const Text('Êtes‑vous sûr de vouloir supprimer ce membre de votre famille ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await _walletService.supprimerBeneficiaire(membreId);
      final scaffold = ScaffoldMessenger.of(context);
      if (success) {
        scaffold.showSnackBar(const SnackBar(content: Text('Membre supprimé'), backgroundColor: Colors.green));
        await _loadFamily();
      } else {
        scaffold.showSnackBar(const SnackBar(content: Text('Erreur lors de la suppression'), backgroundColor: Colors.red));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Ma Famille", style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A884)))
          : Column(
              children: [
                if (_invitations.isNotEmpty) _buildInvitationSection(),
                Expanded(child: _membres.isEmpty ? _buildEmptyState() : _buildFamilyList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/add-family-member');
          if (result == true) {
            _loadFamily();
          }
        },
        backgroundColor: const Color(0xFF00A884),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Ajouter un proche", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildInvitationSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline, color: Color(0xFFFF8F00), size: 22),
              const SizedBox(width: 8),
              Text(
                'Invitations reçues (${_invitations.length})',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._invitations.map((inv) {
            final lien = inv['lienParente'] ?? inv['lien'] ?? 'Proche';
            final invId = inv['id']?.toString() ?? '';
            final tuteurId = inv['portefeuille']?['userId']?.toString() ?? '';
            final displayId = tuteurId.length > 8 ? tuteurId.substring(0, 8) : tuteurId;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF00A884).withOpacity(0.1),
                        radius: 20,
                        child: const Icon(Icons.person_add, color: Color(0xFF00A884), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invitation de $displayId...',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Lien proposé : $lien',
                              style: const TextStyle(
                                color: Color(0xFF8D99AE),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _handleInvitation(invId, false),
                        icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                        label: const Text('Refuser', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _handleInvitation(invId, true),
                        icon: const Icon(Icons.check, size: 18, color: Colors.white),
                        label: const Text('Accepter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A884),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF00A884).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.family_restroom, size: 60, color: Color(0xFF00A884)),
          ),
          const SizedBox(height: 24),
          const Text(
            "Aucun proche ajouté",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
          const SizedBox(height: 12),
          const Text(
            "Ajoutez les membres de votre famille\npour gérer leurs dossiers médicaux\ndepuis votre compte.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8D99AE), fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _membres.length,
      itemBuilder: (context, index) {
        final membre = _membres[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF00A884).withOpacity(0.1),
              radius: 24,
              child: Icon(
                membre.genre == 'Femme' ? Icons.face_3 : Icons.face,
                color: const Color(0xFF00A884),
                size: 28,
              ),
            ),
            title: Text(
              "${membre.prenom} ${membre.nom}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142)),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                membre.lienParente,
                style: const TextStyle(color: Color(0xFF8D99AE), fontWeight: FontWeight.w500),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFF00A884), size: 20),
                    tooltip: "Prendre RDV pour ${membre.prenom}",
                    onPressed: () => _ouvrirPriseRendezVousPourMembre(membre),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  tooltip: "Supprimer",
                  onPressed: () => _showDeleteConfirmation(membre.id),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
              ],
            ),
            onTap: () => _afficherMenuActionsMembre(membre),
          ),
        );
      },
    );
  }

  void _ouvrirPriseRendezVousPourMembre(MembreFamille membre) {
    final enfantId = membre.enfantUserId.trim().isNotEmpty
        ? membre.enfantUserId.trim()
        : "FAM-${membre.id}";
    final nomComplet = "${membre.prenom} ${membre.nom}".trim();
    context.push('/doctors', extra: {
      'id': enfantId,
      'nom': nomComplet.isNotEmpty ? nomComplet : "Membre de la famille",
      'prenom': membre.prenom,
      'nomFamille': membre.nom,
      'lienParente': membre.lienParente,
      'isFamilyMember': true,
      'genre': membre.genre,
    });
  }

  void _ouvrirDossierMedicalMembre(MembreFamille membre) {
    final enfantId = membre.enfantUserId.trim().isNotEmpty
        ? membre.enfantUserId.trim()
        : "FAM-${membre.id}";
    final nomComplet = "${membre.prenom} ${membre.nom}".trim();
    context.push('/medical-record', extra: {
      'id': enfantId,
      'nom': nomComplet.isNotEmpty ? nomComplet : "Membre de la famille",
      'prenom': membre.prenom,
      'nomFamille': membre.nom,
      'lienParente': membre.lienParente,
      'isFamilyMember': true,
      'genre': membre.genre,
      'dateNaissance': membre.dateNaissance,
    });
  }

  void _afficherMenuActionsMembre(MembreFamille membre) {
    final nomComplet = "${membre.prenom} ${membre.nom}".trim();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFE6F7F3),
                      radius: 26,
                      child: Icon(
                        membre.genre == 'Femme' ? Icons.face_3 : Icons.face,
                        color: const Color(0xFF00A884),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nomComplet,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3142)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Lien de parenté : ${membre.lienParente}",
                            style: const TextStyle(color: Color(0xFF8D99AE), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF00A884)),
                  ),
                  title: Text(
                    "Prendre un rendez-vous pour ${membre.prenom}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3142)),
                  ),
                  subtitle: const Text("Trouver un praticien et planifier une consultation"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _ouvrirPriseRendezVousPourMembre(membre);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.folder_shared_rounded, color: Color(0xFF5A607F)),
                  ),
                  title: const Text(
                    "Consulter son Dossier Médical",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3142)),
                  ),
                  subtitle: const Text("Allergies, constantes, historique de soins"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _ouvrirDossierMedicalMembre(membre);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
