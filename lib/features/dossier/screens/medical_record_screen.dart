import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

class MedicalRecordScreen extends ConsumerStatefulWidget {
  const MedicalRecordScreen({super.key});

  @override
  ConsumerState<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends ConsumerState<MedicalRecordScreen> {
  int _selectedTab = 1; // 0: Résumé, 1: Consultations, 2: Ordonnances, 3: Allergies

  final List<Map<String, dynamic>> _consultations = [
    {
      "date": "12 OCT. 2023",
      "doctor": "Dr. Amadou Sarr • Cardiologue",
      "title": "Hypertension Artérielle",
      "summary": "Suivi régulier. Tension 14/9. Adaptation du traitement en cours.",
      "isLatest": true,
    },
    {
      "date": "05 SEPT. 2023",
      "doctor": "Labo Bio-Médical • Analyse",
      "title": "Bilan Sanguin Complet",
      "summary": "Glycémie à jeun: 0.95 g/L. Cholestérol total: 1.80 g/L.",
      "isLatest": false,
    },
    {
      "date": "22 AOÛT 2023",
      "doctor": "Dr. Ndeye Fall • Généraliste",
      "title": "Infection Respiratoire",
      "summary": "Grippe saisonnière. Repos prescrit 3 jours.",
      "isLatest": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D3142), size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Dossier Médical",
          style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF2D3142)),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PATIENT PROFILE GREEN BANNER CARD
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF146C38),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF146C38).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person, color: Colors.white, size: 30),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              "FATOU DIALLO",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE53935),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                "⚠️ ALLERGIES",
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          "34 ans • Groupe O+",
                                          style: TextStyle(fontSize: 13, color: Colors.white70),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          "📍 Dakar, Médina",
                                          style: TextStyle(fontSize: 12, color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white24, height: 24),
                              const Row(
                                children: [
                                  Icon(Icons.phone_in_talk, color: Colors.white70, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    "Urgence: Moussa Diallo (Époux) +221 77 123 45 67",
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // PERMISSION BADGE
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F7F3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline, size: 14, color: Color(0xFF00A884)),
                                SizedBox(width: 6),
                                Text(
                                  "Accès autorisé par la patiente ✔",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00A884)),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // NAVIGATION TABS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildTabItem(0, Icons.assignment_outlined, "Résumé"),
                            _buildTabItem(1, Icons.medical_services_outlined, "Consultations"),
                            _buildTabItem(2, Icons.medication_outlined, "Ordonnances"),
                            _buildTabItem(3, Icons.warning_amber_rounded, "Allergies"),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // MEDICAL TIMELINE
                        ..._consultations.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // TIMELINE NODE
                                Column(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: item['isLatest'] ? const Color(0xFF146C38) : const Color(0xFFCBD5E1),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Container(
                                      width: 2,
                                      height: 140,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),

                                // TIMELINE CARD
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE6F7F3),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          item['date'],
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF146C38)),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0xFFE5E9F2)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['doctor'],
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF8E95A5)),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['title'],
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item['summary'],
                                              style: const TextStyle(fontSize: 13, color: Color(0xFF5A607F), height: 1.4),
                                            ),
                                            const SizedBox(height: 14),
                                            SizedBox(
                                              width: double.infinity,
                                              height: 40,
                                              child: OutlinedButton(
                                                onPressed: () {},
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(0xFF146C38),
                                                  side: const BorderSide(color: Color(0xFF146C38)),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                child: const Text("Voir détails", style: TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),

                // QUICK ACTION DOCK AT BOTTOM (MEDECIN SEULEMENT)
                if (ref.watch(authProvider).user?.isMedecin == true || ref.watch(authProvider).user?.role.toUpperCase() == 'MEDECIN')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // + DIAGNOSTIC
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/new-consultation'),
                            icon: const Icon(Icons.add, color: Colors.white, size: 18),
                            label: const Text("Diagnostic", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF146C38),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // ORDONNANCE
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/smart-prescription'),
                            icon: const Icon(Icons.medication, color: Colors.white, size: 18),
                            label: const Text("Ordonnance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;

    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF146C38) : const Color(0xFF8E95A5),
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF146C38) : const Color(0xFF8E95A5),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF146C38) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
