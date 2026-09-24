import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/planning_provider.dart';
import '../../medecin/models/creneau_model.dart';

class EcranAgendaMedecin extends ConsumerStatefulWidget {
  const EcranAgendaMedecin({super.key});

  @override
  ConsumerState<EcranAgendaMedecin> createState() => _EcranAgendaMedecinState();
}

class _EcranAgendaMedecinState extends ConsumerState<EcranAgendaMedecin> {
  DateTime _dateSelectionnee = DateTime.now();
  late List<DateTime> _joursSemaine;

  @override
  void initState() {
    super.initState();
    _calculerSemaine();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chargerCreneaux();
    });
  }

  String get _medecinId {
    final user = ref.read(authProvider).user;
    if (user != null && user.id.isNotEmpty) {
      return user.id;
    }
    return "med-1";
  }

  void _chargerCreneaux() {
    ref.read(planningProvider.notifier).chargerCreneauxDuMedecin(_medecinId);
  }

  void _calculerSemaine() {
    final now = _dateSelectionnee;
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _joursSemaine = List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  bool _memeJour(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  void _ajouterNouveauCreneau() {
    TimeOfDay heureDebut = const TimeOfDay(hour: 9, minute: 0);
    int dureeMinutes = 30;
    String typeConsultation = "TÉLÉCONSULT.";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final heureFinMinutes = heureDebut.hour * 60 + heureDebut.minute + dureeMinutes;
          final finHeure = (heureFinMinutes ~/ 60) % 24;
          final finMinute = heureFinMinutes % 60;
          final heureFinStr = "${finHeure.toString().padLeft(2, '0')}:${finMinute.toString().padLeft(2, '0')}";
          final heureDebutStr = "${heureDebut.hour.toString().padLeft(2, '0')}:${heureDebut.minute.toString().padLeft(2, '0')}";

          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Ajouter un créneau",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF8E95A5)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  "Date : ${DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_dateSelectionnee)}",
                  style: const TextStyle(fontSize: 13, color: Color(0xFF00A884), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),

                // Heure de début
                const Text(
                  "Heure de début",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142)),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: heureDebut,
                    );
                    if (time != null) {
                      setModalState(() => heureDebut = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, color: Color(0xFF00A884), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              heureDebutStr,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                            ),
                          ],
                        ),
                        const Text("Modifier", style: TextStyle(color: Color(0xFF00A884), fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Durée
                const Text(
                  "Durée de la consultation",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [15, 30, 45, 60].map((duree) {
                    final estChoisi = dureeMinutes == duree;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => setModalState(() => dureeMinutes = duree),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: estChoisi ? const Color(0xFF00A884) : const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: estChoisi ? const Color(0xFF00A884) : const Color(0xFFE2E8F0)),
                            ),
                            child: Center(
                              child: Text(
                                "$duree min",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: estChoisi ? Colors.white : const Color(0xFF5A607F),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Type de consultation
                const Text(
                  "Type de consultation",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setModalState(() => typeConsultation = "TÉLÉCONSULT."),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: typeConsultation == "TÉLÉCONSULT." ? const Color(0xFFE6F7F3) : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: typeConsultation == "TÉLÉCONSULT." ? const Color(0xFF00A884) : const Color(0xFFE2E8F0),
                              width: typeConsultation == "TÉLÉCONSULT." ? 1.5 : 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_rounded, color: Color(0xFF00A884), size: 18),
                              SizedBox(width: 8),
                              Text(
                                "Téléconsultation",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00A884)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => setModalState(() => typeConsultation = "CABINET"),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: typeConsultation == "CABINET" ? const Color(0xFFE6F7F3) : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: typeConsultation == "CABINET" ? const Color(0xFF00A884) : const Color(0xFFE2E8F0),
                              width: typeConsultation == "CABINET" ? 1.5 : 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_hospital_rounded, color: Color(0xFF00A884), size: 18),
                              SizedBox(width: 8),
                              Text(
                                "En Cabinet",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00A884)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Bouton de validation
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      final dateDebut = DateTime(
                        _dateSelectionnee.year,
                        _dateSelectionnee.month,
                        _dateSelectionnee.day,
                        heureDebut.hour,
                        heureDebut.minute,
                      );
                      final dateFin = dateDebut.add(Duration(minutes: dureeMinutes));

                      if (dateDebut.isBefore(DateTime.now())) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Expanded(child: Text("Impossible de créer un créneau pour une date ou une heure passée.")),
                              ],
                            ),
                            backgroundColor: Color(0xFFEF4444),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      try {
                        await ref.read(planningProvider.notifier).ajouterCreneau(
                          medecinId: _medecinId,
                          dateHeureDebut: dateDebut,
                          dateHeureFin: dateFin,
                          typeConsultation: typeConsultation == "TÉLÉCONSULT." ? "TELECONSULTATION" : "PRESENTIELLE",
                        );

                        nav.pop();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text("Créneau $heureDebutStr - $heureFinStr enregistré avec succès !")),
                              ],
                            ),
                            backgroundColor: const Color(0xFF00A884),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        final cleanMsg = e.toString().replaceFirst("Exception: ", "");
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(cleanMsg)),
                              ],
                            ),
                            backgroundColor: const Color(0xFFEF4444),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      "Créer le créneau ($heureDebutStr - $heureFinStr)",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _ouvrirMatinneeRapide() async {
    final heures = ["09:00", "09:30", "10:00", "10:30", "11:00", "11:30"];
    final fins = ["09:30", "10:00", "10:30", "11:00", "11:30", "12:00"];
    int ajoutes = 0;
    int ignores = 0;

    for (int i = 0; i < heures.length; i++) {
      final hParts = heures[i].split(':');
      final fParts = fins[i].split(':');
      final start = DateTime(_dateSelectionnee.year, _dateSelectionnee.month, _dateSelectionnee.day, int.parse(hParts[0]), int.parse(hParts[1]));
      final end = DateTime(_dateSelectionnee.year, _dateSelectionnee.month, _dateSelectionnee.day, int.parse(fParts[0]), int.parse(fParts[1]));

      try {
        await ref.read(planningProvider.notifier).ajouterCreneau(
          medecinId: _medecinId,
          dateHeureDebut: start,
          dateHeureFin: end,
          typeConsultation: i % 2 == 0 ? "TELECONSULTATION" : "PRESENTIELLE",
        );
        ajoutes++;
      } catch (_) {
        ignores++;
      }
    }

    if (mounted) {
      if (ajoutes > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("$ajoutes créneaux générés avec succès !" + (ignores > 0 ? " ($ignores créneaux en doublon/collision ignorés)" : "")),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF00A884),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text("Tous les créneaux de cette matinée existent déjà ou sont en conflit.")),
              ],
            ),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _changerStatutCreneau(CreneauModel creneau) {
    final heureDebutStr = DateFormat('HH:mm').format(creneau.dateHeureDebut);
    final heureFinStr = DateFormat('HH:mm').format(creneau.dateHeureFin);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Gérer le créneau $heureDebutStr - $heureFinStr",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Statut actuel : ${creneau.statut}",
              style: const TextStyle(fontSize: 13, color: Color(0xFF8E95A5)),
            ),
            const SizedBox(height: 20),

            if (creneau.statut == 'DISPONIBLE')
              ListTile(
                leading: const Icon(Icons.block, color: Color(0xFFEF4444)),
                title: const Text("Bloquer ce créneau (Indisponible)"),
                onTap: () {
                  ref.read(planningProvider.notifier).bloquerCreneau(creneauId: creneau.id);
                  Navigator.pop(context);
                },
              ),

            if (creneau.statut == 'BLOQUE')
              ListTile(
                leading: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                title: const Text("Débloquer / Rendre disponible"),
                onTap: () {
                  ref.read(planningProvider.notifier).debloquerCreneau(creneauId: creneau.id);
                  Navigator.pop(context);
                },
              ),

            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              title: const Text("Supprimer ce créneau", style: TextStyle(color: Color(0xFFEF4444))),
              onTap: () {
                ref.read(planningProvider.notifier).supprimerCreneau(creneauId: creneau.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planningState = ref.watch(planningProvider);

    // Extraction en temps réel des créneaux réels pour le jour sélectionné
    final creneauxDuJour = planningState.tousLesCreneaux.where((c) {
      return _memeJour(c.dateHeureDebut, _dateSelectionnee);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // EN-TÊTE
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
                    const Expanded(
                      child: Text(
                        "Gestion des Créneaux",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _ajouterNouveauCreneau,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A884),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // BARRE DE SÉLECTION DU JOUR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy', 'fr_FR').format(_dateSelectionnee).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A607F),
                        letterSpacing: 0.5,
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dateSelectionnee.isBefore(DateTime.now()) ? DateTime.now() : _dateSelectionnee,
                          firstDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                          lastDate: DateTime.now().add(const Duration(days: 120)),
                        );
                        if (picked != null) {
                          setState(() {
                            _dateSelectionnee = picked;
                            _calculerSemaine();
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.calendar_today, size: 13, color: Color(0xFF00A884)),
                            SizedBox(width: 6),
                            Text("Calendrier", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5A607F))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // DÉFILEMENT DES JOURS DE LA SEMAINE
                SizedBox(
                  height: 72,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _joursSemaine.length,
                    itemBuilder: (context, index) {
                      final jour = _joursSemaine[index];
                      final estSelectionne = _memeJour(jour, _dateSelectionnee);
                      final nomJour = DateFormat('EEE', 'fr_FR').format(jour).toUpperCase();
                      final numJour = DateFormat('d').format(jour);

                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _dateSelectionnee = jour;
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 58,
                            decoration: BoxDecoration(
                              color: estSelectionne ? const Color(0xFF00A884) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: estSelectionne ? const Color(0xFF00A884) : const Color(0xFFE5E9F2),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  nomJour,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: estSelectionne ? Colors.white70 : const Color(0xFFB4B9C5),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  numJour,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: estSelectionne ? Colors.white : const Color(0xFF5A607F),
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

                const SizedBox(height: 16),

                // BOUTONS D'ACTION RAPIDE
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _ajouterNouveauCreneau,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A884),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text("+ Créneau", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _ouvrirMatinneeRapide,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00A884),
                          side: const BorderSide(color: Color(0xFF00A884), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.wb_sunny_outlined, size: 18),
                        label: const Text("Ouvrir Matinée", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // LISTE DES CRÉNEAUX DU JOUR
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Planning des consultations",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F7F3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${creneauxDuJour.length} créneau(x)",
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00A884)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (planningState.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(30),
                              child: CircularProgressIndicator(color: Color(0xFF00A884)),
                            ),
                          )
                        else if (creneauxDuJour.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE5E9F2)),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.event_note, color: Color(0xFF8E95A5), size: 36),
                                const SizedBox(height: 8),
                                const Text(
                                  "Aucun créneau ouvert pour ce jour",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142)),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Cliquez sur « + Créneau » ou « Ouvrir Matinée » pour définir vos disponibilités.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Color(0xFF8E95A5)),
                                ),
                              ],
                            ),
                          )
                        else
                          ...creneauxDuJour.map((creneau) {
                            final heureDebutStr = DateFormat('HH:mm').format(creneau.dateHeureDebut);
                            final heureFinStr = DateFormat('HH:mm').format(creneau.dateHeureFin);
                            final estDispo = creneau.statut == 'DISPONIBLE';
                            final estReserve = creneau.statut == 'RESERVE';
                            final isVisio = creneau.typeConsultation == 'TELECONSULTATION';

                            final couleur = estDispo
                                ? const Color(0xFF10B981)
                                : (estReserve ? const Color(0xFF00A884) : const Color(0xFF94A3B8));

                            return InkWell(
                              onTap: () => _changerStatutCreneau(creneau),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE5E9F2)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: couleur,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "$heureDebutStr - $heureFinStr",
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2D3142),
                                          ),
                                        ),
                                        Text(
                                          isVisio ? "Téléconsultation Vidéo" : "Consultation Cabinet",
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF8E95A5)),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: couleur.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        creneau.statut,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: couleur,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
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
}
