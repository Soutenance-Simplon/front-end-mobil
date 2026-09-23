class NotificationModel {
  final String id;
  final String userId;
  final String titre;
  final String corps;
  final String typeNotification; // RAPPEL_RDV, RAPPEL_TRAITEMENT, PAIEMENT, URGENCE, SYSTEME
  final DateTime dateEnvoi;
  final bool lue;
  final String? lienRedirection;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.titre,
    required this.corps,
    this.typeNotification = 'RAPPEL_RDV',
    required this.dateEnvoi,
    this.lue = false,
    this.lienRedirection,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      titre: json['titre'] ?? json['title'] ?? 'Notification',
      corps: json['corps'] ?? json['body'] ?? json['message'] ?? '',
      typeNotification: json['type_notification'] ?? json['typeNotification'] ?? json['type'] ?? 'RAPPEL_RDV',
      dateEnvoi: DateTime.tryParse(json['date_envoi'] ?? json['dateEnvoi'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
      lue: json['lue'] ?? json['read'] ?? false,
      lienRedirection: json['lien_redirection'] ?? json['lienRedirection'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'titre': titre,
      'corps': corps,
      'type_notification': typeNotification,
      'date_envoi': dateEnvoi.toIso8601String(),
      'lue': lue,
      'lien_redirection': lienRedirection,
    };
  }
}
