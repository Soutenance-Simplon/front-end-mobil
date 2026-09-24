import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../patient/providers/patient_provider.dart';

class EcranConfigurationProfil extends ConsumerStatefulWidget {
  final Map<String, dynamic> informationsUtilisateur;

  const EcranConfigurationProfil({super.key, this.informationsUtilisateur = const {}});

  @override
  ConsumerState<EcranConfigurationProfil> createState() => _EcranConfigurationProfilState();
}

class _EcranConfigurationProfilState extends ConsumerState<EcranConfigurationProfil> {
  final _formKey = GlobalKey<FormState>();

  String? _genreSelectionne = 'Masculin';
  final _controleurDateNaissance = TextEditingController();
  final _controleurAdresse = TextEditingController();
  
  // Données médicales vitales
  String _groupeSanguin = 'O+';
  final _controleurPoids = TextEditingController(text: '70');
  final _controleurTaille = TextEditingController(text: '175');
  final _controleurContactUrgenceNom = TextEditingController();
  final _controleurContactUrgenceTel = TextEditingController(text: '+221 ');
  String _contactUrgenceLien = 'Parent (Père/Mère)';
  final _controleurAllergies = TextEditingController();

  Uint8List? _octetsAvatar;
  bool _isSaving = false;

  final List<String> _listeGenres = ['Masculin', 'Féminin'];
  final List<String> _listeGroupesSanguins = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];
  final List<String> _listeLiensParentes = ['Parent (Père/Mère)', 'Conjoint(e)', 'Frère/Sœur', 'Enfant', 'Proche / Ami'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        if (user.dateNaissance != null && user.dateNaissance!.isNotEmpty) {
          _controleurDateNaissance.text = user.dateNaissance!;
        }
        if (user.genre.isNotEmpty) {
          _genreSelectionne = user.genre.startsWith('F') ? 'Féminin' : 'Masculin';
        }
      }
    });
  }

  @override
  void dispose() {
    _controleurDateNaissance.dispose();
    _controleurAdresse.dispose();
    _controleurPoids.dispose();
    _controleurTaille.dispose();
    _controleurContactUrgenceNom.dispose();
    _controleurContactUrgenceTel.dispose();
    _controleurAllergies.dispose();
    super.dispose();
  }

  Future<void> _choisirAvatar() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text(
              "Photo de Profil",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE7F2F0), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0D7C66)),
              ),
              title: const Text("Prendre une photo avec l'appareil", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE7F2F0), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0D7C66)),
              ),
              title: const Text("Choisir depuis la galerie", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_octetsAvatar != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                ),
                title: const Text("Réinitialiser à l'image par défaut", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _octetsAvatar = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _octetsAvatar = bytes;
        });
      }
    } catch (_) {
      final resultat = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (resultat != null && resultat.files.single.bytes != null) {
        setState(() {
          _octetsAvatar = resultat.files.single.bytes;
        });
      }
    }
  }

  Future<void> _choisirDateNaissance() async {
    final aujourdhui = DateTime.now();
    final dateChoisie = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1930),
      lastDate: aujourdhui,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D7C66),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2D3142),
            ),
          ),
          child: child!,
        );
      },
    );

    if (dateChoisie != null) {
      setState(() {
        _controleurDateNaissance.text =
            "${dateChoisie.day.toString().padLeft(2, '0')}/${dateChoisie.month.toString().padLeft(2, '0')}/${dateChoisie.year}";
      });
    }
  }

  Future<void> _terminerProfil() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final user = ref.read(authProvider).user;
    final userId = user?.id ?? 'user-temp';

    // Enregistrer le contact d'urgence
    final nomUrgence = _controleurContactUrgenceNom.text.trim();
    final telUrgence = _controleurContactUrgenceTel.text.trim();
    final lienUrgence = _contactUrgenceLien;

    if (nomUrgence.isNotEmpty && telUrgence.isNotEmpty) {
      await ref.read(patientProvider.notifier).updateEmergencyContact(
        patientId: userId,
        nom: nomUrgence,
        telephone: telUrgence,
        lien: lienUrgence,
      );
    }

    // Enregistrer le marquage de profil complété
    await ApiClient().setProfileCompleted(userId, true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("Profil & Données vitales enregistrés avec succès !"),
            ],
          ),
          backgroundColor: Color(0xFF0D7C66),
          duration: Duration(seconds: 2),
        ),
      );

      // Redirection fluide vers le Dashboard
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final displayName = user?.fullName.trim().isNotEmpty == true ? user!.fullName : "Patient";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 540),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ENTETE & BADGE INITIAL
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F2F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_user_rounded, color: Color(0xFF0D7C66), size: 16),
                              SizedBox(width: 6),
                              Text(
                                "Première Connexion",
                                style: TextStyle(
                                  color: Color(0xFF0D7C66),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Étape 1 sur 1",
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Bienvenue, $displayName 👋",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Pour assurer votre sécurité médicale et générer votre QR Pass d'urgence, veuillez compléter votre profil santé.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // AVATAR PHOTO
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _choisirAvatar,
                                child: Container(
                                  width: 104,
                                  height: 104,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF0D7C66),
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0D7C66).withValues(alpha: 0.18),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _octetsAvatar != null
                                        ? Image.memory(
                                            _octetsAvatar!,
                                            fit: BoxFit.cover,
                                            width: 104,
                                            height: 104,
                                          )
                                        : Image.asset(
                                            'assets/images/default_avatar.png',
                                            fit: BoxFit.cover,
                                            width: 104,
                                            height: 104,
                                          ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _choisirAvatar,
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D7C66),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: _choisirAvatar,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: _octetsAvatar != null
                                    ? const Color(0xFFE7F2F0)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _octetsAvatar != null
                                      ? const Color(0xFF0D7C66).withValues(alpha: 0.4)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _octetsAvatar != null
                                        ? Icons.check_circle_rounded
                                        : Icons.add_a_photo_outlined,
                                    size: 14,
                                    color: _octetsAvatar != null
                                        ? const Color(0xFF0D7C66)
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _octetsAvatar != null
                                        ? "Photo personnalisée définie ✓"
                                        : "Chaque utilisateur doit ajouter sa photo (sinon avatar par défaut)",
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: _octetsAvatar != null
                                          ? const Color(0xFF0D7C66)
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // SECTION 1 : ETAT CIVIL
                    _buildSectionHeader(Icons.person_outline_rounded, "Informations Personnelles"),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLibelle("Genre"),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _genreSelectionne,
                                decoration: _decorationChamp(),
                                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
                                items: _listeGenres.map((genre) {
                                  return DropdownMenuItem(
                                    value: genre,
                                    child: Text(genre, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _genreSelectionne = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLibelle("Date de naissance"),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _controleurDateNaissance,
                                readOnly: true,
                                onTap: _choisirDateNaissance,
                                validator: (val) => (val == null || val.isEmpty) ? "Requis" : null,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                                decoration: _decorationChamp(indication: "JJ/MM/AAAA", suffixe: Icons.calendar_today_rounded),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildLibelle("Adresse de résidence (Ville / Quartier)"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _controleurAdresse,
                      validator: (val) => (val == null || val.trim().isEmpty) ? "Veuillez indiquer votre adresse" : null,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                      decoration: _decorationChamp(indication: "Ex: Mermoz, Dakar"),
                    ),

                    const SizedBox(height: 28),

                    // SECTION 2 : FICHE MEDICALE VITALE
                    _buildSectionHeader(Icons.favorite_outline_rounded, "Données Vitales & Urgence"),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLibelle("Groupe Sanguin"),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _groupeSanguin,
                                decoration: _decorationChamp(),
                                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
                                items: _listeGroupesSanguins.map((g) {
                                  return DropdownMenuItem(
                                    value: g,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(g, style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(g, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) => setState(() => _groupeSanguin = val ?? 'O+'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLibelle("Poids (kg)"),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _controleurPoids,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                                decoration: _decorationChamp(indication: "70 kg"),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLibelle("Taille (cm)"),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _controleurTaille,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                                decoration: _decorationChamp(indication: "175 cm"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // CONTACT URGENCE
                    _buildLibelle("Contact d'Urgence (SAMU / Famille)"),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _controleurContactUrgenceNom,
                            validator: (val) => (val == null || val.trim().isEmpty) ? "Nom du contact requis" : null,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                            decoration: _decorationChamp(indication: "Nom et Prénom du proche"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _contactUrgenceLien,
                            decoration: _decorationChamp(),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
                            items: _listeLiensParentes.map((lien) {
                              return DropdownMenuItem(
                                value: lien,
                                child: Text(lien.split(' ')[0], style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _contactUrgenceLien = val ?? 'Parent (Père/Mère)'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _controleurContactUrgenceTel,
                      keyboardType: TextInputType.phone,
                      validator: (val) => (val == null || val.trim().length < 8) ? "Numéro de téléphone requis" : null,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                      decoration: _decorationChamp(indication: "+221 77 000 00 00", suffixe: Icons.phone_in_talk_rounded),
                    ),

                    const SizedBox(height: 16),

                    _buildLibelle("Allergies connues ou antécédents médicaux"),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _controleurAllergies,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                      decoration: _decorationChamp(indication: "Ex: Pénicilline, Asthme (ou 'Aucun')"),
                    ),

                    const SizedBox(height: 32),

                    // BOUTON FINALISER
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _terminerProfil,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D7C66),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                        label: Text(
                          _isSaving ? "Enregistrement en cours..." : "Enregistrer et Accéder à mon Espace",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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

  Widget _buildSectionHeader(IconData icone, String titre) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFE7F2F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icone, size: 16, color: const Color(0xFF0D7C66)),
        ),
        const SizedBox(width: 8),
        Text(
          titre,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildLibelle(String titre) {
    return Text(
      titre,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
      ),
    );
  }

  InputDecoration _decorationChamp({String? indication, IconData? suffixe}) {
    return InputDecoration(
      hintText: indication,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIcon: suffixe != null ? Icon(suffixe, size: 18, color: const Color(0xFF94A3B8)) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0D7C66), width: 1.8),
      ),
    );
  }
}
