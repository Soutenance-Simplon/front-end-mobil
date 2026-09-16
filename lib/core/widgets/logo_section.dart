import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LogoSection extends StatelessWidget {
  const LogoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // color: const Color(0xFF129A7F),
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/diamyaraam.png',
              width: 300,
              height: 190,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            const Text(
              "Fàggaru mo gën fadiou,aar sa yàram, aar sa dund",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:   AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
