import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../medecin/providers/medecin_provider.dart';

class EcranTableauDeBord extends ConsumerStatefulWidget {
  const EcranTableauDeBord({super.key});

  @override
  ConsumerState<EcranTableauDeBord> createState() => _EcranTableauDeBordState();
}

class _EcranTableauDeBordState extends ConsumerState<EcranTableauDeBord> {
  int _indexNavigationActuelle = 0;
  final _controleurRecherche = TextEditingController();

  @override
  void dispose() {
    _controleurRecherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        // EN-TETE AVEC PROFIL PATIENT ET ACCES AGENDA
                        Row(
                          children: [
                            Builder(builder: (context) {
                              final fullName =
                                  ref.watch(authProvider).user?.fullName ?? '';
                              final initials = fullName
                                  .trim()
                                  .split(' ')
                                  .where((p) => p.isNotEmpty)
                                  .take(2)
                                  .map((p) => p[0].toUpperCase())
                                  .join();
                              return Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D7C66),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    initials.isNotEmpty ? initials : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ref.watch(authProvider).user?.fullName ?? "Utilisateur",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                  Text(
                                    "Trouvez votre médecin idéal ici",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8E95A5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => context.push('/agenda-medecin'),
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
                                  Icons.calendar_month_outlined,
                                  color: Color(0xFF0D7C66),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // BARRE DE RECHERCHE
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
                            onSubmitted: (valeur) => context.push('/liste-medecins'),
                            decoration: const InputDecoration(
                              hintText: "Rechercher un médecin, une spécialité...",
                              hintStyle: TextStyle(color: Color(0xFFB4B9C5), fontSize: 13),
                              suffixIcon: Icon(Icons.search, color: Color(0xFF5A607F)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          "Spécialités",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A607F),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Consumer(builder: (context, ref, _) {
                          final specialites =
                              ref.watch(medecinProvider).specialites;
                          if (specialites.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return SizedBox(
                            height: 140,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: specialites.length,
                              itemBuilder: (context, index) {
                                final spec = specialites[index];
                                final couleurs = [
                                  const Color(0xFF0D7C66),
                                  const Color(0xFF5B67F7),
                                  const Color(0xFFFFA06D),
                                  const Color(0xFFB57CFF),
                                  const Color(0xFF0D7C66),
                                  const Color(0xFFEF4444),
                                  const Color(0xFF0D7C66),
                                ];
                                final couleur =
                                    couleurs[index % couleurs.length];
                                return Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: couleur,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: couleur.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      ref
                                          .read(medecinProvider.notifier)
                                          .searchMedecins(
                                              specialite: spec.nom);
                                      context.push('/liste-medecins');
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.local_hospital_outlined,
                                            color: Colors.white,
                                            size: 34,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            spec.nom,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Médecins renommés",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5A607F),
                              ),
                            ),
                            InkWell(
                              onTap: () => context.push('/liste-medecins'),
                              child: const Text(
                                "Voir tout",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF8E95A5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        ref.watch(medecinProvider).isLoading
                            ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                            : ref.watch(medecinProvider).medecins.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Text("Aucun médecin disponible", style: TextStyle(color: Color(0xFF8E95A5))),
                                  )
                                : SizedBox(
                                    height: 190,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: ref.watch(medecinProvider).medecins.length,
                                      itemBuilder: (context, index) {
                                        final medecin = ref.watch(medecinProvider).medecins[index];

                                        return Container(
                                          width: 130,
                                          margin: const EdgeInsets.only(right: 14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: const Color(0xFFE5E9F2)),
                                          ),
                                          child: InkWell(
                                            onTap: () => context.push('/detail-medecin', extra: medecin),
                                            borderRadius: BorderRadius.circular(20),
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    width: 110,
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFE7F2F0),
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                    child: const Icon(Icons.person, color: Color(0xFF0D7C66), size: 40),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    "Dr. ${medecin.prenom} ${medecin.nom}".trim(),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF2D3142),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    medecin.specialite,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF8E95A5),
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

                // BARRE DE NAVIGATION EN BAS
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildElementNavigation(0, Icons.home_outlined, estPrincipal: true),
                      _buildElementNavigation(1, Icons.notifications_none_outlined),
                      _buildElementNavigation(2, Icons.search_outlined),
                      _buildElementNavigation(3, Icons.assignment_outlined),
                      _buildElementNavigation(4, Icons.account_balance_wallet_outlined),
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

  Widget _buildElementNavigation(int index, IconData icone, {bool estPrincipal = false}) {
    final estSelectionne = _indexNavigationActuelle == index;

    if (estPrincipal && estSelectionne) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D7C66).withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.home_filled,
          color: Color(0xFF0D7C66),
          size: 24,
        ),
      );
    }

    return InkWell(
      onTap: () {
        setState(() => _indexNavigationActuelle = index);
        if (index == 2) context.push('/liste-medecins');
        if (index == 3) context.push('/dossier-medical');
        if (index == 4) context.push('/portefeuille');
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icone,
          color: estSelectionne ? const Color(0xFF0D7C66) : const Color(0xFF8E95A5),
          size: 24,
        ),
      ),
    );
  }
}
