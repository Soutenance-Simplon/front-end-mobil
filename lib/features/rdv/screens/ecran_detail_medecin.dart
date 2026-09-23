import 'package:flutter/material.dart';
import 'doctor_detail_screen.dart';

class EcranDetailMedecin extends StatelessWidget {
  final Map<String, dynamic> medecin;

  const EcranDetailMedecin({super.key, required this.medecin});

  @override
  Widget build(BuildContext context) {
    return DoctorDetailScreen(doctor: medecin);
  }
}
