import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/wallet_api_service.dart';

class EcranPortefeuille extends ConsumerStatefulWidget {
  const EcranPortefeuille({super.key});

  @override
  ConsumerState<EcranPortefeuille> createState() => _EcranPortefeuilleState();
}

class _EcranPortefeuilleState extends ConsumerState<EcranPortefeuille> {
  bool _afficherSolde = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null && user.id.isNotEmpty) {
        ref.read(walletProvider.notifier).loadUserWallet(user.id);
      }
    });
  }

  void _afficherDialogueDepot() {
    final controleurMontant = TextEditingController(text: "5000");
    final controleurTel = TextEditingController(text: "+221 77 000 00 00");
    String moyenPaiement = "Wave";

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 25, offset: Offset(0, 10)),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A884).withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF00A884), size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Recharger mon compte",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Moyen de paiement", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF8E95A5))),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setDialogState(() => moyenPaiement = "Wave"),
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: moyenPaiement == "Wave" ? const Color(0xFF00A884).withValues(alpha: 0.1) : const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: moyenPaiement == "Wave" ? const Color(0xFF00A884) : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Image.asset('assets/images/wave.png', height: 35),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setDialogState(() => moyenPaiement = "Orange Money"),
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: moyenPaiement == "Orange Money" ? const Color(0xFFFF9F65).withValues(alpha: 0.1) : const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: moyenPaiement == "Orange Money" ? const Color(0xFFFF9F65) : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Image.asset('assets/images/orange.png', height: 35),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text("Numéro de téléphone", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF8E95A5))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controleurTel,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Color(0xFF8E95A5)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text("Montant (FCFA)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF8E95A5))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: controleurMontant,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              prefixIcon: const Icon(Icons.payments_rounded, color: Color(0xFF8E95A5)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text("Annuler", style: TextStyle(color: Color(0xFF8E95A5), fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF00A884), Color(0xFF146C38)]),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: const Color(0xFF00A884).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                                      final montant = double.tryParse(controleurMontant.text) ?? 5000;
                                      Navigator.pop(context);
                                      final success = await ref.read(walletProvider.notifier).recharger(
                                            montant: montant,
                                            moyenPaiement: moyenPaiement.toUpperCase(),
                                            numeroTelephone: controleurTel.text,
                                          );
                                      scaffoldMessenger.showSnackBar(
                                        SnackBar(
                                          content: Text(success ? "Recharge de ${montant.toStringAsFixed(0)} FCFA effectuée avec succès !" : "Erreur de recharge"),
                                          backgroundColor: success ? const Color(0xFF00A884) : Colors.red,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: const Text("Valider", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
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
            ),
          ),
        ),
      ),
    );
  }

  void _afficherDialogueAjoutProche() {
    final telController = TextEditingController();
    String lienSelectionne = "Enfant";
    final plafondController = TextEditingController(text: "25000");
    final List<String> optionsLiens = [
      "Enfant",
      "Conjoint(e)",
      "Parent",
      "Frère/Sœur",
      "Autre",
    ];

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 25, offset: Offset(0, 10)),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A884).withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.person_add_rounded, color: Color(0xFF00A884), size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Inviter un proche",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Informations", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF8E95A5))),
                          const SizedBox(height: 12),
                          TextField(
                            controller: telController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                            decoration: InputDecoration(
                              labelText: "Téléphone (+221...)",
                              labelStyle: const TextStyle(color: Color(0xFF8E95A5)),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Color(0xFF8E95A5)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: lienSelectionne,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8E95A5)),
                            decoration: InputDecoration(
                              labelText: "Lien de parenté",
                              labelStyle: const TextStyle(color: Color(0xFF8E95A5)),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              prefixIcon: const Icon(Icons.family_restroom_rounded, color: Color(0xFF8E95A5)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            items: optionsLiens.map((lien) => DropdownMenuItem<String>(value: lien, child: Text(lien, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3142))))).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => lienSelectionne = val);
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: plafondController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                            decoration: InputDecoration(
                              labelText: "Plafond mensuel alloué (FCFA)",
                              labelStyle: const TextStyle(color: Color(0xFF8E95A5)),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF8E95A5)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text("Annuler", style: TextStyle(color: Color(0xFF8E95A5), fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF00A884), Color(0xFF146C38)]),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: const Color(0xFF00A884).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (telController.text.trim().isNotEmpty) {
                                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                                        final api = ref.read(walletApiServiceProvider);
                                        final walletSt = ref.read(walletProvider);
                                        
                                        final procheInfo = await api.rechercherUserParTelephone(telController.text.trim());
                                        if (procheInfo == null) {
                                          scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Ce numéro n'est associé à aucun compte santé."), backgroundColor: Colors.red));
                                          return;
                                        }
                                        
                                        final plafond = double.tryParse(plafondController.text.trim());
                                        final success = await api.inviterProche(
                                          tuteurUserId: walletSt.portefeuille!.userId,
                                          beneficiaireUserId: procheInfo['id'],
                                          lien: lienSelectionne,
                                          plafond: plafond,
                                        );
                                        
                                        if (context.mounted) Navigator.pop(context);
                                        if (success) {
                                          final nomComplet = "${procheInfo['firstName'] ?? ''} ${procheInfo['lastName'] ?? ''}".trim();
                                          WalletApiService.cacheUserName(procheInfo['id'], nomComplet);
                                          scaffoldMessenger.showSnackBar(SnackBar(content: Text("Invitation envoyée à $nomComplet"), backgroundColor: const Color(0xFF00A884)));
                                          ref.read(walletProvider.notifier).rechargerDonnees();
                                        } else {
                                          scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Erreur lors de l'envoi de l'invitation"), backgroundColor: Colors.red));
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: const Text("Inviter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
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
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final solde = walletState.portefeuille?.solde ?? 0.0;
    final transactions = walletState.transactions;

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
          "Portefeuille Santé",
          style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2D3142)),
            tooltip: "Actualiser",
            onPressed: () {
              final user = ref.read(authProvider).user;
              if (user != null && user.id.isNotEmpty) {
                ref.read(walletProvider.notifier).loadUserWallet(user.id);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(20),
            child: RefreshIndicator(
              color: const Color(0xFF00A884),
              onRefresh: () async {
                final user = ref.read(authProvider).user;
                if (user != null && user.id.isNotEmpty) {
                  await ref.read(walletProvider.notifier).loadUserWallet(user.id);
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00A884), Color(0xFF146C38)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00A884).withValues(alpha: 0.3),
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
                              "Solde Disponible Diam Yaraam",
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            IconButton(
                              icon: Icon(
                                _afficherSolde ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: Colors.white70,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _afficherSolde = !_afficherSolde),
                            ),
                          ],
                        ),
                        Text(
                          _afficherSolde ? "${solde.toStringAsFixed(0)} FCFA" : "•••••••• FCFA",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _afficherDialogueDepot,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF00A884),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: const Text("Recharger", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _afficherDialogueAjoutProche,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.people_outline, size: 20),
                                label: const Text("Payer un proche", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (walletState.mesInvitations.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Icon(Icons.mark_email_unread_outlined, color: Color(0xFFE65100), size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          "Invitations reçues",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${walletState.mesInvitations.length}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...walletState.mesInvitations.map((invit) {
                      final tuteurId = invit['portefeuille']?['userId']?.toString();
                      final tuteurNom = invit['nomTuteur'] ??
                          (tuteurId != null ? WalletApiService.getNomUtilisateur(tuteurId) : "Un proche");
                      final rawLien = invit['lienParente']?.toString() ?? 'bénéficiaire';
                      final lien = rawLien.toLowerCase();
                      final rawPlafond = invit['plafondMensuel'];
                      final plafondTexte = (rawPlafond != null && (rawPlafond is num ? rawPlafond > 0 : (double.tryParse(rawPlafond.toString()) ?? 0) > 0))
                          ? "${rawPlafond is num ? rawPlafond.toInt() : (double.tryParse(rawPlafond.toString())?.toInt() ?? rawPlafond)} FCFA / mois"
                          : "Illimité";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E7),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFFB74D), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE0B2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.shield_outlined, color: Color(0xFFE65100), size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    "Demande de prise en charge financière",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    border: Border.all(color: const Color(0xFFFFB74D)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "En attente",
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 13, color: Color(0xFF4A5568), height: 1.4),
                                children: [
                                  TextSpan(
                                    text: tuteurNom,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                                  ),
                                  const TextSpan(text: " souhaite prendre en charge vos actes et consultations médicales en tant que "),
                                  TextSpan(
                                    text: lien,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A884)),
                                  ),
                                  const TextSpan(text: "."),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFFE0B2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.account_balance_wallet_outlined, size: 14, color: Color(0xFF8E95A5)),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Plafond mensuel : $plafondTexte",
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D3142)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () async {
                                    await ref.read(walletApiServiceProvider).repondreInvitation(invit['id'], "REJETER");
                                    if (mounted) {
                                      final user = ref.read(authProvider).user;
                                      if (user != null) {
                                        await ref.read(walletProvider.notifier).loadUserWallet(user.id);
                                      }
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Invitation déclinée avec succès."),
                                          backgroundColor: Colors.grey,
                                        ),
                                      );
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFD32F2F),
                                    side: const BorderSide(color: Color(0xFFD32F2F)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text("Refuser", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await ref.read(walletApiServiceProvider).repondreInvitation(invit['id'], "ACCEPTER");
                                    if (mounted) {
                                      final user = ref.read(authProvider).user;
                                      if (user != null) {
                                        await ref.read(walletProvider.notifier).loadUserWallet(user.id);
                                      }
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("Prise en charge autorisée ! $tuteurNom prendra en charge vos actes médicaux."),
                                          backgroundColor: const Color(0xFF00A884),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                                  label: const Text("Accepter", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00A884),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                    elevation: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Proches pris en charge",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                      ),
                      InkWell(
                        onTap: _afficherDialogueAjoutProche,
                        child: const Text(
                          "+ Ajouter",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00A884)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (walletState.mesBeneficiaires.isEmpty)
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
                          Icon(Icons.family_restroom, color: Color(0xFF8E95A5), size: 26),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Aucun proche pris en charge. Cliquez sur « Payer un proche » ou « + Ajouter » pour allouer un budget santé.",
                              style: TextStyle(fontSize: 12, color: Color(0xFF8E95A5)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...walletState.mesBeneficiaires.map((beneficiaire) {
                      final bool isAttente = beneficiaire['statut'] == 'EN_ATTENTE';
                      final bUserId = beneficiaire['beneficiaireUserId']?.toString() ?? '';
                      final nom = beneficiaire['nomBeneficiaire'] ??
                          WalletApiService.getNomUtilisateur(
                            bUserId,
                            fallbackLien: beneficiaire['lienParente']?.toString(),
                          );
                      final rawLien = beneficiaire['lienParente']?.toString() ?? 'Autre';
                      final lienFormate = rawLien.length > 1
                          ? (rawLien.substring(0, 1).toUpperCase() + rawLien.substring(1).toLowerCase())
                          : rawLien;
                      final plafond = beneficiaire['plafondMensuel'];
                      final plafondTexte = (plafond != null && (plafond is num ? plafond > 0 : (double.tryParse(plafond.toString()) ?? 0) > 0))
                          ? "${plafond is num ? plafond.toInt() : plafond} FCFA"
                          : "Illimité";

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
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isAttente ? const Color(0xFFFFF4E5) : const Color(0xFFE6F7F3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.person_outline, color: isAttente ? const Color(0xFFFFB74D) : const Color(0xFF00A884)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nom,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Lien : $lienFormate • Plafond : $plafondTexte",
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF8E95A5)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isAttente ? const Color(0xFFFFF4E5) : const Color(0xFFE6F7F3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isAttente ? "En attente" : "Actif",
                                style: TextStyle(color: isAttente ? const Color(0xFFFFB74D) : const Color(0xFF00A884), fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 28),
                  const Text(
                    "Historique des transactions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                  ),
                  const SizedBox(height: 12),

                  if (walletState.isLoading && transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(30),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(color: Color(0xFF00A884)),
                    )
                  else if (transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5E9F2)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, color: Color(0xFF8E95A5), size: 32),
                          SizedBox(height: 8),
                          Text(
                            "Aucune transaction récente",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3142)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Vos recharges et paiements apparaîtront ici.",
                            style: TextStyle(fontSize: 11, color: Color(0xFF8E95A5)),
                          ),
                        ],
                      ),
                    )
                  else
                    ...transactions.map((tx) {
                      final isRecharge = tx.estCredit;
                      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(tx.dateTransaction);

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
                                color: isRecharge ? const Color(0xFFE6F7F3) : const Color(0xFFFDE8E8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isRecharge ? Icons.add_circle_outline : Icons.remove_circle_outline,
                                color: isRecharge ? const Color(0xFF00A884) : const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.description.isNotEmpty
                                        ? tx.description
                                        : (isRecharge ? "Recharge Portefeuille Santé" : "Règlement Consultation Médicale"),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    "$dateStr • ${tx.moyenPaiement}",
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF8E95A5)),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${isRecharge ? '+' : '-'}${tx.montant.toStringAsFixed(0)} FCFA",
                              style: TextStyle(
                                color: isRecharge ? const Color(0xFF00A884) : const Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}
