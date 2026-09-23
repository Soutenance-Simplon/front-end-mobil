import 'package:flutter/material.dart';

class Specialite {
  final int id;
  final String nom;
  final String description;

  Specialite({
    required this.id,
    required this.nom,
    required this.description,
  });

  factory Specialite.fromJson(Map<String, dynamic> json) {
    return Specialite(
      id: json['id'],
      nom: json['nom_specialite'] ?? '',
      description: json['description_specialite'] ?? '',
    );
  }

  // ===============================
  // 🎨 UI AUTO (POUR DASHBOARD PRO)
  // ===============================

  Color get color {
    const colors = [
      Color(0xFF0EA5A4),
      Color(0xFF6366F1),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF10B981),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
      Color(0xFFEC4899),
    ];
    return colors[id % colors.length];
  }

  IconData get icon {
    const icons = [
      Icons.favorite,
      Icons.psychology,
      Icons.remove_red_eye,
      Icons.healing,
      Icons.medical_services,
      Icons.child_care,
      Icons.pregnant_woman,
      Icons.coronavirus,
      Icons.bloodtype,
    ];
    return icons[id % icons.length];
  }

  int get doctors => (id * 4) + 6;

  String get name => nom;
}
