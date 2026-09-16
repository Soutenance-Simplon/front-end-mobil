class PortefeuilleModel {
  final String id;
  final String userId;
  final double solde;
  final String devise;
  final bool actif;
  final DateTime? dateDerniereTransaction;

  PortefeuilleModel({
    required this.id,
    required this.userId,
    required this.solde,
    this.devise = 'FCFA',
    this.actif = true,
    this.dateDerniereTransaction,
  });

  factory PortefeuilleModel.fromJson(Map<String, dynamic> json) {
    return PortefeuilleModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      solde: (json['solde'] ?? json['balance'] ?? 0).toDouble(),
      devise: json['devise'] ?? json['currency'] ?? 'FCFA',
      actif: json['actif'] ?? json['active'] ?? true,
      dateDerniereTransaction: json['date_derniere_transaction'] != null
          ? DateTime.tryParse(json['date_derniere_transaction'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'solde': solde,
      'devise': devise,
      'actif': actif,
    };
  }

  String get soldeFormate => "${solde.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} $devise";
}
