import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class IdentityVerificationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> userInfo;

  const IdentityVerificationScreen({super.key, required this.userInfo});

  @override
  ConsumerState<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends ConsumerState<IdentityVerificationScreen> {
  final TextEditingController _numeroController = TextEditingController();
  Uint8List? _idBytes;
  bool _isLoading = false;
  String? _statusMessage;
  String? _verificationStatus;
  int? _score;
  List<dynamic>? _errors;

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  // =========================
  // PICK IMAGE
  // =========================
  Future<void> _pickId() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null) return;

    final file = result.files.single;

    if (file.bytes == null) {
      _showError("Impossible de lire l'image");
      return;
    }

    setState(() {
      _idBytes = file.bytes;
      _statusMessage = null;
      _verificationStatus = null;
      _score = null;
      _errors = null;
    });
  }

  // =========================
  // SUBMIT
  // =========================
  Future<void> _submit() async {
    if (_idBytes == null) {
      _showError("Veuillez uploader votre pièce");
      return;
    }

    if (_numeroController.text.trim().isEmpty) {
      _showError("Numéro de pièce requis");
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final response = await ref
          .read(authProvider.notifier)
          .sendIdentity(
            pieceNumber: _numeroController.text.trim(),
            idBytes: _idBytes!,
            firstName: widget.userInfo["firstName"] ?? "",
            lastName: widget.userInfo["lastName"] ?? "",
            dateNaissance: widget.userInfo["dateNaissance"] ?? "",
          );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response == null) {
        _showError("Erreur serveur. Réessayez.");
        return;
      }

      setState(() {
        _verificationStatus = response["status"];
        _score = int.tryParse(response["score"].toString()) ?? 0;
        _errors = response["errors"] is List ? response["errors"] : [];
      });

      _handleStatus();
    } catch (e) {
      print("ERREUR API : $e");
      setState(() => _isLoading = false);
      _showError("Erreur réseau");
    }
  }

  // =========================
  // HANDLE STATUS
  // =========================
  void _handleStatus() {
    if (_score == 40) {
      _showSuccessAndRegister();
    } else if (_score! >= 30) {
      _showAiDialog();
    } else {
      _showError("Échec vérification (score $_score)");
    }
  }

  // =========================
  // SUCCESS POPUP & REGISTER
  // =========================
  void _showSuccessAndRegister() async {
    setState(() {
      _statusMessage = "✅ Votre inscription est validée (score $_score)";
    });

    // Inscription utilisateur
    final userInfo = widget.userInfo;
    final photo = userInfo['photo'];

    if (photo == null) {
      _showError("Photo manquante !");
      return;
    }
    final success = await ref
        .read(authProvider.notifier)
        .register(
          firstName: userInfo['firstName'] ?? '',
          lastName: userInfo['lastName'] ?? '',
          email: userInfo['email'] ?? '',
          telephone: userInfo['telephone'] ?? '',
          password: userInfo['password'] ?? '',
          password2: userInfo['password'] ?? '',
          roleId: userInfo['roleId']?.toString() ?? '1',
          genre: userInfo['genre'] ?? 'F',
          dateNaissance: userInfo['dateNaissance'] != null
              ? DateTime.tryParse(userInfo['dateNaissance'])
              : null,
          photo: photo,
        );

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Inscription réussie"),
          content: const Text(
            "Votre inscription a été validée avec succès. Vous êtes maintenant redirigé vers le dashboard.",
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.goNamed("dashboard");
              },
              child: const Text("Aller au Dashboard"),
            ),
          ],
        ),
      );
    } else {
      _showError("Impossible d'enregistrer l'utilisateur. Réessayez.");
    }
  }

  // =========================
  // AI POPUP
  // =========================
  void _showAiDialog() {
    final erreurs = _errors?.join(", ") ?? "inconnue";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Analyse automatique"),
        content: Text(
          "Notre système a détecté une incohérence au niveau de :\n\n$erreurs\n\nVeuillez vérifier les informations.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.goNamed("info", extra: widget.userInfo);
            },
            child: const Text("Revérifier les informations"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Quitter"),
          ),
        ],
      ),
    );
  }

  // =========================
  // HELPERS
  // =========================
  void _showError(String msg) {
    setState(() {
      _statusMessage = msg;
      _verificationStatus = "rejected";
    });
  }

  Color _getColor() {
    switch (_verificationStatus) {
      case "approved":
        return AppColors.primary;
      case "manual":
        return Colors.orange;
      case "rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (_verificationStatus) {
      case "approved":
        return Icons.check_circle;
      case "manual":
        return Icons.warning;
      case "rejected":
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: width > 600 ? 500 : double.infinity,
                ),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          "Vérification d'identité",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _numeroController,
                          decoration: const InputDecoration(
                            labelText: "Numéro de la pièce",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _pickId,
                          child: Container(
                            width: double.infinity,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _idBytes != null
                                    ? AppColors.primary
                                    : Colors.grey,
                                width: 2,
                              ),
                              image: _idBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_idBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _idBytes == null
                                ? const Center(
                                    child: Text("Uploader votre pièce"),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text("Vérifier"),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_statusMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getColor().withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(_getIcon(), color: _getColor()),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _statusMessage!,
                                    style: TextStyle(
                                      color: _getColor(),
                                      fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }
}
