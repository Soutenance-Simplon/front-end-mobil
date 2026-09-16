import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/ia_provider.dart';
import '../../dossier/providers/dossier_provider.dart';
import '../../patient/services/patient_api_service.dart';
import '../../../core/network/api_client.dart';
import '../../medecin/services/medecin_api_service.dart';
import '../../medecin/models/medecin_model.dart';

class EcranAssistantIa extends ConsumerStatefulWidget {
  const EcranAssistantIa({super.key});

  @override
  ConsumerState<EcranAssistantIa> createState() => _EcranAssistantIaState();
}

class _EcranAssistantIaState extends ConsumerState<EcranAssistantIa> {
  final TextEditingController _controleurMessage = TextEditingController();
  final ScrollController _controleurScroll = ScrollController();

  final List<String> _suggestionsRapides = [
    "J'ai de la fièvre et des maux de tête",
    "Douleur aiguë dans la poitrine",
    "Vérifier interaction Paracétamol + Ibuprofène",
    "Conseil pour tension élevée",
  ];

  @override
  void initState() {
    super.initState();
    _initContexte();
  }

  Future<void> _initContexte() async {
    // Obtenir le dossier médical actif
    final dossier = ref.read(dossierProvider).dossier;
    
    // Obtenir les membres de la famille
    List<dynamic> famille = [];
    try {
      final patientId = await ApiClient().getUserId();
      if (patientId != null && patientId.isNotEmpty) {
        final membres = await PatientApiService().getMembresFamille(patientId);
        famille = membres.map((m) => m.toJson()).toList();
      }
    } catch (e) {
      // Ignore
    }

    // Initialiser le contexte dans le provider IA
    await ref.read(iaProvider.notifier).initialiserContextePatient(dossier?.toJson(), famille);
  }

  void _faireDefilerEnBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controleurScroll.hasClients) {
        _controleurScroll.animateTo(
          _controleurScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _envoyerMessage(String texte) {
    if (texte.trim().isEmpty) return;
    _controleurMessage.clear();
    ref.read(iaProvider.notifier).envoyerMessage(texte);
    _faireDefilerEnBas();
  }

  Widget _buildSpecialistsList(String specialite) {
    return FutureBuilder<List<MedecinModel>>(
      future: MedecinApiService().searchMedecins(specialite: specialite),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A884))),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text("Aucun spécialiste de cette spécialité n'est disponible actuellement.", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF8E95A5)));
        }
        
        final docs = snapshot.data!.take(3).toList();
        return Column(
          children: docs.map((doc) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E9F2)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF00A884).withValues(alpha: 0.15),
                  child: const Icon(Icons.person_outline, color: Color(0xFF00A884), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.nomComplet, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3142)), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(doc.specialite.isNotEmpty ? doc.specialite : specialite, style: const TextStyle(fontSize: 11, color: Color(0xFF8E95A5))),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.push('/doctors'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A884),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text("Voir créneaux", style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final iaState = ref.watch(iaProvider);
    // Filtrer les messages systèmes (invisibles pour l'utilisateur)
    final messages = iaState.messages.where((m) => !m.contenu.startsWith("CONTEXTE_SYSTEME:")).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2D3142), size: 18),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00A884).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFF00A884), size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Assistant IA Médical",
                  style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Triage & Conseil Diam Yaraam",
                  style: TextStyle(color: Color(0xFF00A884), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF8E95A5)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text("Avertissement Légal & IA"),
                  content: const Text(
                    "L'assistant Diam Yaraam est une aide au triage préliminaire basée sur des protocoles médicaux validés. "
                    "Il ne remplace pas l'avis ou le diagnostic d'un médecin agréé ONMS. En cas d'urgence absolue, composez le 1515 (SAMU).",
                    style: TextStyle(fontSize: 13, color: Color(0xFF5A607F)),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Compris")),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Column(
              children: [
                // Suggestions rapides sous l'AppBar
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  color: Colors.white,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _suggestionsRapides.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestionsRapides[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          label: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                          ),
                          onPressed: () => _envoyerMessage(suggestion),
                        ),
                      );
                    },
                  ),
                ),

                // Liste des messages
                Expanded(
                  child: ListView.builder(
                    controller: _controleurScroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (iaState.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && iaState.isLoading) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFE5E9F2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A884)),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Diam Yaraam réfléchit...",
                                  style: TextStyle(fontSize: 13, color: Color(0xFF8E95A5), fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final msg = messages[index];
                      final estUser = msg.estUtilisateur;

                      return Align(
                        alignment: estUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: estUser ? const Color(0xFF00A884) : Colors.white,
                            borderRadius: BorderRadius.circular(20).copyWith(
                              bottomRight: estUser ? const Radius.circular(4) : const Radius.circular(20),
                              bottomLeft: !estUser ? const Radius.circular(4) : const Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: estUser ? null : Border.all(color: const Color(0xFFE5E9F2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.contenu,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: estUser ? Colors.white : const Color(0xFF2D3142),
                                ),
                              ),
                              if (msg.recommandations != null && msg.recommandations!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 8),
                                const Text(
                                  "Actions recommandées :",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00A884)),
                                ),
                                const SizedBox(height: 6),
                                ...msg.recommandations!.map((rec) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("• ", style: TextStyle(color: Color(0xFF00A884), fontWeight: FontWeight.bold)),
                                          Expanded(
                                            child: Text(rec, style: const TextStyle(fontSize: 12, color: Color(0xFF5A607F))),
                                          ),
                                        ],
                                      ),
                                    )),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => context.push('/doctors'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00A884),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: const Text(
                                      "Voir les spécialistes disponibles",
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                              
                              if (msg.specialitesSuggerees != null && msg.specialitesSuggerees!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.medical_services_outlined, color: Color(0xFF00A884), size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        "Spécialistes suggérés : ${msg.specialitesSuggerees!.first}",
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00A884)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildSpecialistsList(msg.specialitesSuggerees!.first),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Zone de saisie
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controleurMessage,
                          decoration: InputDecoration(
                            hintText: "Décrivez vos symptômes ou posez une question...",
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF8E95A5)),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: Color(0xFFE5E9F2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: Color(0xFFE5E9F2)),
                            ),
                          ),
                          onSubmitted: _envoyerMessage,
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => _envoyerMessage(_controleurMessage.text),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00A884),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
