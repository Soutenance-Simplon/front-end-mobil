class BeneficiaireModel {
  final String id;
  final String parrainId; // utilisateur qui finance
  final String nom;
  final String prenom;
  final String lienParente; // PERE, MERE, ENFANT, CONJOINT, AUTRE
  final String telephone;
  final double plafondMensuel;

  BeneficiaireModel({
    required this.id,
    required this.parrainId,
    required this.nom,
    required this.prenom,
    this.lienParente = 'PROCHE',
    required this.telephone,
    this.plafondMensuel = 50000,
  });

  factory BeneficiaireModel.fromJson(Map<String, dynamic> json) {
    return BeneficiaireModel(
      id: json['id']?.toString() ?? '',
      parrainId: json['parrain_id']?.toString() ?? json['parrainId']?.toString() ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      lienParente: json['lien_parente'] ?? json['lienParente'] ?? 'PROCHE',
      telephone: json['telephone'] ?? '',
      plafondMensuel: (json['plafond_mensuel'] ?? json['plafondMensuel'] ?? 50000).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parrain_id': parrainId,
      'nom': nom,
      'prenom': prenom,
      'lien_parente': lienParente,
      'telephone': telephone,
      'plafond_mensuel': plafondMensuel,
    };
  }

  String get nomComplet => "$prenom $nom";
}
