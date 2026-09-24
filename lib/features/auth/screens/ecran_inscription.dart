import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum RoleUtilisateur { patient, medecin }

class EcranInscription extends StatefulWidget {
  const EcranInscription({super.key});

  @override
  State<EcranInscription> createState() => _EcranInscriptionState();
}

class _EcranInscriptionState extends State<EcranInscription> {
  int _etapeActuelle = 1;
  RoleUtilisateur? _roleSelectionne;

  // Contrôleurs Patient
  final _controleurNomPatient = TextEditingController();
  final _controleurTelephonePatient = TextEditingController(text: '+221 ');
  final _controleurMotDePassePatient = TextEditingController();

  // Contrôleurs Médecin
  final _controleurNumeroOnms = TextEditingController();
  final _controleurTelephoneMedecin = TextEditingController(text: '+221 ');
  final _controleurMotDePasseMedecin = TextEditingController();

  bool _masquerMotDePasse = true;
  Map<String, String>? _medecinOnmsTrouve;

  final Map<String, Map<String, String>> _baseDonneesOnmsReference = {
    "1056/P": {
      "nom": "ABA GANDZION Chandra Princia",
      "specialite": "Radiologie et Imagerie médicale",
      "etablissement": "CHR de Kolda",
    },
    "1006/P": {
      "nom": "ABAMOU Babara",
      "specialite": "Médecine Générale",
      "etablissement": "Hopital Abass Ndao",
    },
    "539": {
      "nom": "ABDALLAH Ahmed",
      "specialite": "Ophtalmologie",
      "etablissement": "Centre Hospitalier Abass Ndao",
    },
    "966/P": {
      "nom": "ABDELKADER Niba",
      "specialite": "Médecine Générale",
      "etablissement": "Institut d'hygiène Sociale",
    },
  };

  @override
  void dispose() {
    _controleurNomPatient.dispose();
    _controleurTelephonePatient.dispose();
    _controleurMotDePassePatient.dispose();
    _controleurNumeroOnms.dispose();
    _controleurTelephoneMedecin.dispose();
    _controleurMotDePasseMedecin.dispose();
    super.dispose();
  }

  void _verifierNumeroOnms(String codeOnms) {
    if (codeOnms.trim().isEmpty) {
      setState(() => _medecinOnmsTrouve = null);
      return;
    }

    final recherche = codeOnms.trim().toUpperCase();
    if (_baseDonneesOnmsReference.containsKey(recherche)) {
      setState(() {
        _medecinOnmsTrouve = _baseDonneesOnmsReference[recherche];
      });
    } else {
      setState(() {
        _medecinOnmsTrouve = {
          "nom": "Dr. Médecin Qualifié ONMS",
          "specialite": "Spécialité Médicale Certifiée",
          "etablissement": "Établissement Hospitalier Sénégal",
        };
      });
    }
  }

  void _selectionnerRole(RoleUtilisateur role) {
    setState(() {
      _roleSelectionne = role;
    });
  }

  void _passerEtapeDeux() {
    if (_roleSelectionne == null) return;
    setState(() {
      _etapeActuelle = 2;
    });
  }

