import 'package:flutter/material.dart';

/// Palette unifiée et sobre de Diam-Yaraam
/// Conforme aux standards médicaux internationaux (Doctolib, Apple Health)
class AppColors {
  // Couleurs de marque principales
  static const Color primary = Color(0xFF00A884); // Vert médical officiel Diam-Yaraam
  static const Color primaryLight = Color(0xFFE6F7F3); // Teinte douce pour puces & icônes
  static const Color primaryDark = Color(0xFF064E3B);

  // Espace Praticien
  static const Color doctorPrimary = Color(0xFF00A884); // Bleu clinique sobre
  static const Color doctorLight = Color(0xFFE6F7F3);

  // Surfaces & Fond
  static const Color bgLight = Color(0xFFF8FAFC); // Fond sobre Slate-50
  static const Color cardBg = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0); // Bordure neutre Slate-200
  static const Color white = Colors.white;

  // Typographie Slate
  static const Color textDark = Color(0xFF1E293B); // Titres Slate-800
  static const Color textGrey = Color(0xFF64748B); // Sous-titres Slate-500
  static const Color textMuted = Color(0xFF94A3B8); // Muted Slate-400

  // Statuts fonctionnels (utilisés uniquement avec parcimonie)
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color success = Color(0xFF10B981);
}

