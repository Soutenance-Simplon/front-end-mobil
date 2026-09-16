class RoleModel {
  final String id;
  final String nomRole;

  RoleModel({required this.id, required this.nomRole});

  String get nom => nomRole;

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id']?.toString() ?? '',
      nomRole: json['nom_role'] ?? json['nomRole'] ?? json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_role': nomRole,
    };
  }
}