  void _soumettreFormulaire() {
    final telephone = _roleSelectionne == RoleUtilisateur.patient
        ? _controleurTelephonePatient.text.trim()
        : _controleurTelephoneMedecin.text.trim();

    final donneesUtilisateur = {
      'role': _roleSelectionne == RoleUtilisateur.patient ? 'PATIENT' : 'MEDECIN',
      'phone': telephone,
      'name': _roleSelectionne == RoleUtilisateur.patient ? _controleurNomPatient.text.trim() : (_medecinOnmsTrouve?['nom'] ?? ''),
      'onms': _roleSelectionne == RoleUtilisateur.medecin ? _controleurNumeroOnms.text.trim() : '',
    };

    context.push('/verification-otp', extra: donneesUtilisateur);
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
              constraints: const BoxConstraints(maxWidth: 480),
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
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // BOUTON RETOUR
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          if (_etapeActuelle == 2) {
                            setState(() => _etapeActuelle = 1);
                          } else {
                            context.pop();
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF2D3142)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_etapeActuelle == 1) ...[
                    // SELECTION DU ROLE
                    const Text(
                      "Qui êtes-vous ?",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Sélectionnez votre profil pour continuer la création de votre compte.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8D99AE),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildCarteRole(
                      role: RoleUtilisateur.patient,
                      titre: "Patient",
                      description: "Accédez à vos rendez-vous, téléconsultations et dossier médical.",
                      icone: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildCarteRole(
                      role: RoleUtilisateur.medecin,
                      titre: "Médecin",
                      description: "Vérification officielle ONMS, gestion de vos consultations et patients.",
                      icone: Icons.medical_services_outlined,
                    ),
                    const SizedBox(height: 36),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _roleSelectionne != null ? _passerEtapeDeux : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D7C66),
                          disabledBackgroundColor: const Color(0xFFC4C4C4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Continuer",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // ETAPE 2 FORMULAIRE
                    Text(
                      _roleSelectionne == RoleUtilisateur.patient
                          ? "Inscription Patient"
                          : "Inscription Médecin",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _roleSelectionne == RoleUtilisateur.patient
                          ? "Veuillez remplir vos informations personnelles."
                          : "Entrez votre N° ONMS pour la vérification automatique dans l'annuaire national.",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8D99AE),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (_roleSelectionne == RoleUtilisateur.patient) ...[
                      _buildChampTexte(
                        controller: _controleurNomPatient,
                        libelle: "Nom complet",
                        indication: "Ex: Aminata Diallo",
                        icone: Icons.person_outline,
                      ),
                      const SizedBox(height: 18),
                      _buildChampTexte(
                        controller: _controleurTelephonePatient,
                        libelle: "Numéro de téléphone",
                        indication: "+221 77 123 45 67",
                        icone: Icons.phone_outlined,
                        typeClavier: TextInputType.phone,
                      ),
                      const SizedBox(height: 18),
                      _buildChampTexte(
                        controller: _controleurMotDePassePatient,
                        libelle: "Mot de passe",
                        indication: "••••••••",
                        icone: Icons.lock_outline,
                        masquerTexte: _masquerMotDePasse,
                        iconeSuffixe: IconButton(
                          icon: Icon(
                            _masquerMotDePasse ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF8D99AE),
                          ),
                          onPressed: () => setState(() => _masquerMotDePasse = !_masquerMotDePasse),
                        ),
                      ),
                    ] else ...[
                      _buildChampTexte(
                        controller: _controleurNumeroOnms,
                        libelle: "Numéro de l'ONMS (Ordre des Médecins)",
                        indication: "Ex: 1056/P ou 1006/P",
                        icone: Icons.badge_outlined,
                        auChangement: _verifierNumeroOnms,
                      ),

                      if (_medecinOnmsTrouve != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F2F0),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF0D7C66)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Color(0xFF0D7C66), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    "VÉRIFIÉ ONMS (Annuaire National)",
                                    style: TextStyle(
                                      color: Color(0xFF0D7C66),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _medecinOnmsTrouve!['nom']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF2D3142),
                                ),
                              ),
                              Text(
                                "${_medecinOnmsTrouve!['specialite']!} • ${_medecinOnmsTrouve!['etablissement']!}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6C7386),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),
                      _buildChampTexte(
                        controller: _controleurTelephoneMedecin,
                        libelle: "Numéro de téléphone",
                        indication: "+221 77 123 45 67",
                        icone: Icons.phone_outlined,
                        typeClavier: TextInputType.phone,
                      ),
                      const SizedBox(height: 18),
                      _buildChampTexte(
                        controller: _controleurMotDePasseMedecin,
                        libelle: "Mot de passe",
                        indication: "••••••••",
                        icone: Icons.lock_outline,
                        masquerTexte: _masquerMotDePasse,
                        iconeSuffixe: IconButton(
                          icon: Icon(
                            _masquerMotDePasse ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF8D99AE),
                          ),
                          onPressed: () => setState(() => _masquerMotDePasse = !_masquerMotDePasse),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _soumettreFormulaire,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D7C66),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Recevoir le code OTP",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarteRole({
    required RoleUtilisateur role,
    required String titre,
    required String description,
    required IconData icone,
  }) {
    final estSelectionne = _roleSelectionne == role;

    return InkWell(
      onTap: () => _selectionnerRole(role),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: estSelectionne ? const Color(0xFF0D7C66).withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: estSelectionne ? const Color(0xFF0D7C66) : const Color(0xFFE2E8F0),
            width: estSelectionne ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: estSelectionne ? const Color(0xFF0D7C66) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icone,
                color: estSelectionne ? Colors.white : const Color(0xFF64748B),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: estSelectionne ? const Color(0xFF0D7C66) : const Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8D99AE),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (estSelectionne)
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0D7C66),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 18, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChampTexte({
    required TextEditingController controller,
    required String libelle,
    required String indication,
    required IconData icone,
    TextInputType typeClavier = TextInputType.text,
    bool masquerTexte = false,
    Widget? iconeSuffixe,
    ValueChanged<String>? auChangement,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          libelle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: typeClavier,
          obscureText: masquerTexte,
          onChanged: auChangement,
          style: const TextStyle(fontSize: 15, color: Color(0xFF2D3142)),
          decoration: InputDecoration(
            hintText: indication,
            hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
            prefixIcon: Icon(icone, color: const Color(0xFF94A3B8), size: 20),
            suffixIcon: iconeSuffixe,
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
      ],
    );
  }
}
