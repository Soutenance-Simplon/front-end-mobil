import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../services/auth_api_service.dart';

enum UserRole { patient, doctor }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  bool _isLoading = false;
  int _currentStep = 1;
  UserRole? _selectedRole;

  // Controllers Patient
  final _patientNameController = TextEditingController();
  final _patientPhoneController = TextEditingController(text: '+221 ');
  final _patientPasswordController = TextEditingController();

  // Controllers Médecin
  final _onmsController = TextEditingController();
  final _doctorPhoneController = TextEditingController(text: '+221 ');
  final _doctorPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isVerifyingOnms = false;
  bool _onmsVerifFailed = false;
  Map<String, String>? _onmsMatch;

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientPhoneController.dispose();
    _patientPasswordController.dispose();
    _onmsController.dispose();
    _doctorPhoneController.dispose();
    _doctorPasswordController.dispose();
    super.dispose();
  }

  /// Vérification réelle du numéro ONMS via le backend
  /// Endpoint : GET /api/medecins/onms/lookup/{numeroOrdre}
  Future<void> _verifyOnmsNumber(String code) async {
    final query = code.trim();
    if (query.isEmpty) {
      setState(() {
        _onmsMatch = null;
        _onmsVerifFailed = false;
      });
      return;
    }

    // Lancer la vérification seulement si le champ a au moins 3 caractères
    if (query.length < 3) return;

    setState(() {
      _isVerifyingOnms = true;
      _onmsMatch = null;
      _onmsVerifFailed = false;
    });

    try {
      final response = await ApiClient().dio.get(
        '/api/medecins/onms/lookup/${Uri.encodeComponent(query)}',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;

        // Vérifier que le médecin est bien ACTIF
        final statut = data['statutProfessionnel']?.toString() ?? 'ACTIF';
        if (statut != 'ACTIF') {
          setState(() {
            _isVerifyingOnms = false;
            _onmsVerifFailed = true;
            _onmsMatch = null;
          });
          return;
        }

        setState(() {
          _isVerifyingOnms = false;
          _onmsVerifFailed = false;
          _onmsMatch = {
            'nom': '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'.trim(),
            'specialite': data['specialite']?.toString() ?? 'Non précisée',
            'etablissement': data['etablissement']?.toString() ?? 'Non précisé',
            'statut': statut,
          };
        });
      } else {
        setState(() {
          _isVerifyingOnms = false;
          _onmsVerifFailed = true;
          _onmsMatch = null;
        });
      }
    } catch (_) {
      // Numéro introuvable dans la base ONMS
      setState(() {
        _isVerifyingOnms = false;
        _onmsVerifFailed = true;
        _onmsMatch = null;
      });
    }
  }

  void _onRoleSelected(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _goToStep2() {
    if (_selectedRole == null) return;
    setState(() {
      _currentStep = 2;
    });
  }

  Future<void> _submitForm() async {
    if (_isLoading) return;

    // ── PATIENT ──────────────────────────────────────────────
    if (_selectedRole == UserRole.patient) {
      final nom = _patientNameController.text.trim();
      final phone = _patientPhoneController.text.trim();
      final password = _patientPasswordController.text.trim();

      if (nom.isEmpty || phone.isEmpty || password.isEmpty) {
        _showError('Veuillez remplir tous les champs.');
        return;
      }
      if (password.length < 6) {
        _showError('Le mot de passe doit contenir au moins 6 caractères.');
        return;
      }

      setState(() => _isLoading = true);
      try {
        final res = await AuthApiService().register(
          firstName: nom.split(' ').first,
          lastName: nom.split(' ').length > 1 ? nom.split(' ').sublist(1).join(' ') : nom,
          telephone: phone,
          email: '${phone.replaceAll(RegExp(r'[^0-9]'), '')}@diam.sn',
          password: password,
          roleId: 'PATIENT',
          genre: 'M',
        );

        if (!mounted) return;

        if (res.success == false &&
            res.message != null &&
            !res.message!.toLowerCase().contains('otp') &&
            !res.message!.toLowerCase().contains('verif') &&
            !res.message!.toLowerCase().contains('code')) {
          _showError(res.message ?? 'Erreur lors de l\'inscription.');
          return;
        }

        // Succès → aller à l'écran OTP
        context.push('/verify-phone-otp', extra: {
          'role': 'PATIENT',
          'phone': phone,
          'name': nom,
          'password': password,
        });
      } catch (e) {
        if (mounted) _showError('Erreur réseau. Vérifiez votre connexion.');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

    // ── MEDECIN (activation de compte) ───────────────────────
    else if (_selectedRole == UserRole.doctor) {
      if (_isVerifyingOnms) return;
      if (_onmsMatch == null) {
        _showError('Veuillez entrer un numéro ONMS valide et vérifié.');
        return;
      }

      final phone = _doctorPhoneController.text.trim();
      final password = _doctorPasswordController.text.trim();

      if (phone.isEmpty || password.isEmpty) {
        _showError('Veuillez remplir tous les champs.');
        return;
      }
      if (password.length < 6) {
        _showError('Le mot de passe doit contenir au moins 6 caractères.');
        return;
      }

      setState(() => _isLoading = true);
      try {
        final nom = _onmsMatch!['nom'] ?? '';
        final res = await AuthApiService().register(
          firstName: nom.split(' ').first,
          lastName: nom.split(' ').length > 1 ? nom.split(' ').sublist(1).join(' ') : nom,
          telephone: phone,
          email: '${phone.replaceAll(RegExp(r'[^0-9]'), '')}@diam.sn',
          password: password,
          roleId: 'MEDECIN',
          genre: 'M',
        );

        if (!mounted) return;

        if (res.success == false &&
            res.message != null &&
            !res.message!.toLowerCase().contains('otp') &&
            !res.message!.toLowerCase().contains('verif') &&
            !res.message!.toLowerCase().contains('code')) {
          _showError(res.message ?? 'Erreur lors de l\'activation.');
          return;
        }

        context.push('/verify-phone-otp', extra: {
          'role': 'MEDECIN',
          'phone': phone,
          'name': nom,
          'onms': _onmsController.text.trim(),
          'password': password,
        });
      } catch (e) {
        if (mounted) _showError('Erreur réseau. Vérifiez votre connexion.');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
                  // TOP BAR: BOUTON RETOUR
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          if (_currentStep == 2) {
                            setState(() => _currentStep = 1);
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

                  if (_currentStep == 1) ...[
                    // CHOIX DE ROLE
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

                    // CARTES DE SELECTION DE ROLE
                    _buildRoleCard(
                      role: UserRole.patient,
                      title: "Patient",
                      subtitle: "Accédez à vos rendez-vous, téléconsultations et dossier médical.",
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildRoleCard(
                      role: UserRole.doctor,
                      title: "Médecin",
                      subtitle: "Vérification officielle ONMS, gestion de vos consultations et patients.",
                      icon: Icons.medical_services_outlined,
                    ),
                    const SizedBox(height: 36),

                    // BOUTON CONTINUER
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _selectedRole != null ? _goToStep2 : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A884),
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
                    // ETAPE 2: FORMULAIRE DYNAMIQUE
                    Text(
                      _selectedRole == UserRole.patient
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
                      _selectedRole == UserRole.patient
                          ? "Veuillez remplir vos informations personnelles."
                          : "Entrez votre N° ONMS pour la vérification automatique dans l'annuaire national.",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8D99AE),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (_selectedRole == UserRole.patient) ...[
                      _buildTextField(
                        controller: _patientNameController,
                        label: "Nom complet",
                        hint: "Ex: Aminata Diallo",
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 18),
                      _buildTextField(
                        controller: _patientPhoneController,
                        label: "Numéro de téléphone",
                        hint: "+221 77 123 45 67",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 18),
                      _buildTextField(
                        controller: _patientPasswordController,
                        label: "Mot de passe",
                        hint: "••••••••",
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF8D99AE),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ] else ...[
                      // NUMERO ONMS AVEC VERIFICATION REELLE EN DIRECT (API Backend)
                      _buildTextField(
                        controller: _onmsController,
                        label: "Numéro de l'ONMS (Ordre des Médecins)",
                        hint: "Ex: 1056/P ou 539",
                        icon: Icons.badge_outlined,
                        onChanged: (val) => _verifyOnmsNumber(val),
                        suffixIcon: _isVerifyingOnms
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF00A884),
                                  ),
                                ),
                              )
                            : null,
                      ),

                      // CARTE SUCCÈS : médecin trouvé et actif
                      if (_onmsMatch != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7F3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF00A884)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.verified, color: Color(0xFF00A884), size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    "VÉRIFIÉ — Annuaire ONMS Officiel",
                                    style: TextStyle(
                                      color: Color(0xFF00A884),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _onmsMatch!['nom']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF2D3142),
                                ),
                              ),
                              Text(
                                "${_onmsMatch!['specialite']!} • ${_onmsMatch!['etablissement']!}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6C7386),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // CARTE ERREUR : numéro introuvable ou médecin non actif
                      if (_onmsVerifFailed) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFEF4444)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.cancel, color: Color(0xFFEF4444), size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Numéro ONMS introuvable ou médecin non autorisé à exercer. Vérifiez votre numéro d'ordre.",
                                  style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),
                      _buildTextField(
                        controller: _doctorPhoneController,
                        label: "Numéro de téléphone",
                        hint: "+221 77 123 45 67",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 18),
                      _buildTextField(
                        controller: _doctorPasswordController,
                        label: "Mot de passe",
                        hint: "••••••••",
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0xFF8D99AE),
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // BOUTON VALIDER
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A884),
                          disabledBackgroundColor: const Color(0xFFC4C4C4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
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

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () => _onRoleSelected(role),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A884).withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A884) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00A884) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF00A884) : const Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8D99AE),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF00A884),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 18, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, color: Color(0xFF2D3142)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00A884), width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}
