import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EcranConnexion extends StatefulWidget {
  const EcranConnexion({super.key});

  @override
  State<EcranConnexion> createState() => _EcranConnexionState();
}

class _EcranConnexionState extends State<EcranConnexion> {
  final _controleurIdentifiant = TextEditingController();
  final _controleurMotDePasse = TextEditingController();
  bool _masquerMotDePasse = true;

  @override
  void dispose() {
    _controleurIdentifiant.dispose();
    _controleurMotDePasse.dispose();
    super.dispose();
  }

  void _seConnecter() {
    final identifiant = _controleurIdentifiant.text.trim();
    final motDePasse = _controleurMotDePasse.text.trim();

    if (identifiant.isNotEmpty && motDePasse.isNotEmpty) {
      context.go('/tableau-de-bord');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LOGO & TITRE EN FRANCAIS
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F2F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: Color(0xFF0D7C66),
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Diam Yaraam",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D7C66),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Connectez-vous à votre espace santé",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E95A5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // CHAMP TELEPHONE
                  const Text(
                    "Numéro de téléphone",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _controleurIdentifiant,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142)),
                    decoration: InputDecoration(
                      hintText: "Ex: +221771234567",
                      hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                      prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF94A3B8), size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0D7C66), width: 1.8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // CHAMP MOT DE PASSE
                  const Text(
                    "Mot de passe",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _controleurMotDePasse,
                    obscureText: _masquerMotDePasse,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142)),
                    decoration: InputDecoration(
                      hintText: "••••••••",
                      hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _masquerMotDePasse ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF94A3B8),
                        ),
                        onPressed: () => setState(() => _masquerMotDePasse = !_masquerMotDePasse),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0D7C66), width: 1.8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // BOUTON SE CONNECTER
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _seConnecter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D7C66),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Se connecter",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // LIEN INSCRIPTION
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Vous n'avez pas encore de compte ? ",
                          style: TextStyle(fontSize: 13, color: Color(0xFF8E95A5)),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/inscription'),
                          child: const Text(
                            "Créer un compte",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D7C66),
                            ),
                          ),
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
    );
  }
}
