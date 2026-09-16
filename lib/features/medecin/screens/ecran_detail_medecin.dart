import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../rdv/providers/planning_provider.dart';
import '../models/creneau_model.dart';

class EcranDetailMedecin extends ConsumerStatefulWidget {
  final Map<String, dynamic> medecin;

  const EcranDetailMedecin({super.key, required this.medecin});

  @override
  ConsumerState<EcranDetailMedecin> createState() => _EcranDetailMedecinState();
}

class _EcranDetailMedecinState extends ConsumerState<EcranDetailMedecin> {
  bool _estFavoris = false;
  int _indexDateSelectionnee = 0;
  late List<DateTime> _dates;
  CreneauModel? _creneauSelectionne;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dates = List.generate(14, (index) => now.add(Duration(days: index)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planningProvider.notifier).chargerCreneauxDuMedecin(_medecinId);
    });
  }

  String get _medecinId {
    return widget.medecin['id']?.toString() ??
        widget.medecin['userId']?.toString() ??
        widget.medecin['user_id']?.toString() ??
        "med-1";
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les créneaux en direct
    ref.watch(planningProvider);

    final rawNom = widget.medecin['nom'] ?? widget.medecin['nomComplet'] ?? '';
    final prenom = widget.medecin['prenom'] ?? '';
    final nom = (prenom.isNotEmpty)
        ? "Dr. $prenom $rawNom".trim()
        : (rawNom.toString().startsWith("Dr.") ? rawNom.toString() : "Dr. $rawNom".trim());
    final specialite = widget.medecin['specialite'] ?? 'Médecine Générale';
    final etablissement = widget.medecin['adresse'] ?? widget.medecin['etablissement'] ?? 'Centre Hospitalier';
    final tarif = widget.medecin['tarifConsultation'] ?? widget.medecin['tarif_consultation'] ?? 15000;

    final dateChoisie = _dates[_indexDateSelectionnee];

    // Créneaux STRICTEMENT libres/disponibles pour ce médecin à la date sélectionnée
    final creneauxLibres = ref.read(planningProvider.notifier).getCreneauxDisponibles(
      medecinId: _medecinId,
      date: dateChoisie,
    );

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
                        // BOUTON RETOUR
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

                        // EN-TÊTE MÉDECIN
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 90,
                                height: 90,
                                color: const Color(0xFFE6F7F3),
                                child: const Icon(Icons.person, size: 45, color: Color(0xFF00A884)),
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
                                    "$specialite • $etablissement",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF8E95A5),
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6F7F3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified, color: Color(0xFF00A884), size: 12),
                                        SizedBox(width: 4),
                                        Text(
                                          "Agréé ONMS Sénégal",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF00A884),
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
                        const SizedBox(height: 24),

                        // STATISTIQUES MÉDECIN
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A884),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.people_alt_outlined, color: Colors.white, size: 24),
                                  SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "1 000+",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        "Patients suivis",
                                        style: TextStyle(fontSize: 11, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.star_rounded, color: Colors.amber, size: 26),
                                  SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "4.9",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        "Avis vérifiés",
                                        style: TextStyle(fontSize: 11, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // A PROPOS DU MÉDECIN
                        const Text(
                          "À propos du médecin",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Médecin spécialiste inscrit à l'Ordre National des Médecins du Sénégal (ONMS). "
                          "Consultations en cabinet et téléconsultations sécurisées au tarif de $tarif FCFA.",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E95A5),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // SECTION HORAIRES & DISPONIBILITÉS (CRÉNEAUX LIBRES UNIQUEMENT)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Horaires & Disponibilités",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F7F3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${creneauxLibres.length} créneau(x) libre(s)",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00A884),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Sélectionnez un jour pour voir les créneaux disponibles :",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8E95A5),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // DÉFILEMENT DES JOURS DE LA SEMAINE
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _dates.length,
                            itemBuilder: (context, index) {
                              final date = _dates[index];
                              final estSelectionnee = _indexDateSelectionnee == index;
                              final nomJour = DateFormat('EEE', 'fr_FR').format(date).toUpperCase();
                              final numJour = DateFormat('d').format(date);

                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: InkWell(
                                  onTap: () => setState(() {
                                    _indexDateSelectionnee = index;
                                    _creneauSelectionne = null;
                                  }),
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
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
                                          nomJour,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: estSelectionnee ? Colors.white70 : const Color(0xFFB4B9C5),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          numJour,
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

                        // AFFICHAGE EXCLUSIF DES CRÉNEAUX LIBRES POUR LA DATE CHOISIE
                        if (creneauxLibres.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E9F2)),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.event_busy, color: Color(0xFFEF4444), size: 28),
                                SizedBox(height: 6),
                                Text(
                                  "Aucun créneau libre pour ce jour",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3142)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Tous les créneaux sont occupés ou fermés. Veuillez choisir une autre date.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, color: Color(0xFF8E95A5)),
                                ),
                              ],
                            ),
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: creneauxLibres.map((c) {
                              final heureStr = DateFormat('HH:mm').format(c.dateHeureDebut);
                              final estSelectionne = _creneauSelectionne?.id == c.id;
                              final isVisio = c.typeConsultation == 'TELECONSULTATION';

                              return InkWell(
                                onTap: () => setState(() => _creneauSelectionne = c),
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: estSelectionne ? const Color(0xFF00A884) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: estSelectionne ? const Color(0xFF00A884) : const Color(0xFFE5E9F2),
                                      width: estSelectionne ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isVisio ? Icons.videocam_rounded : Icons.local_hospital_rounded,
                                        size: 16,
                                        color: estSelectionne ? Colors.white : const Color(0xFF00A884),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        heureStr,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: estSelectionne ? Colors.white : const Color(0xFF2D3142),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: estSelectionne ? Colors.white.withOpacity(0.2) : const Color(0xFFE6F7F3),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          "Libre",
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: estSelectionne ? Colors.white : const Color(0xFF00A884),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // BARRE D'ACTION INFÉRIEURE AVEC BOUTON DE PRISE DE RENDEZ-VOUS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE5E9F2))),
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
                              context.push('/book-appointment', extra: {
                                ...widget.medecin,
                                'dateSelectionnee': dateChoisie,
                                'creneauSelectionne': _creneauSelectionne,
                                'periode': _creneauSelectionne != null
                                    ? (_creneauSelectionne!.dateHeureDebut.hour < 13 ? 'Matin' : 'Soir')
                                    : null,
                                'typeConsultation': _creneauSelectionne?.typeConsultation ?? 'TELECONSULTATION',
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A884),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              _creneauSelectionne != null
                                  ? "Prendre RDV à ${DateFormat('HH:mm').format(_creneauSelectionne!.dateHeureDebut)}"
                                  : "Prendre rendez-vous",
                              style: const TextStyle(
                                fontSize: 15,
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
