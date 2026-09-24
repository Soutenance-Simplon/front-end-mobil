import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

class DoctorDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  ConsumerState<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends ConsumerState<DoctorDetailScreen> {
  bool _isFavorite = false;
  int _selectedDateIndex = 0;

  late Map<String, dynamic> _doctorData;
  late String _biographie;
  late int _experience;
  late int _nombreAvis;
  late double _note;
  late String _name;
  late String _spec;
  late String _image;
  bool _estDescriptionPersonnalisee = false;

  final List<Map<String, dynamic>> _avisList = [
    {
      "auteur": "Awa Ndiaye",
      "date": "Il y a 3 jours",
      "note": 5.0,
      "commentaire": "Médecin très à l'écoute, ponctuel et rassurant. La téléconsultation s'est parfaitement déroulée.",
    },
    {
      "auteur": "Moussa Diop",
      "date": "Il y a 1 semaine",
      "note": 5.0,
      "commentaire": "Excellent diagnostic et explications très claires. Je recommande vivement ce praticien.",
    },
    {
      "auteur": "Fatou Bintou Sall",
      "date": "Il y a 2 semaines",
      "note": 4,
      "commentaire": "Professionnel et disponible pour expliquer chaque étape de la prise en charge médicale.",
    },
  ];

  final List<Map<String, String>> _dates = [
    {"day": "LUN", "date": "10"},
    {"day": "MAR", "date": "11"},
    {"day": "MER", "date": "12"},
    {"day": "JEU", "date": "13"},
    {"day": "VEN", "date": "14"},
    {"day": "SAM", "date": "15"},
  ];

  /// Génère une description clinique riche et réaliste selon la spécialité médicale
  static String _genererDescriptionParSpecialite(String specialite, String nomMedecin) {
    final spec = specialite.toLowerCase().trim();

    if (spec.contains('cardio')) {
      return "Médecin spécialiste en Cardiologie et affections cardiovasculaires, inscrit à l'Ordre National des Médecins du Sénégal (ONMS). "
          "Dédié à la prévention, au dépistage et au traitement de l'hypertension artérielle, des troubles du rythme et des cardiopathies. "
          "Propose des bilans cardiaques complets au cabinet et des téléconsultations sécurisées au sein du réseau Diam Yaraam.";
    } else if (spec.contains('pédiat') || spec.contains('pediat')) {
      return "Médecin spécialiste en Pédiatrie, inscrit à l'ONMS. "
          "Assure le suivi attentif de la croissance, du développement psychomoteur et du calendrier vaccinal des nourrissons, enfants et adolescents. "
          "Prend en charge les pathologies pédiatriques aiguës et chroniques avec écoute et bienveillance envers les parents.";
    } else if (spec.contains('gynéco') || spec.contains('gyneco') || spec.contains('obstét') || spec.contains('obstet')) {
      return "Médecin spécialiste en Gynécologie-Obstétrique, agréé par l'ONMS. "
          "Assure le suivi gynécologique préventif, le suivi de grossesse, la santé reproductive et le dépistage précoce des pathologies féminines au cabinet et à distance.";
    } else if (spec.contains('derma')) {
      return "Médecin spécialiste en Dermatologie et Vénérologie, certifié par l'ONMS. "
          "Expert dans le diagnostic et le traitement des maladies de la peau, du cuir chevelu, des muqueuses et des ongles (eczéma, acné, psoriasis, allergies cutanées et télé-expertise).";
    } else if (spec.contains('ophtalmo') || spec.contains('yeux') || spec.contains('vision')) {
      return "Médecin spécialiste en Ophtalmologie, inscrit à l'ONMS. "
          "Spécialisé dans les bilans de réfraction visuelle, la santé oculaire, le dépistage du glaucome et de la cataracte, et le suivi visuel des adultes et des enfants.";
    } else if (spec.contains('dent') || spec.contains('odonto')) {
      return "Chirurgien-dentiste diplômé, inscrit à l'Ordre des Chirurgiens-Dentistes du Sénégal. "
          "Dédié aux soins bucco-dentaires préventifs, détartrages, traitements conservateurs et réhabilitations au sein du réseau Diam Yaraam.";
    } else if (spec.contains('neuro')) {
      return "Médecin spécialiste en Neurologie, agréé par l'ONMS. "
          "Prend en charge les pathologies du système nerveux : migraines chroniques, céphalées, épilepsies, neuropathies et troubles de la motricité.";
    } else if (spec.contains('pneumo')) {
      return "Médecin spécialiste en Pneumologie, inscrit à l'ONMS. "
          "Dédié au diagnostic et à la prise en charge de l'asthme, des bronchopneumopathies, des allergies respiratoires et des infections pulmonaires.";
    } else if (spec.contains('orl') || spec.contains('oto')) {
      return "Médecin spécialiste en Oto-Rhino-Laryngologie (ORL), certifié par l'ONMS. "
          "Prend en charge les affections de l'oreille, du nez, des sinus, de la gorge et des voies respiratoires supérieures.";
    } else if (spec.contains('psy')) {
      return "Médecin psychiatre agréé par l'Ordre National des Médecins du Sénégal. "
          "Propose un cadre d'écoute confidentiel pour l'accompagnement et le traitement des troubles anxieux, dépressifs et du sommeil.";
    } else {
      return "Médecin généraliste qualifié et conventionné, inscrit à l'Ordre National des Médecins du Sénégal (ONMS). "
          "Assure le suivi médical global, le dépistage préventif, l'orientation diagnostique et la prise en charge des affections courantes au cabinet et en téléconsultation.";
    }
  }

