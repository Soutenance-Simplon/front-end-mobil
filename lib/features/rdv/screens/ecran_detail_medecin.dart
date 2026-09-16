import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EcranDetailMedecin extends StatefulWidget {
  final Map<String, dynamic> medecin;

  const EcranDetailMedecin({super.key, required this.medecin});

  @override
  State<EcranDetailMedecin> createState() => _EcranDetailMedecinState();
}

class _EcranDetailMedecinState extends State<EcranDetailMedecin> {
  bool _estFavoris = false;
  int _indexDateSelectionnee = 0;

  final List<Map<String, String>> _listeDates = [
    {"jour": "LUN", "date": "10"},
    {"jour": "MAR", "date": "11"},
    {"jour": "MER", "date": "12"},
    {"jour": "JEU", "date": "13"},
    {"jour": "VEN", "date": "14"},
    {"jour": "SAM", "date": "15"},
  ];

  @override
  Widget build(BuildContext context) {
    final nom = widget.medecin['nom'] ?? 'Dr. Mahmud Nik';
    final specialite = widget.medecin['specialite'] ?? 'Cardiologue - Hôpital Fann';
    final image = widget.medecin['image'] ?? "https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=300&q=80";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => context.pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 42,
                            height: 42,
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

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                image,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 90,
                                  height: 90,
                                  color: const Color(0xFFEAEAEA),
                                  child: const Icon(Icons.person, size: 40, color: Color(0xFF8E95A5)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nom,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    specialite,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF8E95A5),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A884),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.people_outline, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "1000+",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        "Patients",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              Container(width: 1, height: 36, color: Colors.white24),

                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.workspace_premium_outlined, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "5 Ans",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        "D'expérience",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          "À propos du médecin",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A607F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Spécialiste agréé par l'Ordre National des Médecins du Sénégal (ONMS). "
                          "Disponible pour des consultations au cabinet et en ligne via la plateforme Diam Yaraam.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E95A5),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          "Horaires de travail",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A607F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Lun - Ven 09:00 - 20:00",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E95A5),
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _listeDates.length,
                            itemBuilder: (context, index) {
                              final element = _listeDates[index];
                              final estSelectionnee = _indexDateSelectionnee == index;

                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: InkWell(
                                  onTap: () => setState(() => _indexDateSelectionnee = index),
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: estSelectionnee ? const Color(0xFF00A884) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: estSelectionnee ? const Color(0xFF00A884) : const Color(0xFFE5E9F2),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          element['jour']!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: estSelectionnee ? Colors.white70 : const Color(0xFFB4B9C5),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          element['date']!,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: estSelectionnee ? Colors.white : const Color(0xFF5A607F),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

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
                      InkWell(
                        onTap: () => setState(() => _estFavoris = !_estFavoris),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7F3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _estFavoris ? Icons.favorite : Icons.favorite_border,
                            color: const Color(0xFF00A884),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              context.push('/prise-rendez-vous', extra: widget.medecin);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A884),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Prendre rendez-vous",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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
}
