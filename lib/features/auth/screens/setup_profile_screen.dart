import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SetupProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  const SetupProfileScreen({super.key, required this.userInfo});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  String? _selectedGender;
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  Uint8List? _avatarBytes;

  final List<String> _genders = ['Masculin', 'Féminin', 'Autre'];

  @override
  void dispose() {
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _avatarBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1930),
      lastDate: now,
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

    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _onComplete() {
    print("Profil complété pour ${widget.userInfo}");
    context.goNamed('dashboard');
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BOUTON RETOUR
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Color(0xFF5A607F),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // TITRE EN FRANCAIS
                  const Text(
                    "Configurez votre profil",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A607F),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // SOUS-TITRE EN FRANCAIS
                  const Text(
                    "Complétez votre profil pour permettre une meilleure prise en charge médicale.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E95A5),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // AVATAR AVEC BADGE APPAREIL PHOTO
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAEAEA),
                            borderRadius: BorderRadius.circular(32),
                            image: _avatarBytes != null
                                ? DecorationImage(
                                    image: MemoryImage(_avatarBytes!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _avatarBytes == null
                              ? const Icon(
                                  Icons.person,
                                  size: 64,
                                  color: Color(0xFF9EA5B4),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickAvatar,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D7C66),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // CHAMP GENRE
                  _buildInputLabel(Icons.people_outline, "Genre"),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    hint: const Text(
                      "Sélectionnez votre genre",
                      style: TextStyle(color: Color(0xFFB4B9C5), fontSize: 14),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9EA5B4)),
                    decoration: _inputDecoration(),
                    items: _genders.map((g) {
                      return DropdownMenuItem(
                        value: g,
                        child: Text(g, style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142))),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedGender = val),
                  ),

                  const SizedBox(height: 20),

                  // CHAMP DATE DE NAISSANCE
                  _buildInputLabel(Icons.calendar_today_outlined, "Date de naissance"),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _dobController,
                    readOnly: true,
                    onTap: _pickDate,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142)),
                    decoration: _inputDecoration(hint: "Saisissez votre date de naissance"),
                  ),

                  const SizedBox(height: 20),

                  // CHAMP ADRESSE
                  _buildInputLabel(Icons.location_on_outlined, "Adresse"),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _addressController,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142)),
                    decoration: _inputDecoration(hint: "Entrez votre adresse"),
                  ),

                  const SizedBox(height: 36),

                  // BOUTON TERMINER EN FRANCAIS
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D7C66),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Terminer",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildInputLabel(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8E95A5)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6C7386),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB4B9C5), fontSize: 14),
      filled: false,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE5E9F2)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF0D7C66), width: 2),
      ),
    );
  }
}
