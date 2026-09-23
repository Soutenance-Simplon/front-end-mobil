import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  String? _error;

  @override
  void initState() {
    super.initState();

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
    final success = await ref
        .read(authProvider.notifier)
        .login(
          email: _emailController.text.trim(),
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
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: "Numéro de téléphone ou Email",
                            hintText: "Ex: +221 77 123 45 67",
                            prefixIcon: Icon(Icons.phone_android_rounded),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// PASSWORD
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Mot de passe",
                            prefixIcon: Icon(Icons.lock_outline),
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
                                      color: Colors.green,
                                    ),
                                  )
                                : const Text(
                                    "Connexion",
                                    style: TextStyle(
                                      color: Color(0xFF129A7F), // vert primary
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
