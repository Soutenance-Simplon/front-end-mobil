import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/rendez_vous_model.dart';
import '../providers/planning_provider.dart';
import '../providers/rdv_provider.dart';
import '../../medecin/models/creneau_model.dart';

/// Écran d'Agenda et Planning du Médecin
/// Créneaux découpés par tranche de 1 heure (ex: 12h-13h, 13h-14h, 14h-15h...)
class DoctorAgendaScreen extends ConsumerStatefulWidget {
  const DoctorAgendaScreen({super.key});

  @override
  ConsumerState<DoctorAgendaScreen> createState() => _DoctorAgendaScreenState();
}

class _DoctorAgendaScreenState extends ConsumerState<DoctorAgendaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _dateSelectionnee = DateTime.now();
  late List<DateTime> _joursSemaine;
  String _filtreConsultations = "Tous"; // "Tous", "Aujourd'hui", "À venir", "Terminés"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calculerSemaine();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rafraichirDonnees();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _medecinId {
    final user = ref.read(authProvider).user;
    if (user != null && user.id.isNotEmpty) {
      return user.id;
    }
    return "med-1";
  }

  void _calculerSemaine() {
    final now = _dateSelectionnee;
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _joursSemaine = List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  bool _memeJour(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<void> _rafraichirDonnees() async {
    final medId = _medecinId;
    await Future.wait([
      ref.read(rdvProvider.notifier).loadAgendaMedecin(medecinId: medId),
      ref.read(planningProvider.notifier).chargerCreneauxDuMedecin(medId),
    ]);
  }

  // =========================================================================
  // ACTIONS SUR LES CRÉNEAUX : DÉCOUPAGE PAR TRANCHE D'1 HEURE
  // =========================================================================

  /// Modal ergonomique permettant au médecin de définir une plage horaire
  /// (ex: 12h à 16h) qui sera automatiquement découpée en créneaux de 1 heure
  void _ouvrirModalPlageHoraire() {
    int heureDebut = 12; // 12h00 par défaut
    int heureFin = 16;   // 16h00 par défaut

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (heureFin <= heureDebut) {
            heureFin = heureDebut + 1;
          }
          final nbCreneaux = heureFin - heureDebut;

          // Aperçu des tranches d'1h découpées
          final tranchesApercu = List.generate(nbCreneaux, (i) {
            final hStart = heureDebut + i;
            final hEnd = hStart + 1;
            return "${hStart.toString().padLeft(2, '0')}:00 - ${hEnd.toString().padLeft(2, '0')}:00";
          });

          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Ouvrir une plage horaire",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F2F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF0D7C66)),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_dateSelectionnee),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0D7C66),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SÉLECTEUR HEURE DE DÉBUT ET HEURE DE FIN
                  Row(
                    children: [
                      // Heure de début
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "De (Heure début)",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFC3DED9)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: heureDebut,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0D7C66)),
                                  items: List.generate(24, (h) => h).map((h) {
                                    return DropdownMenuItem<int>(
                                      value: h,
                                      child: Text(
                                        "${h.toString().padLeft(2, '0')}:00",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() {
                                        heureDebut = val;
                                        if (heureFin <= heureDebut) {
                                          heureFin = (heureDebut + 1).clamp(1, 24);
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Heure de fin
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "À (Heure fin)",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFC3DED9)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: heureFin,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0D7C66)),
                                  items: List.generate(24, (h) => h + 1).map((h) {
                                    return DropdownMenuItem<int>(
                                      value: h,
                                      enabled: h > heureDebut,
                                      child: Text(
                                        "${h.toString().padLeft(2, '0')}:00",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: h > heureDebut ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null && val > heureDebut) {
                                      setModalState(() => heureFin = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ENCART DÉCOUPAGE AUTOMATIQUE PAR TRANCHE D'1 HEURE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF0D7C66), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Découpage automatique : $nbCreneaux créneau(x) de 1h",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D7C66)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tranchesApercu.map((t) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7F2F0),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFC3DED9)),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D7C66)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BOUTON DE VALIDATION
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final nav = Navigator.of(ctx);
                        final scaffold = ScaffoldMessenger.of(context);

                        int ajoutes = 0;
                        int ignores = 0;

                        for (int h = heureDebut; h < heureFin; h++) {
                          final start = DateTime(
                            _dateSelectionnee.year,
                            _dateSelectionnee.month,
                            _dateSelectionnee.day,
                            h,
                            0,
                          );
                          final end = DateTime(
                            _dateSelectionnee.year,
                            _dateSelectionnee.month,
                            _dateSelectionnee.day,
                            h + 1,
                            0,
                          );

                          if (start.isBefore(DateTime.now())) {
                            ignores++;
                            continue;
                          }

                          try {
                            await ref.read(planningProvider.notifier).ajouterCreneau(
                              medecinId: _medecinId,
                              dateHeureDebut: start,
                              dateHeureFin: end,
                              typeConsultation: "TELECONSULTATION",
                            );
                            ajoutes++;
                          } catch (_) {
                            ignores++;
                          }
                        }

                        nav.pop();

                        if (ajoutes > 0) {
                          scaffold.showSnackBar(
                            SnackBar(
                              content: Text(
                                "$ajoutes créneau(x) d'1h généré(s) de ${heureDebut.toString().padLeft(2, '0')}:00 à ${heureFin.toString().padLeft(2, '0')}:00 !" +
                                    (ignores > 0 ? " ($ignores ignorés car passés ou déjà existants)" : ""),
                              ),
                              backgroundColor: const Color(0xFF0D7C66),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          scaffold.showSnackBar(
                            const SnackBar(
                              content: Text("Aucun créneau créé : les heures sont déjà passées ou existent déjà."),
                              backgroundColor: Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D7C66),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                      label: Text(
                        "Ouvrir ces $nbCreneaux créneaux de 1h",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Ouverture rapide matinée découpée par 1h : 08:00 à 13:00 (5 créneaux d'1h)
  void _ouvrirMatinneeRapide() async {
    final heures = [8, 9, 10, 11, 12];
    int ajoutes = 0;
    int ignores = 0;

    for (final h in heures) {
      final start = DateTime(_dateSelectionnee.year, _dateSelectionnee.month, _dateSelectionnee.day, h, 0);
      final end = DateTime(_dateSelectionnee.year, _dateSelectionnee.month, _dateSelectionnee.day, h + 1, 0);

      if (start.isBefore(DateTime.now())) {
        ignores++;
        continue;
      }

      try {
        await ref.read(planningProvider.notifier).ajouterCreneau(
          medecinId: _medecinId,
          dateHeureDebut: start,
          dateHeureFin: end,
          typeConsultation: "TELECONSULTATION",
        );
        ajoutes++;
      } catch (_) {
        ignores++;
      }
    }

    if (!mounted) return;
    if (ajoutes > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "$ajoutes créneaux d'1h ouverts pour la matinée (08h - 13h) !" +
                (ignores > 0 ? " ($ignores ignorés car déjà passés)" : ""),
          ),
          backgroundColor: const Color(0xFF0D7C66),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aucun créneau créé : les horaires de matinée sont déjà passés ou existent déjà."),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Ouverture rapide après-midi découpée par 1h : 14:00 à 18:00 (4 créneaux d'1h)
  void _ouvrirApresMidiRapide() async {
    final heures = [14, 15, 16, 17];
    int ajoutes = 0;
    int ignores = 0;

    for (final h in heures) {
      final start = DateTime(_dateSelectionnee.year, _dateSelectionnee.month, _dateSelectionnee.day, h, 0);
      final end = DateTime(_dateSelectionnee.year, _dateSelectionnee.month, _dateSelectionnee.day, h + 1, 0);

      if (start.isBefore(DateTime.now())) {
        ignores++;
        continue;
      }

      try {
        await ref.read(planningProvider.notifier).ajouterCreneau(
          medecinId: _medecinId,
          dateHeureDebut: start,
          dateHeureFin: end,
          typeConsultation: "TELECONSULTATION",
        );
        ajoutes++;
      } catch (_) {
        ignores++;
      }
    }

    if (!mounted) return;
    if (ajoutes > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "$ajoutes créneaux d'1h ouverts pour l'après-midi (14h - 18h) !" +
                (ignores > 0 ? " ($ignores ignorés car déjà passés)" : ""),
          ),
          backgroundColor: const Color(0xFF0D7C66),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aucun créneau créé : les horaires sont déjà passés ou existent déjà."),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Ouverture rapide soirée découpée par 1h : 18:00 à 22:00 (4 créneaux d'1h)
  void _ouvrirSoireeRapide() async {
    final heures = [18, 19, 20, 21];
    int ajoutes = 0;
    int ignores = 0;

    for (final h in heures) {
      final start = DateTime(_dateSelectionnee.year, _dateSelectionnee.month, _dateSelectionnee.day, h, 0);
      final end = DateTime(_dateSelectionnee.year, _dateSelectionnee.month, _dateSelectionnee.day, h + 1, 0);

      if (start.isBefore(DateTime.now())) {
        ignores++;
        continue;
      }

      try {
        await ref.read(planningProvider.notifier).ajouterCreneau(
          medecinId: _medecinId,
          dateHeureDebut: start,
          dateHeureFin: end,
          typeConsultation: "TELECONSULTATION",
        );
        ajoutes++;
      } catch (_) {
        ignores++;
      }
    }

    if (!mounted) return;
    if (ajoutes > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "$ajoutes créneaux d'1h ouverts pour la soirée (18h - 22h) !" +
                (ignores > 0 ? " ($ignores ignorés car déjà passés)" : ""),
          ),
          backgroundColor: const Color(0xFF0D7C66),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aucun créneau créé : les horaires sont déjà passés ou existent déjà."),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _gererCreneau(CreneauModel creneau) {
    final heureDebutStr = DateFormat('HH:mm').format(creneau.dateHeureDebut);
    final heureFinStr = DateFormat('HH:mm').format(creneau.dateHeureFin);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Créneau $heureDebutStr - $heureFinStr (1h)",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              "Statut actuel : ${creneau.statut}",
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),

            if (creneau.statut == 'DISPONIBLE')
              ListTile(
                leading: const Icon(Icons.block_rounded, color: Color(0xFFF59E0B)),
                title: const Text("Bloquer ce créneau temporairement"),
                subtitle: const Text("Les patients ne pourront plus le réserver"),
                onTap: () {
                  ref.read(planningProvider.notifier).bloquerCreneau(creneauId: creneau.id);
                  Navigator.pop(ctx);
                },
              ),

            if (creneau.statut == 'BLOQUE')
              ListTile(
                leading: const Icon(Icons.lock_open_rounded, color: Color(0xFF0D7C66)),
                title: const Text("Rendre à nouveau disponible"),
                subtitle: const Text("Réouvrir ce créneau à la réservation"),
                onTap: () {
                  ref.read(planningProvider.notifier).debloquerCreneau(creneauId: creneau.id);
                  Navigator.pop(ctx);
                },
              ),

            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              title: const Text("Supprimer le créneau", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
              onTap: () {
                ref.read(planningProvider.notifier).supprimerCreneau(creneauId: creneau.id);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Créneau d'1h supprimé du planning"),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // INTERFACE PRINCIPALE
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final rdvState = ref.watch(rdvProvider);
    final planningState = ref.watch(planningProvider);

    // Filtrer les créneaux pour le jour sélectionné
    final creneauxDuJour = planningState.tousLesCreneaux.where((c) {
      return _memeJour(c.dateHeureDebut, _dateSelectionnee);
    }).toList()
      ..sort((a, b) => a.dateHeureDebut.compareTo(b.dateHeureDebut));

    final creneauxDispos = creneauxDuJour.where((c) => c.statut == 'DISPONIBLE').length;

    // Filtrer les rendez-vous du médecin
    final allRdvs = rdvState.agendaMedecin;
    final rdvsDuJour = allRdvs.where((r) => _memeJour(r.dateHeure, _dateSelectionnee)).toList();
    final visiosDuJour = rdvsDuJour.where((r) => r.typeConsultation == 'TELECONSULTATION').length;

    // RDVs selon filtre sélectionné
    final List<RendezVousModel> rdvsFiltres;
    if (_filtreConsultations == "Aujourd'hui") {
      rdvsFiltres = allRdvs.where((r) => _memeJour(r.dateHeure, DateTime.now())).toList();
    } else if (_filtreConsultations == "À venir") {
      rdvsFiltres = allRdvs.where((r) => r.dateHeure.isAfter(DateTime.now())).toList();
    } else if (_filtreConsultations == "Terminés") {
      rdvsFiltres = allRdvs.where((r) => r.statut == 'TERMINE').toList();
    } else {
      rdvsFiltres = allRdvs;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 18),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            const Text(
              "Mon Agenda Médical",
              style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              user?.fullName.isNotEmpty == true ? "Dr. ${user!.fullName}" : "Espace Praticien Diam-Yaraam",
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Ouvrir une plage horaire",
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFE7F2F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Color(0xFF0D7C66), size: 20),
            ),
            onPressed: _ouvrirModalPlageHoraire,
          ),
          IconButton(
            tooltip: "Actualiser",
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0D7C66)),
            onPressed: _rafraichirDonnees,
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0D7C66),
          indicatorWeight: 3,
          labelColor: const Color(0xFF0D7C66),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.assignment_ind_outlined, size: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Consultations"),
                  if (allRdvs.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D7C66),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${allRdvs.length}",
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              icon: const Icon(Icons.calendar_month_outlined, size: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Mon Planning (1h)"),
                  if (creneauxDuJour.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F2F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${creneauxDuJour.length}",
                        style: const TextStyle(color: Color(0xFF0D7C66), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF0D7C66),
          onRefresh: _rafraichirDonnees,
          child: Column(
            children: [
              // ── SÉLECTEUR DE JOUR INTERACTIF (COMMUN) ──
              _buildModernCalendarHeader(allRdvs),

              // ── CONTENU DES DEUX ONGLETS ──
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ONGLET 1 : RENDEZ-VOUS & CONSULTATIONS PATIENTS
                    _buildConsultationsTab(rdvsFiltres),

                    // ONGLET 2 : DISPONIBILITÉS & GESTION DES CRÉNEAUX D'1H
                    _buildPlanningTab(creneauxDuJour, creneauxDispos, visiosDuJour, rdvsDuJour.length),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ouvrirModalPlageHoraire,
        backgroundColor: const Color(0xFF0D7C66),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.more_time_rounded),
        label: const Text("Ouvrir Plage (1h)", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // =========================================================================
  // COMPOSANTS GRAPHIQUES : CALENDRIER & KPI
  // =========================================================================

  Widget _buildModernCalendarHeader(List<RendezVousModel> allRdvs) {
    final nomMois = DateFormat('MMMM yyyy', 'fr_FR').format(_dateSelectionnee).toUpperCase();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF0D7C66)),
                  const SizedBox(width: 8),
                  Text(
                    nomMois,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _dateSelectionnee = DateTime.now();
                        _calculerSemaine();
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      backgroundColor: const Color(0xFFE7F2F0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.today_rounded, size: 14, color: Color(0xFF0D7C66)),
                    label: const Text(
                      "Aujourd'hui",
                      style: TextStyle(fontSize: 12, color: Color(0xFF0D7C66), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateSelectionnee,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 180)),
                      );
                      if (picked != null) {
                        setState(() {
                          _dateSelectionnee = picked;
                          _calculerSemaine();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ligne des 7 jours de la semaine
          SizedBox(
            height: 68,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _joursSemaine.length,
              itemBuilder: (context, index) {
                final jour = _joursSemaine[index];
                final estSelectionne = _memeJour(jour, _dateSelectionnee);
                final estAujourdhui = _memeJour(jour, DateTime.now());
                final nomJour = DateFormat('EEE', 'fr_FR').format(jour).toUpperCase();
                final numJour = DateFormat('d').format(jour);

                // Vérifier s'il y a des rendez-vous ce jour
                final nbRdvCeJour = allRdvs.where((r) => _memeJour(r.dateHeure, jour)).length;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _dateSelectionnee = jour;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 52,
                      decoration: BoxDecoration(
                        color: estSelectionne
                            ? const Color(0xFF0D7C66)
                            : (estAujourdhui ? const Color(0xFFE7F2F0) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: estSelectionne
                              ? const Color(0xFF0D7C66)
                              : (estAujourdhui ? const Color(0xFFC3DED9) : const Color(0xFFE2E8F0)),
                          width: estSelectionne ? 2 : 1,
                        ),
                        boxShadow: estSelectionne
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0D7C66).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            nomJour,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: estSelectionne
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : (estAujourdhui ? const Color(0xFF0D7C66) : const Color(0xFF94A3B8)),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            numJour,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: estSelectionne
                                  ? Colors.white
                                  : (estAujourdhui ? const Color(0xFF0D7C66) : const Color(0xFF1E293B)),
                            ),
                          ),
                          if (nbRdvCeJour > 0) ...[
                            const SizedBox(height: 2),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: estSelectionne ? Colors.white : const Color(0xFF0D7C66),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // VUE 1 : RENDEZ-VOUS & CONSULTATIONS PATIENTS (DURÉE 1H)
  // =========================================================================

  Widget _buildConsultationsTab(List<RendezVousModel> rdvsFiltres) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FILTRES RAPIDES
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["Tous", "Aujourd'hui", "À venir", "Terminés"].map((filtre) {
                final estActif = _filtreConsultations == filtre;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filtre),
                    selected: estActif,
                    onSelected: (val) => setState(() => _filtreConsultations = filtre),
                    selectedColor: const Color(0xFF0D7C66),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: estActif ? Colors.white : const Color(0xFF475569),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: estActif ? const Color(0xFF0D7C66) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // TITRE DE LA LISTE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Consultations (${rdvsFiltres.length})",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Text(
                DateFormat('d MMMM yyyy', 'fr_FR').format(_dateSelectionnee),
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (rdvsFiltres.isEmpty)
            _buildEmptyStateCard(
              icon: Icons.event_available_rounded,
              title: "Aucune consultation trouvée",
              subtitle: "Vous n'avez pas de rendez-vous pour ce filtre. Vous pouvez ouvrir des plages horaires de 1h dans l'onglet « Mon Planning ».",
              buttonLabel: "Ouvrir des plages horaires (1h)",
              onButtonPressed: () => _tabController.animateTo(1),
            )
          else
            ...rdvsFiltres.map((rdv) => _buildConsultationCard(rdv)),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildConsultationCard(RendezVousModel rdv) {
    final heureStr = DateFormat('HH:mm').format(rdv.dateHeure);
    // Consultation par tranche d'1 heure
    final heureFinStr = DateFormat('HH:mm').format(rdv.dateHeure.add(const Duration(hours: 1)));
    final dateStr = DateFormat('EEE d MMM', 'fr_FR').format(rdv.dateHeure);

    // Extraction du nom du patient et éventuel bénéficiaire
    String nomAffiche = rdv.patientNom?.trim().isNotEmpty == true
        ? rdv.patientNom!
        : "Patient Diam-Yaraam";
    String? mentionBeneficiaire;

    if (rdv.motif.contains("[Bénéficiaire :")) {
      final startIndex = rdv.motif.indexOf("[Bénéficiaire :");
      final endIndex = rdv.motif.indexOf("]", startIndex);
      if (endIndex != -1) {
        mentionBeneficiaire = rdv.motif.substring(startIndex + 1, endIndex);
      }
    }

    final initiales = nomAffiche.length >= 2
        ? nomAffiche.substring(0, 2).toUpperCase()
        : "PT";

    final estAujourdhui = _memeJour(rdv.dateHeure, DateTime.now());
    final estConfirme = rdv.statut == 'CONFIRME';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: estAujourdhui ? const Color(0xFFC3DED9) : const Color(0xFFE2E8F0),
          width: estAujourdhui ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LIGNE DU HAUT : HORAIRE 1H + BADGE STATUT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: estAujourdhui ? const Color(0xFFE7F2F0) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_filled_rounded,
                        size: 14,
                        color: estAujourdhui ? const Color(0xFF0D7C66) : const Color(0xFF475569),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$heureStr - $heureFinStr ($dateStr)",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: estAujourdhui ? const Color(0xFF0D7C66) : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: estConfirme ? const Color(0xFFE7F2F0) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        estConfirme ? Icons.check_circle_rounded : Icons.pending_rounded,
                        size: 13,
                        color: estConfirme ? const Color(0xFF0D7C66) : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        estConfirme ? "Confirmé" : "En attente",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: estConfirme ? const Color(0xFF0D7C66) : const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // INFORMATIONS PATIENT
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F2F0),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFC3DED9), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initiales,
                    style: const TextStyle(
                      color: Color(0xFF0D7C66),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nomAffiche,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      if (mentionBeneficiaire != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.people_outline_rounded, size: 13, color: Color(0xFF0D7C66)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                mentionBeneficiaire,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF0D7C66), fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.videocam_rounded, size: 12, color: Color(0xFF2563EB)),
                                SizedBox(width: 4),
                                Text(
                                  "Téléconsultation (1h)",
                                  style: TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // MOTIF DE LA CONSULTATION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medical_information_outlined, size: 16, color: Color(0xFF0D7C66)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rdv.motif.isNotEmpty ? rdv.motif : "Consultation médicale de suivi (1 heure)",
                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // BOUTONS D'ACTION RAPIDE (EXPERIENCE UTILISATEUR OPTIMALE)
            Row(
              children: [
                // BOUTON 1 : LANCER LA TÉLÉCONSULTATION
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/teleconsultation-room', extra: rdv);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D7C66),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.videocam_rounded, size: 18),
                    label: const Text(
                      "Rejoindre Visio",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // BOUTON 2 : DOSSIER MÉDICAL
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/dossier-medical', extra: {
                        'id': rdv.patientId,
                        'nom': nomAffiche,
                        'isSelf': false,
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E293B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.folder_shared_outlined, size: 16),
                    label: const Text("Dossier", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),

                // BOUTON 3 : ORDONNANCE
                InkWell(
                  onTap: () {
                    context.push('/smart-prescription', extra: {
                      'patientId': rdv.patientId,
                      'patientNom': nomAffiche,
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F2F0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC3DED9)),
                    ),
                    child: const Icon(Icons.note_alt_outlined, size: 18, color: Color(0xFF0D7C66)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // VUE 2 : PLANNING & GESTION DES CRÉNEAUX DE DISPONIBILITÉS (DÉCOUPÉS PAR 1H)
  // =========================================================================

  Widget _buildPlanningTab(
    List<CreneauModel> creneauxDuJour,
    int creneauxDispos,
    int visiosDuJour,
    int totalRdvs,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI CARDS EN HAUT ──
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  titre: "RDV Prévus",
                  valeur: "$totalRdvs",
                  icone: Icons.assignment_outlined,
                  color: const Color(0xFF0D7C66),
                  bgColor: const Color(0xFFE7F2F0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  titre: "En Visio",
                  valeur: "$visiosDuJour",
                  icone: Icons.videocam_outlined,
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildKpiCard(
                  titre: "Dispos (1h)",
                  valeur: "$creneauxDispos",
                  icone: Icons.access_time_rounded,
                  color: const Color(0xFF0D7C66),
                  bgColor: const Color(0xFFE7F2F0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── ACTIONS RAPIDES PAR TRANCHES DE 1 HEURE ──
          const Text(
            "Ouverture Rapide par Plages de 1h",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _ouvrirMatinneeRapide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D7C66),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.wb_sunny_rounded, size: 15),
                  label: const Text("Matin (8h-13h)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _ouvrirApresMidiRapide,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D7C66),
                    side: const BorderSide(color: Color(0xFF0D7C66), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.wb_twilight_rounded, size: 15),
                  label: const Text("A-M (14h-18h)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _ouvrirSoireeRapide,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D7C66),
                    side: const BorderSide(color: Color(0xFF0D7C66), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.nights_stay_rounded, size: 15),
                  label: const Text("Soir (18h-22h)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ── LISTE CHRONOLOGIQUE DES CRÉNEAUX D'1H ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Créneaux d'1h du ${DateFormat('d MMMM', 'fr_FR').format(_dateSelectionnee)}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F2F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${creneauxDuJour.length} créneau(x) d'1h",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D7C66)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (creneauxDuJour.isEmpty)
            _buildEmptyStateCard(
              icon: Icons.alarm_off_rounded,
              title: "Aucun créneau ouvert",
              subtitle: "Définissez une plage horaire (ex: 12h à 16h) pour la découper automatiquement par tranches de 1h.",
              buttonLabel: "Ouvrir une plage (ex: 12h-16h)",
              onButtonPressed: _ouvrirModalPlageHoraire,
            )
          else
            ...creneauxDuJour.map((creneau) => _buildSlotCard(creneau)),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String titre,
    required String valeur,
    required IconData icone,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            valeur,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 2),
          Text(
            titre,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(CreneauModel creneau) {
    final heureDebutStr = DateFormat('HH:mm').format(creneau.dateHeureDebut);
    final heureFinStr = DateFormat('HH:mm').format(creneau.dateHeureFin);

    final estDispo = creneau.statut == 'DISPONIBLE';
    final estReserve = creneau.statut == 'RESERVE';

    final Color badgeBg;
    final Color badgeText;
    final String labelStatut;
    final IconData iconStatut;

    if (estDispo) {
      badgeBg = const Color(0xFFE7F2F0);
      badgeText = const Color(0xFF0D7C66);
      labelStatut = "Disponible";
      iconStatut = Icons.check_circle_outline_rounded;
    } else if (estReserve) {
      badgeBg = const Color(0xFFEFF6FF);
      badgeText = const Color(0xFF2563EB);
      labelStatut = "Réservé";
      iconStatut = Icons.person_rounded;
    } else {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFFD97706);
      labelStatut = "Bloqué";
      iconStatut = Icons.lock_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: () => _gererCreneau(creneau),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(iconStatut, color: badgeText, size: 20),
        ),
        title: Text(
          "$heureDebutStr - $heureFinStr",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
        ),
        subtitle: const Row(
          children: [
            Icon(Icons.videocam_rounded, size: 12, color: Color(0xFF64748B)),
            SizedBox(width: 4),
            Text("Téléconsultation • 1h (Tarif horaire)", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            labelStatut,
            style: TextStyle(color: badgeText, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onButtonPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFE7F2F0),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0D7C66), size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onButtonPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D7C66),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
