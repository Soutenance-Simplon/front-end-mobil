import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VerifyPhoneOtpScreen extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  const VerifyPhoneOtpScreen({super.key, required this.userInfo});

  @override
  State<VerifyPhoneOtpScreen> createState() => _VerifyPhoneOtpScreenState();
}

class _VerifyPhoneOtpScreenState extends State<VerifyPhoneOtpScreen> {
  final List<String> _digits = ['', '', '', '', '', ''];
  int _currentIndex = 0;

  int _startSeconds = 29;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _startSeconds = 29);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startSeconds > 0) {
        setState(() => _startSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onKeyPress(String value) {
    if (value == 'backspace') {
      if (_currentIndex > 0 && _digits[_currentIndex].isEmpty) {
        setState(() {
          _currentIndex--;
          _digits[_currentIndex] = '';
        });
      } else if (_digits[_currentIndex].isNotEmpty) {
        setState(() {
          _digits[_currentIndex] = '';
        });
      }
    } else {
      if (_currentIndex < 6) {
        setState(() {
          _digits[_currentIndex] = value;
          if (_currentIndex < 5) {
            _currentIndex++;
          }
        });

        if (_digits.every((d) => d.isNotEmpty)) {
          _verifyOtp();
        }
      }
    }
  }

  void _verifyOtp() {
    final otpCode = _digits.join();
    print("Code OTP soumis : $otpCode pour ${widget.userInfo['phone']}");
    context.push('/setup-profile', extra: widget.userInfo);
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.userInfo['phone'] ?? '+221 77 000 00 00';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // BOUTON RETOUR
                    InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: Color(0xFF5A607F),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // TITRE
                    const Text(
                      "Code OTP",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A607F),
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // SOUS-TITRE EN FRANCAIS
                    Text(
                      "Saisissez le code OTP à 6 chiffres envoyé à votre numéro\n$phone",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8E95A5),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // 6 CASES OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        final isFocused = _currentIndex == index;
                        final hasValue = _digits[index].isNotEmpty;

                        return Container(
                          width: 48,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isFocused
                                  ? const Color(0xFF0D7C66)
                                  : const Color(0xFFE5E9F2),
                              width: isFocused ? 2 : 1.5,
                            ),
                            boxShadow: [
                              if (isFocused)
                                BoxShadow(
                                  color: const Color(0xFF0D7C66).withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                            ],
                          ),
                          child: Center(
                            child: isFocused && !hasValue
                                ? Container(
                                    width: 2,
                                    height: 20,
                                    color: const Color(0xFF0D7C66),
                                  )
                                : Text(
                                    _digits[index],
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5A607F),
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 28),

                    // COMPTE A REBOURS ET RENVOYER LE CODE EN FRANCAIS
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Code envoyé dans 0:${_startSeconds.toString().padLeft(2, '0')} ",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9EA5B4),
                            ),
                          ),
                          GestureDetector(
                            onTap: _startSeconds == 0 ? _startTimer : null,
                            child: Text(
                              "Renvoyer le code",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _startSeconds == 0
                                    ? const Color(0xFF0D7C66)
                                    : const Color(0xFF0D7C66).withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // CLAVIER NUMERIQUE SUR MESURE EN BAS
                    Container(
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildKeypadRow(['1', '2', '3']),
                          const SizedBox(height: 16),
                          _buildKeypadRow(['4', '5', '6']),
                          const SizedBox(height: 16),
                          _buildKeypadRow(['7', '8', '9']),
                          const SizedBox(height: 16),
                          _buildKeypadRow(['', '0', 'backspace']),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const SizedBox(width: 70, height: 50);
        }

        return SizedBox(
          width: 80,
          height: 52,
          child: InkWell(
            onTap: () => _onKeyPress(key),
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: key == 'backspace'
                  ? const Icon(
                      Icons.backspace_outlined,
                      color: Color(0xFF5A607F),
                      size: 22,
                    )
                  : Text(
                      key,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5A607F),
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
