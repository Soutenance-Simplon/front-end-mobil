class MessageIaModel {
  final String id;
  final String contenu;
  final bool estUtilisateur;
  final DateTime timestamp;
  final String? niveauUrgence; // FAIBLE, MODERE, URGENT, SAMU
  final List<String>? recommandations;
  final List<String>? specialitesSuggerees;

  MessageIaModel({
    required this.id,
    required this.contenu,
    required this.estUtilisateur,
    required this.timestamp,
    this.niveauUrgence,
    this.recommandations,
    this.specialitesSuggerees,
  });

  factory MessageIaModel.fromJson(Map<String, dynamic> json) {
    return MessageIaModel(
      id: json['id']?.toString() ?? '',
      contenu: json['contenu'] ?? json['text'] ?? json['content'] ?? '',
      estUtilisateur: json['est_utilisateur'] ?? json['isUser'] ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      niveauUrgence: json['niveau_urgence'] ?? json['urgencyLevel'],
      recommandations: json['recommandations'] != null ? List<String>.from(json['recommandations']) : null,
      specialitesSuggerees: json['specialites_suggerees'] != null ? List<String>.from(json['specialites_suggerees']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contenu': contenu,
      'est_utilisateur': estUtilisateur,
      'timestamp': timestamp.toIso8601String(),
      'niveau_urgence': niveauUrgence,
      'recommandations': recommandations,
      'specialites_suggerees': specialitesSuggerees,
    };
  }
}
