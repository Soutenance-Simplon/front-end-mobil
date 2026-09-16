import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../auth/providers/auth_provider.dart';

class EmailOTPVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailOTPVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<EmailOTPVerificationScreen> createState() =>
      _EmailOTPVerificationScreenState();
}

class _EmailOTPVerificationScreenState
    extends ConsumerState<EmailOTPVerificationScreen> {

  final _codeController = TextEditingController();
  String? _errorMessage;
  bool _codeResent = false;

  // ====== SECURITE ======
  int _attempts = 0;
  DateTime? _firstAttemptTime;
  bool _blocked = false;
  DateTime? _blockedUntil;

  // =====================================================
  // 🔹 VERIFY OTP
  // =====================================================
  Future<void> _verifyCode() async {
    if (_blocked) {
      final remaining = _blockedUntil != null
          ? _blockedUntil!.difference(DateTime.now()).inMinutes
          : 0;

      setState(() {
        _errorMessage =
            "Trop d'essais. Réessayez après $remaining min";
      });
      return;
    }

    final code = _codeController.text.trim();

    if (code.length != 6) {
      setState(() => _errorMessage = 'Le code doit contenir 6 chiffres');
      return;
    }

    // ====== GESTION DES TENTATIVES ======
    if (_firstAttemptTime == null) {
      _firstAttemptTime = DateTime.now();
    }

    // Si 15 min passées, reset des essais
    if (DateTime.now().difference(_firstAttemptTime!).inMinutes >= 15) {
      _attempts = 0;
      _firstAttemptTime = DateTime.now();
    }

    // Si déjà 3 essais, blocage 24h
    if (_attempts >= 3) {
      _blocked = true;
      _blockedUntil = DateTime.now().add(const Duration(hours: 24));
      setState(() {
        _errorMessage =
            "Blocage 24h pour sécurité. Réessayez demain.";
      });
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .verifyEmailOtp(
          email: widget.email,
          code: code,
        );

    if (success) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email vérifié avec succès')),
      );

      context.goNamed('upload-id');
    } else {
      _attempts++;
      setState(() => _errorMessage =
          'Code incorrect ou expiré (${_attempts}/3 essais)');
    }
  }

  // =====================================================
  // 🔹 RESEND OTP
  // =====================================================
  Future<void> _resendCode() async {
    if (_blocked) {
      setState(() {
        _errorMessage =
            "Blocage 24h. Impossible de renvoyer un code.";
      });
      return;
    }

    final success = await ref.read(authProvider.notifier).sendEmailOtp(
          email: widget.email,
        );

    if (success) {
      setState(() {
        _codeResent = true;
        _errorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nouveau code envoyé')),
      );
    } else {
      setState(() => _errorMessage = 'Erreur lors du renvoi du code');
    }
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vérification de l’email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Un code à 6 chiffres a été envoyé à :\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Code reçu par email',
                  hintText: '------',
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: authState.isLoading ? null : _verifyCode,
                child: authState.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Vérifier le code'),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: authState.isLoading ? null : _resendCode,
                child: Text(
                  _codeResent ? 'Renvoyer un nouveau code' : 'Renvoyer le code',
                ),
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
