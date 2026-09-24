import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DoctorAgendaScreen extends StatefulWidget {
  const DoctorAgendaScreen({super.key});

  @override
  State<DoctorAgendaScreen> createState() => _DoctorAgendaScreenState();
}

class _DoctorAgendaScreenState extends State<DoctorAgendaScreen> {
  int _selectedDayIndex = 2; // M 06

  final List<Map<String, String>> _days = [
    {"letter": "L", "num": "04"},
    {"letter": "M", "num": "05"},
    {"letter": "M", "num": "06"},
    {"letter": "J", "num": "07"},
    {"letter": "V", "num": "08"},
    {"letter": "S", "num": "09"},
    {"letter": "D", "num": "10"},
  ];

  final List<Map<String, dynamic>> _pendingRequests = [
    {
      "id": "1",
      "name": "Ousmane Diop",
      "time": "Aujourd'hui, 16:30",
      "motif": "Douleurs thoraciques",
      "status": "pending",
    },
    {
      "id": "2",
      "name": "Ibrahim Ndiaye",
      "time": "Demain, 10:00",
      "motif": "Suivi post-opératoire",
      "status": "pending",
    },
  ];

  void _handleRequest(int index, bool accept) {
    setState(() {
      _pendingRequests.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(accept ? "Rendez-vous accepté !" : "Rendez-vous refusé"),
        backgroundColor: accept ? const Color(0xFF0D7C66) : const Color(0xFFE53935),
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
          "Mon Agenda",
          style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFE7F2F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Color(0xFF0D7C66), size: 20),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MONTH PICKER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Décembre 2023",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Color(0xFF5A607F)),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Color(0xFF5A607F)),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // DAY PICKER HORIZONTAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_days.length, (index) {
                      final item = _days[index];
                      final isSelected = _selectedDayIndex == index;

                      return InkWell(
                        onTap: () => setState(() => _selectedDayIndex = index),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0D7C66) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item['letter']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white70 : const Color(0xFF8E95A5),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['num']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFF2D3142),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // LEGEND
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _LegendItem(color: Color(0xFF0D7C66), label: "DISPONIBLE"),
                      _LegendItem(color: Color(0xFFE53935), label: "OCCUPÉ"),
                      _LegendItem(color: Color(0xFF0D7C66), label: "TÉLÉCONSULT."),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // TIME SLOTS LIST
                  _buildSlotCard(
                    time: "08:00",
                    title: "Disponible",
                    subtitle: "Plage horaire libre",
                    color: const Color(0xFF0D7C66),
                    bgColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  _buildSlotCard(
                    time: "09:30",
                    title: "Mme Diallo",
                    subtitle: "📹 Téléconsultation",
                    color: const Color(0xFF0D7C66),
                    bgColor: const Color(0xFFF0F8FF),
                    hasMore: true,
                  ),
                  const SizedBox(height: 12),
                  _buildSlotCard(
                    time: "11:00",
                    title: "M. Sarr",
                    subtitle: "🏥 Consultation Cabinet",
                    color: const Color(0xFFE53935),
                    bgColor: const Color(0xFFFFECEB),
                    hasMore: true,
                  ),
                  const SizedBox(height: 12),
                  _buildSlotCard(
                    time: "14:00",
                    title: "Disponible",
                    subtitle: "Plage horaire libre",
                    color: const Color(0xFF0D7C66),
                    bgColor: Colors.white,
                  ),

                  const SizedBox(height: 28),

                  // PENDING REQUESTS SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Demandes en attente (${_pendingRequests.length})",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      const Text(
                        "Tout voir",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D7C66),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  ..._pendingRequests.asMap().entries.map((entry) {
                    final index = entry.key;
                    final req = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E9F2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF4F6F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person, color: Color(0xFF8E95A5)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      req['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D3142),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Motif: ${req['motif']}",
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF8E95A5)),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                req['time'],
                                style: const TextStyle(fontSize: 11, color: Color(0xFF8E95A5)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _handleRequest(index, false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFE53935),
                                    side: const BorderSide(color: Color(0xFFFFCDD2)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text("✕ Refuser"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _handleRequest(index, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D7C66),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text("✓ Accepter", style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 20),

                  // GERER MES DISPONIBILITES BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.history, color: Color(0xFF0D7C66)),
                      label: const Text(
                        "Gérer mes disponibilités",
                        style: TextStyle(color: Color(0xFF0D7C66), fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0D7C66), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotCard({
    required String time,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    bool hasMore = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8E95A5),
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: title == "Disponible" ? color : const Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF8E95A5)),
                      ),
                    ],
                  ),
                ),
                if (hasMore)
                  const Icon(Icons.more_vert, color: Color(0xFF8E95A5), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8E95A5),
          ),
        ),
      ],
    );
  }
}
