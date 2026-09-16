class MembreFamille {
  final String id;
  final String parentUserId;
  final String enfantUserId;
  final String nom;
  final String prenom;
  final String? dateNaissance;
  final String? genre;
  final String lienParente;

  MembreFamille({
    required this.id,
    required this.parentUserId,
    required this.enfantUserId,
    required this.nom,
    required this.prenom,
    this.dateNaissance,
    this.genre,
    required this.lienParente,
  });

  factory MembreFamille.fromJson(Map<String, dynamic> json) {
    return MembreFamille(
      id: json['id'] ?? '',
      parentUserId: json['parentUserId'] ?? '',
      enfantUserId: json['enfantUserId'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      dateNaissance: json['dateNaissance'],
      genre: json['genre'],
      lienParente: json['lienParente'] ?? 'Inconnu',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'dateNaissance': dateNaissance,
      'genre': genre,
      'lienParente': lienParente,
    };
  }
}
