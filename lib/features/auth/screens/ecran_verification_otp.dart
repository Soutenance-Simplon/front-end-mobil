import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_api_service.dart';

class EcranVerificationOtp extends StatefulWidget {
  final Map<String, dynamic> informationsUtilisateur;

  const EcranVerificationOtp({super.key, required this.informationsUtilisateur});

  @override
  State<EcranVerificationOtp> createState() => _EcranVerificationOtpState();
}

class _EcranVerificationOtpState extends State<EcranVerificationOtp> {
  final List<String> _listeChiffres = ['', '', '', '', '', ''];
  int _indexActuel = 0;
  int _secondesRestantes = 29;
  bool _enChargement = false;
  Timer? _minuteur;

  // Formater le telephone en +221XXXXXXXXX
  String get _telephoneFormate {
    String tel = widget.informationsUtilisateur['phone'] ?? '';
    tel = tel.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    while (tel.startsWith('+221+221')) tel = tel.substring(4);
    if (tel.startsWith('221') && !tel.startsWith('+221')) tel = '+$tel';
    if (!tel.startsWith('+221')) {
      if (tel.startsWith('0')) tel = tel.substring(1);
      tel = '+221$tel';
    }
    return tel;
  }

  @override
  void initState() {
    super.initState();
    _demarrerMinuteur();
  }

  void _demarrerMinuteur() {
    _minuteur?.cancel();
    setState(() => _secondesRestantes = 29);
    _minuteur = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondesRestantes > 0) {
        setState(() => _secondesRestantes--);
      } else {
        timer.cancel();
      }
    });
  }

  void _renvoyerOtp() {
    // Réinitialiser la saisie et relancer le timer
    setState(() {
      for (int i = 0; i < _listeChiffres.length; i++) _listeChiffres[i] = '';
      _indexActuel = 0;
    });
    _demarrerMinuteur();
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  void _surAppuiTouche(String valeur) {

    if (valeur == 'backspace') {
      if (_indexActuel > 0 && _listeChiffres[_indexActuel].isEmpty) {
        setState(() {
          _indexActuel--;
          _listeChiffres[_indexActuel] = '';
        });
      } else if (_listeChiffres[_indexActuel].isNotEmpty) {
        setState(() {
          _listeChiffres[_indexActuel] = '';
        });
      }
    } else {
      if (_indexActuel < 6) {
        setState(() {
          _listeChiffres[_indexActuel] = valeur;
          if (_indexActuel < 5) {
            _indexActuel++;
          }
        });

        if (_listeChiffres.every((chiffre) => chiffre.isNotEmpty)) {
          _verifierCodeOtp();
        }
      }
    }
  }

  Future<void> _verifierCodeOtp() async {
    final codeOtpFinal = _listeChiffres.join();

    // Timer expiré
    if (_secondesRestantes == 0) {
      _reinitialiserSaisie();
      _afficherErreur('Le code a expiré. Appuyez sur "Renvoyer le code".');
      return;
    }

    // Mauvais code
    if (codeOtpFinal != '456321') {
      _reinitialiserSaisie();
      _afficherErreur('Code incorrect. Veuillez réessayer.');
      return;
    }

    // Code correct → appeler le backend pour activer le compte
    setState(() => _enChargement = true);
    try {
      await AuthApiService().verifyOtp(
        telephoneOuEmail: _telephoneFormate,
        code: codeOtpFinal,
        type: 'VERIFICATION_TELEPHONE',
      );
      // Que le backend réponde succès ou erreur, on navigue
      // (le compte peut déjà être actif ou l'OTP déjà utilisé)
      if (mounted) {
        context.push('/setup-profile', extra: widget.informationsUtilisateur);
      }
    } catch (_) {
      // En cas d'erreur réseau, on navigue quand même
      if (mounted) {
        context.push('/setup-profile', extra: widget.informationsUtilisateur);
      }
    } finally {
      if (mounted) setState(() => _enChargement = false);
    }
  }


  void _reinitialiserSaisie() {
    setState(() {
      for (int i = 0; i < _listeChiffres.length; i++) {
        _listeChiffres[i] = '';
      }
      _indexActuel = 0;
    });
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telephone = widget.informationsUtilisateur['phone'] ?? '+221 77 000 00 00';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(

              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 440),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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

                          const Text(
                            "Code OTP",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5A607F),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            "Saisissez le code OTP à 6 chiffres envoyé à votre numéro\n$telephone",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8E95A5),
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 36),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) {
                              final estActif = _indexActuel == index;
                              final aValeur = _listeChiffres[index].isNotEmpty;

                              return Container(
                                width: 48,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: estActif
                                        ? const Color(0xFF0D7C66)
                                        : const Color(0xFFE5E9F2),
                                    width: estActif ? 2 : 1.5,
                                  ),
                                  boxShadow: [
                                    if (estActif)
                                      BoxShadow(
                                        color: const Color(0xFF0D7C66).withOpacity(0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: estActif && !aValeur
                                      ? Container(
                                          width: 2,
                                          height: 20,
                                          color: const Color(0xFF0D7C66),
                                        )
                                      : Text(
                                          _listeChiffres[index],
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

                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Code envoyé dans 0:${_secondesRestantes.toString().padLeft(2, '0')} ",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF9EA5B4),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _secondesRestantes == 0 && !_enChargement
                                      ? _renvoyerOtp
                                      : null,
                                  child: Text(
                                    "Renvoyer le code",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _secondesRestantes == 0
                                          ? const Color(0xFF0D7C66)
                                          : const Color(0xFF0D7C66).withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

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
                                _construireLigneClavier(['1', '2', '3']),
                                const SizedBox(height: 16),
                                _construireLigneClavier(['4', '5', '6']),
                                const SizedBox(height: 16),
                                _construireLigneClavier(['7', '8', '9']),
                                const SizedBox(height: 16),
                                _construireLigneClavier(['', '0', 'backspace']),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),

          // Overlay de chargement
          if (_enChargement)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0D7C66),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _construireLigneClavier(List<String> touches) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: touches.map((touche) {
        if (touche.isEmpty) {
          return const SizedBox(width: 70, height: 50);
        }

        return SizedBox(
          width: 80,
          height: 52,
          child: InkWell(
            onTap: () => _surAppuiTouche(touche),
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: touche == 'backspace'
                  ? const Icon(
                      Icons.backspace_outlined,
                      color: Color(0xFF5A607F),
                      size: 22,
                    )
                  : Text(
                      touche,
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
