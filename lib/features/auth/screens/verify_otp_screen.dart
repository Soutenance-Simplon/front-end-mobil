import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/routes/app_router.dart';
import 'package:go_router/go_router.dart';
// import 'package:lottie/lottie.dart';
import '../../../core/widgets/reponsive_layout.dart';
import '../../../core/widgets/logo_section.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 6; i++) {
      _otpControllers[i].addListener(() {
        final text = _otpControllers[i].text;
        if (text.length > 1) {
          _otpControllers[i].text = text.substring(0, 1);
        }
        if (text.isNotEmpty && i < 5) {
          _focusNodes[i + 1].requestFocus();
        }
        if (text.isEmpty && i > 0) {
          _focusNodes[i - 1].requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var ctrl in _otpControllers) ctrl.dispose();
    for (var node in _focusNodes) node.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
  if (_loading) return;

  setState(() => _loading = true);

  final otp = _otpControllers.map((e) => e.text).join();

  print("OTP SAISI = $otp");

  final success = await ref.read(authProvider.notifier).verifyEmailOtp(
        email: widget.email,
        code: otp,
      );

  print("SUCCESS VERIFY = $success");

  setState(() => _loading = false);

  if (!mounted) return;

  if (success) {
    print("REDIRECTION VERS INFO SCREEN");

    context.goNamed(
      infoRoute,
      extra: {'email': widget.email},
    );
  } else {
    setState(() => _error = "OTP incorrect ou expiré");
  }
}


  Widget _otpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 60, // largeur plus grande
          height: 70, // hauteur plus grande
          child: TextField(
            controller: _otpControllers[i],
            focusNode: _focusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32, // texte plus grand
              fontWeight: FontWeight.bold,
            ),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.6),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobile: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LogoSection(),
            const SizedBox(height: 20),
            Text(
              "Entrez le code envoyé à ${widget.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            _otpFields(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(150, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Vérifier OTP"),
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
        web: Row(
          children: [
            Expanded(flex: 6, child: const LogoSection()),
            Expanded(
              flex: 4,
              child: Center(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Entrez le code envoyé à ${widget.email}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _otpFields(),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(150, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("Vérifier OTP"),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
