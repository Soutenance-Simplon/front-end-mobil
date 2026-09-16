class SpecialiteModel {
  final int id;
  final String nom;
  final String? description;
  final String? icone;

  SpecialiteModel({
    required this.id,
    required this.nom,
    this.description,
    this.icone,
  });

  factory SpecialiteModel.fromJson(Map<String, dynamic> json) {
    return SpecialiteModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      nom: json['nom'] ?? json['nom_specialite'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      icone: json['icone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'icone': icone,
    };
  }
}
