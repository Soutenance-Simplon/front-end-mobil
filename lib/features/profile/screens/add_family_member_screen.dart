import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/membre_famille_model.dart';
import '../../patient/services/patient_api_service.dart';
import '../../../core/network/api_client.dart';

class AddFamilyMemberScreen extends StatefulWidget {
  const AddFamilyMemberScreen({super.key});

  @override
  State<AddFamilyMemberScreen> createState() => _AddFamilyMemberScreenState();
}

class _AddFamilyMemberScreenState extends State<AddFamilyMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final PatientApiService _apiService = PatientApiService();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  String _genre = 'Homme';
  String _lienParente = 'Enfant';
  bool _isSaving = false;

  final List<String> _liens = ['Enfant', 'Conjoint(e)', 'Parent', 'Frère/Sœur', 'Autre'];
  final List<String> _genres = ['Homme', 'Femme'];

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    final parentId = await ApiClient().getUserId() ?? '';
    if (parentId.isEmpty) {
      setState(() => _isSaving = false);
      return;
    }

    final newMember = MembreFamille(
      id: '', // Sera généré par le backend
      parentUserId: parentId,
      enfantUserId: '', // Sera généré par le backend
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      genre: _genre,
      lienParente: _lienParente,
    );

    final result = await _apiService.ajouterMembreFamille(parentId, newMember);
    
    setState(() => _isSaving = false);
    
    if (result != null) {
      if (mounted) context.pop(true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'ajout. Veuillez réessayer.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Ajouter un proche", style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Informations du proche",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Ce profil partagera votre compte et n'aura pas besoin de se connecter.",
                  style: TextStyle(fontSize: 14, color: Color(0xFF8D99AE)),
                ),
                const SizedBox(height: 32),

                _buildTextField(
                  controller: _prenomController,
                  label: "Prénom",
                  icon: Icons.person_outline,
                  validator: (val) => val == null || val.isEmpty ? "Veuillez entrer le prénom" : null,
                ),
                const SizedBox(height: 20),
                
                _buildTextField(
                  controller: _nomController,
                  label: "Nom",
                  icon: Icons.badge_outlined,
                  validator: (val) => val == null || val.isEmpty ? "Veuillez entrer le nom" : null,
                ),
                const SizedBox(height: 20),

                _buildDropdown(
                  label: "Lien de parenté",
                  value: _lienParente,
                  items: _liens,
                  onChanged: (val) => setState(() => _lienParente = val!),
                  icon: Icons.family_restroom,
                ),
                const SizedBox(height: 20),

                _buildDropdown(
                  label: "Genre",
                  value: _genre,
                  items: _genres,
                  onChanged: (val) => setState(() => _genre = val!),
                  icon: Icons.transgender,
                ),
                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveMember,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            "Ajouter",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A5568))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A884))),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A5568))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
              items: items.map((item) {
                return DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(color: Color(0xFF2D3142))));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
