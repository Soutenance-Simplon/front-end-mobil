import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/reponsive_layout.dart';
import '../../../core/widgets/logo_section.dart';

class SendOtpScreen extends ConsumerStatefulWidget {
  const SendOtpScreen({super.key});

  @override
  ConsumerState<SendOtpScreen> createState() => _SendOtpScreenState();
}

class _SendOtpScreenState extends ConsumerState<SendOtpScreen> {
  final _emailController = TextEditingController();
  String? _error;

  Future<void> _sendOtp() async {
    final success = await ref
        .read(authProvider.notifier)
        .sendEmailOtp(email: _emailController.text.trim());

    if (success && mounted) {
      // Pour debug : afficher l'OTP dans le terminal
      print("OTP envoyé à ${_emailController.text.trim()}");
      context.goNamed(
        'verify-otp',
        extra: {'email': _emailController.text.trim()},
      );
    } else {
      setState(() => _error = "Erreur envoi OTP");
    }
  }

  Widget _form(bool isMobile) {
    final authState = ref.watch(authProvider); // 👈 ICI en haut

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: isMobile
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Vérification Email",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: authState.isLoading ? null : _sendOtp,
              child: authState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Envoyer le code"),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        // 📱 MOBILE
        mobile: Column(
          children: [
            Expanded(flex: 6, child: const LogoSection()),
            Expanded(flex: 4, child: _form(true)),
          ],
        ),

        // 💻 WEB
        web: Row(
          children: [
            Expanded(flex: 6, child: const LogoSection()),
            Expanded(
              flex: 4,
              child: Center(child: SizedBox(width: 400, child: _form(false))),
            ),
          ],
        ),
      ),
    );
  }
}
