import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String _selectedPeriod = "Matin";
  String _selectedTimeSlot = "10:30";
  String _selectedConsultationType = "TELECONSULTATION"; // TELECONSULTATION ou DOMICILE

  final TextEditingController _locationController = TextEditingController();

  final List<String> _morningSlots = ["09:00", "09:30", "10:00", "10:30", "11:00", "11:30"];
  final List<String> _eveningSlots = ["14:00", "14:30", "15:00", "15:30", "16:00", "17:00"];

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _onGetCurrentLocation() {
    setState(() {
      _locationController.text = "Dakar, Sacré-Cœur 3, Villa N° 45B (Position GPS détectée)";
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Position GPS actuelle ajoutée avec succès"),
        backgroundColor: Color(0xFF00A884),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onContinue() {
    final isHome = _selectedConsultationType == "DOMICILE";

    if (isHome && _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez renseigner votre adresse de localisation pour la visite à domicile."),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final doctorName = widget.doctor['nom'] != null 
        ? "Dr. ${widget.doctor['prenom'] ?? ''} ${widget.doctor['nom']}".trim()
        : "Dr. Praticien";

    final price = isHome ? "15 000 FCFA" : "10 000 FCFA";
    final typeText = isHome ? "Consultation à Domicile" : "Téléconsultation Vidéo";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF00A884), size: 28),
            SizedBox(width: 10),
            Text("RDV Transmis !", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Votre demande a été transmise à $doctorName.",
              style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isHome ? Icons.home_work_rounded : Icons.videocam_rounded, 
                          color: const Color(0xFF00A884), size: 18),
                      const SizedBox(width: 8),
                      Text(typeText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text("🕒 Créneau : $_selectedTimeSlot ($_selectedPeriod)", style: const TextStyle(fontSize: 12, color: Color(0xFF5A607F))),
                  Text("💰 Tarif : $price", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF00A884))),
                  if (isHome) ...[
                    const SizedBox(height: 6),
                    Text("📍 Adresse : ${_locationController.text.trim()}", style: const TextStyle(fontSize: 12, color: Color(0xFF5A607F))),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A884),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text("Retour au Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeSlots = _selectedPeriod == "Matin" ? _morningSlots : _eveningSlots;
    final doctorName = widget.doctor['nom'] != null 
        ? "Dr. ${widget.doctor['prenom'] ?? ''} ${widget.doctor['nom']}".trim()
        : "Dr. Spécialiste";
    final specialty = widget.doctor['specialite'] ?? "Médecine Générale";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    Expanded(
                      child: Text(
                        doctorName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CARTE MEDECIN
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE5E9F2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F7F3),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.person, color: Color(0xFF00A884), size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doctorName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2D3142)),
                                    ),
                                    Text(
                                      specialty,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF00A884), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F7F3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.verified, color: Color(0xFF00A884), size: 12),
                                    SizedBox(width: 4),
                                    Text("Agréé ONMS", style: TextStyle(fontSize: 10, color: Color(0xFF00A884), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          "Type de Consultation",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildConsultationOption(
                          id: "TELECONSULTATION",
                          title: "Téléconsultation Vidéo",
                          subtitle: "Consultation à distance par appel vidéo sécurisé",
                          price: "10 000 FCFA",
                          icon: Icons.videocam_rounded,
                        ),

                        const SizedBox(height: 12),

                        _buildConsultationOption(
                          id: "DOMICILE",
                          title: "Consultation à Domicile",
                          subtitle: "Déplacement et visite médicale à votre adresse",
                          price: "15 000 FCFA",
                          icon: Icons.home_work_rounded,
                        ),

                        if (_selectedConsultationType == "DOMICILE") ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFBBEFDB)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.location_on_rounded, color: Color(0xFF00A884), size: 20),
                                        SizedBox(width: 6),
                                        Text(
                                          "Adresse de Consultation",
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF134E3F)),
                                        ),
                                      ],
                                    ),
                                    InkWell(
                                      onTap: _onGetCurrentLocation,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00A884),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.my_location, color: Colors.white, size: 12),
                                            SizedBox(width: 4),
                                            Text("GPS Actuel", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _locationController,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText: "Ex: Dakar, Mermoz Pyrotechnie, Rue MZ-12, Villa 45...",
                                    hintStyle: const TextStyle(color: Color(0xFF8E95A5), fontSize: 13),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF00A884), width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "💡 Indiquez des repères précis (numéro de villa, pharmacie, boutique) pour faciliter l'arrivée du médecin.",
                                  style: TextStyle(fontSize: 11, color: Color(0xFF5A607F), fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        const Text(
                          "Date & Créneaux Disponibles",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildPeriodTab(
                                id: "Matin",
                                title: "Matinée",
                                icon: Icons.wb_sunny_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPeriodTab(
                                id: "Soir",
                                title: "Après-midi / Soir",
                                icon: Icons.cloud_outlined,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: activeSlots.map((slot) {
                            final isSelected = _selectedTimeSlot == slot;

                            return InkWell(
                              onTap: () => setState(() => _selectedTimeSlot = slot),
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 95,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF00A884) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF00A884) : const Color(0xFFE5E9F2),
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: const Color(0xFF00A884).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    slot,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : const Color(0xFF5A607F),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _selectedConsultationType == "DOMICILE"
                          ? "Confirmer la Visite à Domicile (15 000 FCFA)"
                          : "Confirmer la Téléconsultation (10 000 FCFA)",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsultationOption({
    required String id,
    required String title,
    required String subtitle,
    required String price,
    required IconData icon,
  }) {
    final isSelected = _selectedConsultationType == id;

    return InkWell(
      onTap: () => setState(() => _selectedConsultationType = id),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A884) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A884) : const Color(0xFFE5E9F2),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF00A884).withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFFE6F7F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF00A884),
                size: 24,
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white.withOpacity(0.85) : const Color(0xFF8E95A5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFE6F7F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                price,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF00A884) : const Color(0xFF00A884),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab({
    required String id,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedPeriod == id;

    return InkWell(
      onTap: () => setState(() => _selectedPeriod = id),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: estSelectionne(isSelected),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF00A884) : const Color(0xFFE5E9F2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF8E95A5),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF8E95A5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color estSelectionne(bool sel) => sel ? const Color(0xFF00A884) : Colors.white;
}
