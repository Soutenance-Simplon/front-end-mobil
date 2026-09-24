import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../medecin/providers/medecin_provider.dart';

class EcranListeMedecins extends ConsumerStatefulWidget {
  final Map<String, dynamic>? beneficiaire;
  const EcranListeMedecins({super.key, this.beneficiaire});

  @override
  ConsumerState<EcranListeMedecins> createState() => _EcranListeMedecinsState();
}

class _EcranListeMedecinsState extends ConsumerState<EcranListeMedecins> {
  String _categorieSelectionnee = "Tous";
  final _controleurRecherche = TextEditingController();
  String _rechercheTexte = "";

  final List<String> _listeCategories = [
    "Tous",
    "Cardiologie",
    "Pédiatrie",
    "Dentiste",
    "Gynécologie",
    "Médecine Générale",
  ];

  @override
  Widget build(BuildContext context) {
    final medecinState = ref.watch(medecinProvider);
    final medecinsFiltres = medecinState.medecins.where((medecin) {
      final correspondCategorie = _categorieSelectionnee == "Tous" || medecin.specialite.toLowerCase().contains(_categorieSelectionnee.toLowerCase());
      final correspondRecherche = _rechercheTexte.isEmpty ||
          "${medecin.prenom} ${medecin.nom}".toLowerCase().contains(_rechercheTexte) ||
          medecin.specialite.toLowerCase().contains(_rechercheTexte);

      return correspondCategorie && correspondRecherche;
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
                        "Annuaire des Médecins",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A607F),
                        ),
                      ),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),

                if (widget.beneficiaire != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F2F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF0D7C66).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.family_restroom, color: Color(0xFF0D7C66), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Pour : ${widget.beneficiaire!['nom'] ?? 'Proche'}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D7C66)),
                              ),
                              Text(
                                "Lien : ${widget.beneficiaire!['lienParente'] ?? 'Membre de la famille'}",
                                style: const TextStyle(fontSize: 11, color: Color(0xFF5A607F)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controleurRecherche,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142)),
                    decoration: const InputDecoration(
                      hintText: "Rechercher par nom, spécialité...",
                      hintStyle: TextStyle(color: Color(0xFFB4B9C5), fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF9EA5B4)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _listeCategories.length,
                    itemBuilder: (context, index) {
                      final categorie = _listeCategories[index];
                      final estSelectionnee = _categorieSelectionnee == categorie;

                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: InkWell(
                          onTap: () => setState(() => _categorieSelectionnee = categorie),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: estSelectionnee ? const Color(0xFF0D7C66) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: estSelectionnee ? const Color(0xFF0D7C66) : const Color(0xFFE5E9F2),
                              ),
                            ),
                            child: Text(
                              categorie,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: estSelectionnee ? Colors.white : const Color(0xFF6C7386),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: medecinsFiltres.isEmpty
                      ? const Center(
                          child: Text(
                            "Aucun médecin trouvé.",
                            style: TextStyle(color: Color(0xFF8E95A5), fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          itemCount: medecinsFiltres.length,
                          itemBuilder: (context, index) {
                            final medecin = medecinsFiltres[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE5E9F2)),
                              ),
                              child: InkWell(
                                onTap: () {
                                  final medecinMap = {
                                    'id': medecin.id,
                                    'nom': medecin.nom,
                                    'prenom': medecin.prenom,
                                    'specialite': medecin.specialite,
                                    'ville': medecin.ville,
                                    'tarifConsultation': medecin.tarifConsultation,
                                    'beneficiaire': widget.beneficiaire,
                                    'beneficiaireId': widget.beneficiaire?['id'],
                                  };
                                  context.push('/book-appointment', extra: medecinMap);
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 76,
                                        height: 76,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE7F2F0),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(Icons.person, color: Color(0xFF0D7C66), size: 38),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    "Dr. ${medecin.prenom} ${medecin.nom}".trim(),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF2D3142),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFE7F2F0),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    "ONMS Certifié",
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF0D7C66),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${medecin.specialite} - ${medecin.ville}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF8E95A5),
                                              ),
                                            ),
                                          ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
