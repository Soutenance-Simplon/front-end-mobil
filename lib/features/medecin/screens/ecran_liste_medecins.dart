import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/medecin_provider.dart';
import '../services/medecin_api_service.dart';

class EcranListeMedecins extends ConsumerStatefulWidget {
  final Map<String, dynamic>? beneficiaire;
  const EcranListeMedecins({super.key, this.beneficiaire});

  @override
  ConsumerState<EcranListeMedecins> createState() => _EcranListeMedecinsState();
}

class _EcranListeMedecinsState extends ConsumerState<EcranListeMedecins> {
  final _controleurRecherche = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controleurRecherche.addListener(() {
      setState(() {});
      ref.read(medecinProvider.notifier).searchMedecins(query: _controleurRecherche.text.trim());
    });
  }

  @override
  void dispose() {
    _controleurRecherche.dispose();
    super.dispose();
  }

  String _normaliser(String? s) {
    if (s == null) return '';
    var str = s.toLowerCase();
    const map = {
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a',
      'î': 'i', 'ï': 'i', 'ì': 'i', 'í': 'i',
      'ô': 'o', 'ö': 'o', 'ò': 'o', 'ó': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'ñ': 'n'
    };
    map.forEach((k, v) => str = str.replaceAll(k, v));
    return str.trim();
  }

  @override
  Widget build(BuildContext context) {
    final medecinState = ref.watch(medecinProvider);
    final medecins = medecinState.medecins;
    final specialites = medecinState.specialites;
    final selectedSpecialite = medecinState.selectedSpecialite;

    // Liste complète des spécialités (depuis l'API ou fallback complet)
    final listeSpecialites = specialites.isNotEmpty
        ? specialites
        : MedecinApiService.defaultSpecialites;

    final estTous = selectedSpecialite == null || selectedSpecialite.trim().isEmpty;
    final query = _normaliser(_controleurRecherche.text);
    final selectedSpecNorm = estTous ? '' : _normaliser(selectedSpecialite);

    // Filtrage réactif des médecins (spécialité sélectionnée + texte de recherche)
    final medecinsAffiches = medecins.where((m) {
      if (query.isNotEmpty) {
        final matchNom = _normaliser(m.nomComplet).contains(query);
        final matchSpec = _normaliser(m.specialite).contains(query);
        final matchEtab = _normaliser(m.adresse).contains(query);
        final matchRegion = _normaliser(m.region).contains(query);
        final matchOnms = _normaliser(m.onmsReference?.numeroOrdre).contains(query);
        if (!matchNom && !matchSpec && !matchEtab && !matchRegion && !matchOnms) {
          return false;
        }
      }
      if (selectedSpecNorm.isNotEmpty) {
        final ms = _normaliser(m.specialite);
        if (!ms.contains(selectedSpecNorm) && !selectedSpecNorm.contains(ms)) {
          return false;
        }
      }
      return true;
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
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controleurRecherche,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF2D3142)),
                    decoration: const InputDecoration(
                      hintText: "Rechercher par nom, spécialité, ONMS...",
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
                    physics: const BouncingScrollPhysics(),
                    itemCount: listeSpecialites.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            onTap: () => ref.read(medecinProvider.notifier).searchMedecins(specialite: ''),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: estTous ? const Color(0xFF0D7C66) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: estTous ? const Color(0xFF0D7C66) : const Color(0xFFE5E9F2),
                                ),
                              ),
                              child: Text(
                                "Tous",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: estTous ? Colors.white : const Color(0xFF6C7386),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final spec = listeSpecialites[index - 1];
                      final specNorm = _normaliser(spec.nom);
                      final estSelectionnee = !estTous && (
                          selectedSpecialite == spec.nom ||
                          selectedSpecNorm == specNorm ||
                          selectedSpecNorm.contains(specNorm) ||
                          specNorm.contains(selectedSpecNorm)
                      );

                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: InkWell(
                          onTap: () {
                            if (estSelectionnee) {
                              ref.read(medecinProvider.notifier).searchMedecins(specialite: '');
                            } else {
                              ref.read(medecinProvider.notifier).searchMedecins(specialite: spec.nom);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: estSelectionnee ? const Color(0xFF0D7C66) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: estSelectionnee ? const Color(0xFF0D7C66) : const Color(0xFFE5E9F2),
                              ),
                            ),
                            child: Text(
                              spec.nom,
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
                  child: medecinState.isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D7C66)))
                      : medecinsAffiches.isEmpty
                          ? const Center(
                              child: Text(
                                "Aucun médecin trouvé.",
                                style: TextStyle(color: Color(0xFF8E95A5), fontSize: 14),
                              ),
                            )
                          : ListView.builder(
                              itemCount: medecinsAffiches.length,
                              itemBuilder: (context, index) {
                                final medecin = medecinsAffiches[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFE5E9F2)),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      final medecinData = {
                                        ...medecin.toJson(),
                                        'beneficiaire': widget.beneficiaire,
                                        'beneficiaireId': widget.beneficiaire?['id'],
                                      };
                                      context.push('/doctor-detail', extra: medecinData);
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Container(
                                              width: 76,
                                              height: 76,
                                              color: const Color(0xFFE7F2F0),
                                              child: const Icon(
                                                Icons.person,
                                                color: Color(0xFF0D7C66),
                                                size: 38,
                                              ),
                                            ),
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
                                                        medecin.nomComplet,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF2D3142),
                                                        ),
                                                      ),
                                                    ),
                                                    if (medecin.isVerified)
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
                                                Row(
                                                  children: [
                                                    const Icon(Icons.star, color: Colors.amber, size: 15),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      "${medecin.note} (${medecin.nombreAvis} Avis)",
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Color(0xFF8E95A5),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "${medecin.specialite} • ${medecin.region ?? 'Sénégal'}",
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