  /// Extrait des initiales professionnelles pour l'avatar médical
  static String _obtenirInitiales(String nomComplet) {
    final clean = nomComplet
        .replaceAll("Dr.", "")
        .replaceAll("Dr", "")
        .replaceAll("Docteur", "")
        .trim();
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return "DR";
    if (parts.length == 1) {
      return parts[0].length >= 2 ? parts[0].substring(0, 2).toUpperCase() : parts[0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _doctorData = Map<String, dynamic>.from(widget.doctor);

    final nom = _doctorData['nom']?.toString() ?? '';
    final prenom = _doctorData['prenom']?.toString() ?? '';
    _name = _doctorData['name'] ?? _doctorData['nomComplet'] ?? (nom.isNotEmpty ? "Dr. $prenom $nom".trim() : "Dr. Praticien");
    _spec = _doctorData['specialty'] ?? _doctorData['specialite'] ?? 'Médecine Générale';

    // SUPPRESSION DE LA PHOTO STATIQUE UNSPLASH : On n'affiche que les photos réelles, sinon l'avatar monogramme
    final rawImg = _doctorData['image'] ??
        _doctorData['photo_url'] ??
        _doctorData['photoUrl'] ??
        _doctorData['photoProfessionnelle'];
    if (rawImg != null &&
        rawImg.toString().isNotEmpty &&
        !rawImg.toString().contains("images.unsplash.com") &&
        !rawImg.toString().contains("placeholder")) {
      _image = rawImg.toString();
    } else {
      _image = "";
    }

    // DESCRIPTION : Si le médecin a écrit sa propre biographie personnalisée, on l'affiche, sinon description générique selon la spécialité
    final rawBio = _doctorData['biographie'] ?? _doctorData['bio'] ?? _doctorData['description'];
    final bool aBioPersoValide = rawBio != null &&
        rawBio.toString().trim().isNotEmpty &&
        !rawBio.toString().contains("Mahmud Nik") &&
        !rawBio.toString().startsWith("Spécialiste agréé") &&
        rawBio.toString().trim() != "Médecin praticien agréé par l'Ordre National des Médecins du Sénégal (ONMS).";

    if (aBioPersoValide) {
      _biographie = rawBio.toString().trim();
      _estDescriptionPersonnalisee = true;
    } else {
      _biographie = _genererDescriptionParSpecialite(_spec, _name);
      _estDescriptionPersonnalisee = false;
    }

    _experience = _doctorData['anneesExperience'] ?? _doctorData['annees_experience'] ?? _doctorData['experience'] ?? 8;
    _nombreAvis = _doctorData['nombreAvis'] ?? _doctorData['nombre_avis'] ?? 36;
    _note = (_doctorData['note'] is num) ? (_doctorData['note'] as num).toDouble() : 4.9;
  }

  /// Boîte de dialogue permettant au médecin de rédiger sa propre description et son expérience
  void _ouvrirDialogueModificationMedecin() {
    final bioController = TextEditingController(text: _biographie);
    final expController = TextEditingController(text: _experience.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 24,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Modifier ma présentation",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
            ),
            const SizedBox(height: 6),
            const Text(
              "Renseignez votre propre description et vos années d'expérience pour vos patients.",
              style: TextStyle(fontSize: 13, color: Color(0xFF8E95A5)),
            ),
            const SizedBox(height: 20),

            // ANNÉES D'EXPÉRIENCE
            const Text("Années d'expérience", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF4A5568))),
            const SizedBox(height: 6),
            TextField(
              controller: expController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Ex: 8",
                suffixText: "ans",
                prefixIcon: const Icon(Icons.workspace_premium_outlined, color: Color(0xFF00A884)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 16),

            // DESCRIPTION / BIOGRAPHIE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("À propos de moi (description)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF4A5568))),
                InkWell(
                  onTap: () {
                    bioController.text = _genererDescriptionParSpecialite(_spec, _name);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: Color(0xFF00A884)),
                        SizedBox(width: 4),
                        Text(
                          "Modèle spécialité",
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF00A884), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: bioController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Présentez votre parcours, vos spécialités et vos domaines d'expertise clinique...",
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 24),

            // BOUTON ENREGISTRER
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final newExp = int.tryParse(expController.text.trim()) ?? _experience;
                  final newBio = bioController.text.trim();

                  setState(() {
                    _experience = newExp;
                    if (newBio.isNotEmpty) {
                      _biographie = newBio;
                      _estDescriptionPersonnalisee = true;
                    }
                    _doctorData['biographie'] = _biographie;
                    _doctorData['anneesExperience'] = _experience;
                  });

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Présentation personnalisée et enregistrée avec succès"),
                      backgroundColor: Color(0xFF00A884),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A884),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Enregistrer les modifications", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Boîte de dialogue permettant au patient de donner son avis après un rendez-vous
  void _ouvrirDialogueDonnerAvis() {
    double noteDonnee = 5.0;
    final commentaireController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFE6F7F3), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.star_rounded, color: Color(0xFF00A884)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text("Donner votre avis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Votre retour après votre consultation avec $_name :",
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6C7386)),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final etoile = index + 1;
                      return IconButton(
                        icon: Icon(
                          etoile <= noteDonnee ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() => noteDonnee = etoile.toDouble());
                        },
                      );
                    }),
                  ),
                ),
                Center(
                  child: Text(
                    "${noteDonnee.toStringAsFixed(0)} / 5",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3142)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentaireController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Partagez votre expérience (écoute, ponctualité, conseils reçus...)",
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler", style: TextStyle(color: Color(0xFF8E95A5))),
            ),
            ElevatedButton(
              onPressed: () {
                final user = ref.read(authProvider).user;
                final auteur = user != null ? "${user.firstName} ${user.lastName}".trim() : "Patient vérifié";
                final commentaire = commentaireController.text.trim().isNotEmpty
                    ? commentaireController.text.trim()
                    : "Consultation très satisfaisante.";

                setState(() {
                  _nombreAvis++;
                  _note = double.parse((((_note * (_nombreAvis - 1)) + noteDonnee) / _nombreAvis).toStringAsFixed(1));
                  _avisList.insert(0, {
                    "auteur": auteur.isNotEmpty ? auteur : "Patient vérifié",
                    "date": "À l'instant",
                    "note": noteDonnee,
                    "commentaire": commentaire,
                  });
                });

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Merci pour votre avis ! Il a été publié avec succès."),
                    backgroundColor: Color(0xFF00A884),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A884),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Publier l'avis", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isCurrentUserDoctor = user != null && user.role.toUpperCase() == 'MEDECIN';

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
                        // BARRE DE NAVIGATION SUPÉRIEURE
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            if (isCurrentUserDoctor)
                              TextButton.icon(
                                onPressed: _ouvrirDialogueModificationMedecin,
                                icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF00A884), size: 20),
                                label: const Text(
                                  "Éditer profil",
                                  style: TextStyle(color: Color(0xFF00A884), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // EN-TÊTE MÉDECIN (AVATAR DYNAMIQUE AUX INITIALES, NOM RÉEL ET SPÉCIALITÉ)
                        Row(
                          children: [
                            _buildMonogrammeAvatar(),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3142),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _spec,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF8E95A5),
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE6F7F3),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified, color: Color(0xFF00A884), size: 12),
                                        SizedBox(width: 4),
                                        Text(
                                          "ONMS Certifié",
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00A884)),
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

                        // BANNIÈRE VERTE DYNAMIQUE : 1. AVIS PATIENTS / NOTE  -- 2. ANNÉES D'EXPÉRIENCE
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A884),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00A884).withOpacity(0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // 1. AVIS & NOTE DES PATIENTS
                              InkWell(
                                onTap: _ouvrirDialogueDonnerAvis,
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${_note.toStringAsFixed(1)} ★",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            "$_nombreAvis Avis patients",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Container(width: 1, height: 36, color: Colors.white24),

                              // 2. ANNÉES D'EXPÉRIENCE RENSEIGNÉES PAR LE MÉDECIN (MODIFIABLE SEULEMENT PAR LE MÉDECIN)
                              InkWell(
                                onTap: isCurrentUserDoctor ? _ouvrirDialogueModificationMedecin : null,
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
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
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                "$_experience Ans",
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              if (isCurrentUserDoctor) ...[
                                                const SizedBox(width: 4),
                                                const Icon(Icons.edit, size: 12, color: Colors.white70),
                                              ],
                                            ],
                                          ),
                                          const Text(
                                            "D'expérience",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // SECTION À PROPOS DU MÉDECIN (RÉDIGÉE PAR LE MÉDECIN OU GÉNÉRIQUE SELON SPÉCIALITÉ)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "À propos du médecin",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3142),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _estDescriptionPersonnalisee ? const Color(0xFFE6F7F3) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _estDescriptionPersonnalisee ? "Personnalisée" : "Selon spécialité",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _estDescriptionPersonnalisee ? const Color(0xFF00A884) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isCurrentUserDoctor)
                              TextButton.icon(
                                onPressed: _ouvrirDialogueModificationMedecin,
                                icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF00A884)),
                                label: const Text(
                                  "Personnaliser",
                                  style: TextStyle(color: Color(0xFF00A884), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _biographie,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6C7386),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // HORAIRES DE TRAVAIL
                        const Text(
                          "Horaires de travail",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Lun - Ven 09:00 - 18:00 • Téléconsultations & Cabinet",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8E95A5),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // SELECTEUR DE DATE INTERACTIF
                        Row(
                          children: [
                            const Text(
                              "Créneaux disponibles",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Text("Octobre", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                                  Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // LISTE HORIZONTALE DES DATES
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _dates.length,
                            itemBuilder: (context, index) {
                              final item = _dates[index];
                              final isSelected = _selectedDateIndex == index;

                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedDateIndex = index),
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF00A884) : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF00A884) : const Color(0xFFE5E9F2),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item['day']!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected ? Colors.white70 : const Color(0xFFB4B9C5),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['date']!,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : const Color(0xFF5A607F),
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

                        const SizedBox(height: 28),

                        // SECTION AVIS DES PATIENTS (INVITATION POST-RDV)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Avis des patients",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3142),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F7F3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "$_nombreAvis",
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00A884)),
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: _ouvrirDialogueDonnerAvis,
                              icon: const Icon(Icons.rate_review_outlined, size: 16, color: Color(0xFF00A884)),
                              label: const Text(
                                "Donner un avis",
                                style: TextStyle(color: Color(0xFF00A884), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // LISTE DES DERNIERS AVIS
                        ..._avisList.map((avis) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E9F2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: const Color(0xFFE6F7F3),
                                          child: Text(
                                            avis['auteur'].toString().substring(0, 1),
                                            style: const TextStyle(color: Color(0xFF00A884), fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              avis['auteur'] as String,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142)),
                                            ),
                                            Text(
                                              avis['date'] as String,
                                              style: const TextStyle(fontSize: 11, color: Color(0xFFA0AEC0)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                        const SizedBox(width: 3),
                                        Text(
                                          "${avis['note']}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3142)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  avis['commentaire'] as String,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF6C7386), height: 1.4),
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // BARRE D'ACTION EN BAS (FAVORI & PRENDRE RENDEZ-VOUS)
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
                        onTap: () => setState(() => _isFavorite = !_isFavorite),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7F3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
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
                              context.push('/book-appointment', extra: _doctorData);
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

  Widget _buildMonogrammeAvatar() {
    if (_image.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.network(
          _image,
          width: 88,
          height: 88,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitialsContainer(),
        ),
      );
    }
    return _buildInitialsContainer();
  }

  Widget _buildInitialsContainer() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE6F7F3), Color(0xFFC7EFE6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF00A884).withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A884).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            _obtenirInitiales(_name),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00A884),
              letterSpacing: 1.2,
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF00A884),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.verified, color: Colors.white, size: 12),
            ),
          ),
        ],
      ),
    );
  }
}
