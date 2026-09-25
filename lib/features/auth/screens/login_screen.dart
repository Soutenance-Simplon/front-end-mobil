import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:country_code_picker/country_code_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _pageController;
  late AnimationController _logoController;
  late AnimationController _shakeController;

  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _logoScale;
  late Animation<double> _shake;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isPhone = true;
  String _countryCode = '+221';

  String? _error;

  @override
  void initState() {
    super.initState();

    _emailController.addListener(_onInputChanged);

    /// Page animation
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _pageController, curve: Curves.easeInOut);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageController, curve: Curves.easeOut));

    /// Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    /// Error shake animation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 0), weight: 1),
    ]).animate(_shakeController);

    _pageController.forward();
    _logoController.forward();
  }

  void _onInputChanged() {
    final text = _emailController.text;
    final hasLetters = text.contains(RegExp(r'[a-zA-Z@]'));
    if (hasLetters && _isPhone) {
      setState(() => _isPhone = false);
    } else if (!hasLetters && !_isPhone) {
      setState(() => _isPhone = true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _logoController.dispose();
    _shakeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final input = _emailController.text.trim();
    final isEmail = input.contains('@');
    final finalInput = isEmail ? input : '$_countryCode$input'.replaceAll(' ', '');

    final success = await ref
        .read(authProvider.notifier)
        .login(
          email: finalInput,
          password: _passwordController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      context.goNamed('dashboard');
    } else {
      setState(() => _error = "Email ou mot de passe incorrect");
      _shakeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shake.value, 0),
                    child: child,
                  );
                },
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// LOGO
                        ScaleTransition(
                          scale: _logoScale,
                          child: Image.asset(
                            'assets/images/diamyaraam.png',
                            width: 300,
                            height: 190,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          "Fàggaru mo gën fadiou,aar sa yàram, aar sa dund",
                          style: AppTextStyles.subtitle,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        /// IDENTIFIANT (TELEPHONE OU EMAIL)
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: _isPhone ? "Numéro de téléphone ou Email (Ex: 77 123 45 67)" : "Email (Ex: jean@mail.com)",
                            prefixIcon: _isPhone
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CountryCodePicker(
                                        onChanged: (code) {
                                          _countryCode = code.dialCode ?? '+221';
                                        },
                                        initialSelection: 'SN',
                                        favorite: const ['+221', 'SN'],
                                        showCountryOnly: false,
                                        showOnlyCountryWhenClosed: false,
                                        alignLeft: false,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        flagWidth: 24,
                                        showFlagMain: true,
                                        showFlag: true,
                                        textStyle: const TextStyle(fontSize: 15, color: Color(0xFF2D3142), fontWeight: FontWeight.w500),
                                      ),
                                      Container(
                                        height: 24,
                                        width: 1,
                                        color: const Color(0xFFE2E8F0),
                                        margin: const EdgeInsets.only(right: 12),
                                      ),
                                    ],
                                  )
                                : const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Icon(Icons.email_outlined),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// PASSWORD
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: "Mot de passe",
                            prefixIcon: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Icon(Icons.lock_outline),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFF8D99AE),
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        /// BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _login,
                            child: authState.isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: const Color(0xFF0D7C66),
                                    ),
                                  )
                                : const Text(
                                    "Connexion",
                                    style: TextStyle(
                                      color: Color(0xFF0D7C66), // vert primary
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),

                        /// REGISTER
                        TextButton(
                          onPressed: () => context.push('/inscription'),
                          child: const Text(
                            "Créer un compte",
                            style: AppTextStyles.link,
                          ),
                        ),

                        /// ERROR
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
