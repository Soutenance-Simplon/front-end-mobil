import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';


class UploadIdScreen extends ConsumerStatefulWidget {
  const UploadIdScreen({super.key});

  @override
  ConsumerState<UploadIdScreen> createState() => _UploadIdScreenState();
}

class _UploadIdScreenState extends ConsumerState<UploadIdScreen> {
  XFile? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _verificationResult;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  // Prendre une photo avec l'appareil photo
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImage = XFile(photo.path);
        _errorMessage = null;
      });
    }
  }

  // Choisir une photo depuis la galerie
  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = XFile(image.path);
        _errorMessage = null;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      setState(() => _errorMessage = 'Veuillez sélectionner une photo');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _verificationResult = null;
    });

    final authService = ref.read(authServiceProvider);

    final result = await authService.uploadIdentity(_selectedImage!);

    setState(() => _isLoading = false);

    if (result != null) {
      setState(() => _verificationResult = result);

      if (result['status'] == 'approved') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identité vérifiée avec succès !'),
            backgroundColor: AppColors.primary,
          ),
        );

        // Navigation vers l'écran principal/profil
        context.goNamed('profile');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['status'] == 'manual'
                  ? 'Vérification en attente (manuelle)'
                  : 'Vérification rejetée',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      setState(() => _errorMessage = 'Erreur lors de l\'upload ou de la vérification');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification de la pièce d\'identité')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Téléchargez une photo nette de votre pièce d\'identité (CNI, passeport...)',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (_selectedImage != null)
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF00A884), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_selectedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, size: 80, color: Colors.grey),
                  ),
                ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galerie'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Appareil photo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading || _selectedImage == null ? null : _uploadImage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Vérifier l\'identité', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 24),

              if (_verificationResult != null) ...[
                Card(
                  color: _verificationResult!['status'] == 'approved'
                      ? AppColors.primary.withOpacity(0.1)
                      : _verificationResult!['status'] == 'manual'
                          ? Colors.orange[50]
                          : Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Résultat : ${_verificationResult!['status'] == 'approved' ? 'Approuvé' : _verificationResult!['status'] == 'manual' ? 'En attente' : 'Rejeté'}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _verificationResult!['status'] == 'approved'
                                ? AppColors.primary
                                : _verificationResult!['status'] == 'manual'
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Score de correspondance : ${_verificationResult!['score']}% ${_verificationResult!['status'] == 'approved' ? '✅' : _verificationResult!['status'] == 'manual' ? '⏳' : '❌'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
