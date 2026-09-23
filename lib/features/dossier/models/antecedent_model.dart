class AntecedentModel {
  final String id;
  final String description;
  final String typeAntecedent; // MEDICAL, CHIRURGICAL, FAMILIAL
  final String? dateEvenement;

  AntecedentModel({
    required this.id,
    required this.description,
    this.typeAntecedent = 'MEDICAL',
    this.dateEvenement,
  });

  factory AntecedentModel.fromJson(Map<String, dynamic> json) {
    return AntecedentModel(
      id: json['id']?.toString() ?? '',
      description: json['description'] ?? '',
      typeAntecedent: json['type_antecedent'] ?? json['typeAntecedent'] ?? 'MEDICAL',
      dateEvenement: json['date_evenement'] ?? json['dateEvenement'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'type_antecedent': typeAntecedent,
      'date_evenement': dateEvenement,
    };
  }
}
