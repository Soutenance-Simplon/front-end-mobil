class TriSymptomeModel {
  final String descriptionSymptomes;
  final String niveauGravite; // VERT (Bénin), JAUNE (Consultation normale), ORANGE (Rapide), ROUGE (Urgence Vitale)
  final String orientationSuggeree; // EXEMPLE: "Médecine Générale", "Cardiologie", "SAMU 1515"
  final String conseilImmediat;
  final List<String> questionsSuivi;

  TriSymptomeModel({
    required this.descriptionSymptomes,
    required this.niveauGravite,
    required this.orientationSuggeree,
    required this.conseilImmediat,
    this.questionsSuivi = const [],
  });

  factory TriSymptomeModel.fromJson(Map<String, dynamic> json) {
    return TriSymptomeModel(
      descriptionSymptomes: json['description_symptomes'] ?? json['symptoms'] ?? '',
      niveauGravite: json['niveau_gravite'] ?? json['severity'] ?? 'VERT',
      orientationSuggeree: json['orientation_suggeree'] ?? json['recommendation'] ?? 'Médecine Générale',
      conseilImmediat: json['conseil_immediat'] ?? json['advice'] ?? '',
      questionsSuivi: List<String>.from(json['questions_suivi'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description_symptomes': descriptionSymptomes,
      'niveau_gravite': niveauGravite,
      'orientation_suggeree': orientationSuggeree,
      'conseil_immediat': conseilImmediat,
      'questions_suivi': questionsSuivi,
    };
  }
}
