class AllergieModel {
  final String id;
  final String nomAllergene;
  final String typeAllergie; // MEDICAMENTEUSE, ALIMENTAIRE, ENVIRONNEMENTALE
  final String severite; // FAIBLE, MOYENNE, SEVERE
  final String? reaction;

  AllergieModel({
    required this.id,
    required this.nomAllergene,
    this.typeAllergie = 'MEDICAMENTEUSE',
    this.severite = 'SEVERE',
    this.reaction,
  });

  factory AllergieModel.fromJson(Map<String, dynamic> json) {
    return AllergieModel(
      id: json['id']?.toString() ?? '',
      nomAllergene: json['nom_allergene'] ?? json['nomAllergene'] ?? json['name'] ?? '',
      typeAllergie: json['type_allergie'] ?? json['typeAllergie'] ?? 'MEDICAMENTEUSE',
      severite: json['severite'] ?? 'SEVERE',
      reaction: json['reaction'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_allergene': nomAllergene,
      'type_allergie': typeAllergie,
      'severite': severite,
      'reaction': reaction,
    };
  }
}
