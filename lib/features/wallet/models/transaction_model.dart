class TransactionModel {
  final String id;
  final String portefeuilleId;
  final double montant;
  final String typeTransaction; // RECHARGE, PAIEMENT_CONSULTATION, TRANSFERT_PROCHE, REMBOURSEMENT
  final String moyenPaiement; // WAVE, ORANGE_MONEY, CARTE_BANCAIRE, PORTEFEUILLE
  final String statut; // REUSSI, EN_ATTENTE, ECHOUE
  final String description;
  final DateTime dateTransaction;
  final String? referenceExterne;

  TransactionModel({
    required this.id,
    required this.portefeuilleId,
    required this.montant,
    required this.typeTransaction,
    this.moyenPaiement = 'WAVE',
    this.statut = 'REUSSI',
    required this.description,
    required this.dateTransaction,
    this.referenceExterne,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final rawMontant = json['montant'] ?? json['amount'];
    final montantVal = (rawMontant is num)
        ? rawMontant.toDouble()
        : (double.tryParse(rawMontant?.toString() ?? '0') ?? 0.0);

    final pId = json['portefeuille_id']?.toString() ??
        json['portefeuilleId']?.toString() ??
        (json['portefeuille'] is Map ? json['portefeuille']['id']?.toString() : null) ??
        '';

    final rawDate = json['date_transaction'] ?? json['dateTransaction'] ?? json['date'] ?? json['createdAt'];
    final dateVal = (rawDate != null)
        ? (DateTime.tryParse(rawDate.toString()) ?? DateTime.now())
        : DateTime.now();

    return TransactionModel(
      id: json['id']?.toString() ?? '',
      portefeuilleId: pId,
      montant: montantVal,
      typeTransaction: json['type_transaction']?.toString() ??
          json['typeTransaction']?.toString() ??
          json['type']?.toString() ??
          'DEPOT',
      moyenPaiement: json['moyen_paiement']?.toString() ??
          json['moyenPaiement']?.toString() ??
          json['paymentMethod']?.toString() ??
          'WAVE',
      statut: json['statut']?.toString() ?? json['status']?.toString() ?? 'VALIDE',
      description: json['description']?.toString() ?? '',
      dateTransaction: dateVal,
      referenceExterne: json['reference_externe']?.toString() ?? json['referenceExterne']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'portefeuille_id': portefeuilleId,
      'montant': montant,
      'type_transaction': typeTransaction,
      'moyen_paiement': moyenPaiement,
      'statut': statut,
      'description': description,
      'date_transaction': dateTransaction.toIso8601String(),
    };
  }

  bool get estCredit {
    final type = typeTransaction.toUpperCase();
    return type == 'RECHARGE' ||
        type == 'DEPOT' ||
        type == 'REMBOURSEMENT' ||
        type == 'CREDIT' ||
        type.contains('HONORAIRES') ||
        type.contains('REVENUE');
  }
}
