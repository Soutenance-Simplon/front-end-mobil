import 'dart:typed_data';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/providers/auth_provider.dart';

class InfoScreen extends ConsumerStatefulWidget {
  final String email;

  const InfoScreen({super.key, required this.email});

  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _emailController;
  final TextEditingController _phoneController = TextEditingController(text: '+221');
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController(); // Date de naissance

  String? _selectedGenre;
  String? _selectedRoleId;
  XFile? _photo;
  Uint8List? _photoBytes;

  final List<String> _genres = ['Masculin', 'Féminin'];

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);

    // Charger les rôles depuis le provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).loadRoles();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  bool isValidPhone(String phone) {
    final regex = RegExp(r'^\+221(70|75|76|77|78)\d{7}$');
    return regex.hasMatch(phone);
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      setState(() {
        _photoBytes = file.bytes;
        _photo = XFile.fromData(file.bytes!, name: file.name);
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      _dobController.text = "${date.toLocal()}".split(' ')[0];
    }
  }

  void _nextStep() {
    if (!_formKey.currentState!.validate()) return;

    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter une photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!isValidPhone(_phoneController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Téléphone invalide. Format : +2217XXXXXXXX'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un rôle'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_dobController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner votre date de naissance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Passe à l'étape 3 pour vérification identité
    context.goNamed(
      'verify-identity',
      extra: {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'telephone': _phoneController.text.trim(),
        'genre': _selectedGenre,
        'photoBytes': _photoBytes,
        'roleId': _selectedRoleId,
        'dateNaissance': _dobController.text,
        'password': _passwordController.text,
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/diamyaraam.png",
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.4),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 16,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        const Center(
                          child: Text(
                            "Créer un compte",
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          enabled: false,
                          decoration: _inputDecoration("Email", Icons.email_outlined),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            CountryCodePicker(
                              initialSelection: "SN",
                              favorite: const ["+221", "SN"],
                              enabled: false,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: _inputDecoration("Téléphone", Icons.phone_outlined),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _firstNameController,
                          decoration: _inputDecoration("Prénom", Icons.person_outline),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: _inputDecoration("Nom", Icons.person_outline),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration("Genre", Icons.wc_outlined),
                          items: _genres
                              .map((g) => DropdownMenuItem(
                                    value: g == 'Masculin' ? 'M' : 'F',
                                    child: Text(g),
                                  ))
                              .toList(),
                          onChanged: (v) => _selectedGenre = v,
                        ),
                        const SizedBox(height: 14),
                        // Sélection du rôle
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration("Rôle", Icons.work_outline),
                          items: authState.roles
                              .map((r) => DropdownMenuItem(
                                    value: r.id,
                                    child: Text(r.nom),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedRoleId = v),
                        ),
                        const SizedBox(height: 14),
                        // Date de naissance
                        TextFormField(
                          controller: _dobController,
                          readOnly: true,
                          onTap: _pickDate,
                          decoration: _inputDecoration("Date de naissance", Icons.calendar_today),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _inputDecoration("Mot de passe", Icons.lock_outline),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: _inputDecoration("Confirmer le mot de passe", Icons.lock_outline),
                        ),
                        const SizedBox(height: 26),
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: Theme.of(context).primaryColor,
                                backgroundImage:
                                    _photoBytes != null ? MemoryImage(_photoBytes!) : null,
                                child: _photoBytes == null
                                    ? const Icon(Icons.camera_alt, color: Colors.white, size: 34)
                                    : null,
                              ),
                              TextButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.add_a_photo_outlined,
                                    color: Color(0xFF0D7C66)),
                                label: const Text(
                                  "Ajouter une photo",
                                  style: TextStyle(
                                      color: Color(0xFF0D7C66), fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _nextStep,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text("Suivant", style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
