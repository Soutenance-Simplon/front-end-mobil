import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/portefeuille_model.dart';
import '../models/transaction_model.dart';

class WalletApiService {
  final ApiClient _client = ApiClient();
  Dio get dio => _client.dio;

  /// Récupérer le portefeuille de l'utilisateur
  Future<PortefeuilleModel?> getPortefeuille(String userId) async {
    try {
      final response = await dio.get('/portefeuilles/user/$userId');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return PortefeuilleModel.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Recharger le portefeuille via Wave ou Orange Money
  Future<bool> rechargerPortefeuille({
    required String portefeuilleId,
    required double montant,
    required String moyenPaiement, // WAVE, ORANGE_MONEY
    required String numeroTelephone,
  }) async {
    try {
      final response = await dio.post(
        '/portefeuilles/deposer',
        queryParameters: {
          'userId': portefeuilleId,
          'montant': montant,
          'moyen': moyenPaiement == 'WAVE' ? 'MOBILE_MONEY_WAVE' : 'MOBILE_MONEY_ORANGE',
          'reference': numeroTelephone,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Payer une consultation médicale (Débit du patient + Crédit du médecin)
  Future<bool> payerConsultation({
    required String userId,
    required String rdvId,
    required double montant,
    String? medecinId,
    String? description,
  }) async {
    try {
      final response = await dio.post(
        '/portefeuilles/payer-service',
        queryParameters: {
          'userId': userId,
          'montant': montant,
          'type': 'PAIEMENT_TELECONSULTATION',
          'description': description ?? 'Règlement Consultation $rdvId',
          if (medecinId != null && medecinId.isNotEmpty) 'medecinUserId': medecinId,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer l'historique des transactions
  Future<List<TransactionModel>> getTransactions(String userId) async {
    try {
      final response = await dio.get('/portefeuilles/user/$userId/historique');
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data;
        final List list;
        if (raw is List) {
          list = raw;
        } else if (raw is Map && raw['data'] is List) {
          list = raw['data'] as List;
        } else {
          list = [];
        }
        final result = <TransactionModel>[];
        for (final item in list) {
          try {
            if (item is Map<String, dynamic>) {
              result.add(TransactionModel.fromJson(item));
            } else if (item is Map) {
              result.add(TransactionModel.fromJson(Map<String, dynamic>.from(item)));
            }
          } catch (_) {
            // Keep going if one item fails
          }
        }
        return result;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Registre et cache des noms d'utilisateurs Diam Yaraam
  static final Map<String, String> _userNamesCache = {
    'ba869f7a-4ba9-49de-86df-59cc10b6f3e7': 'Fatou Ndiaye',
    '5b7603ef-fea9-48b9-bfce-431c30702617': 'Dr. Mariama Ba',
    '99e7da2a-70a9-4a0c-a33b-d7061a9be38f': 'Aminata Gueye',
    '3479cb7c-6a74-42aa-8fd9-11e0eaeff149': 'Ibrahim Traore',
    'f880df2d-f0c0-4bd1-bafa-7242bab62226': 'Khadija Sarr',
    'c387368f-9274-4d46-9fee-e8ddd34d7c36': 'Mamadou Kane',
    'a4020b38-a282-4372-847c-4765a4c18c1f': 'Oumar Diallo',
    '90ee9e44-68ce-4bf9-bdad-dc3a4d33f61d': 'Dr. Mouhamed Sow',
    '58640569-a522-491f-bc98-8ef4c8c7d744': 'Dr. Aïssatou Diop',
    'e27223a2-4984-4e81-9a6a-738a11b8ae0e': 'Dr. Cheikh Fall',
    '6b0662f5-ef8b-47f9-aa25-b7a6980e6472': 'Mari Sene',
    '93591d8a-0e37-41b9-9c70-1dfad06b538c': 'Enfant Fall',
    'c5381747-e6fe-4e4c-bda7-a38bec8bf5c2': 'Proche Diallo',
  };

  static void cacheUserName(String userId, String fullName) {
    final cleanId = userId.toLowerCase().trim();
    final cleanName = fullName.trim();
    if (cleanId.isNotEmpty && cleanName.isNotEmpty) {
      _userNamesCache[cleanId] = cleanName;
    }
  }

  static String getNomUtilisateur(String? userId, {String? fallbackLien}) {
    if (userId == null || userId.isEmpty) {
      return fallbackLien != null && fallbackLien.isNotEmpty ? "Proche ($fallbackLien)" : "Proche bénéficiaire";
    }
    final cleanId = userId.toLowerCase().trim();
    if (_userNamesCache.containsKey(cleanId)) {
      return _userNamesCache[cleanId]!;
    }
    if (fallbackLien != null && fallbackLien.isNotEmpty) {
      final cleanLien = fallbackLien.substring(0, 1).toUpperCase() + fallbackLien.substring(1).toLowerCase();
      return "Proche ($cleanLien)";
    }
    return "Proche bénéficiaire";
  }

  /// Rechercher un utilisateur par téléphone
  Future<Map<String, dynamic>?> rechercherUserParTelephone(String telephone) async {
    try {
      final response = await dio.get('/auth/search', queryParameters: {'telephone': telephone});
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          final uid = data['id']?.toString() ?? '';
          final prenom = data['firstName']?.toString() ?? '';
          final nom = data['lastName']?.toString() ?? '';
          final nomComplet = "$prenom $nom".trim();
          if (uid.isNotEmpty && nomComplet.isNotEmpty) {
            cacheUserName(uid, nomComplet);
          }
        }
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Inviter un proche
  Future<bool> inviterProche({
    required String tuteurUserId,
    required String beneficiaireUserId,
    required String lien,
    double? plafond,
  }) async {
    try {
      final response = await dio.post(
        '/portefeuilles/beneficiaire/inviter',
        queryParameters: {
          'tuteurUserId': tuteurUserId,
          'beneficiaireUserId': beneficiaireUserId,
          'lien': lien,
          if (plafond != null) 'plafond': plafond,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer les invitations reçues par un utilisateur
  Future<List<Map<String, dynamic>>> getInvitations(String userId) async {
    try {
      final response = await dio.get('/portefeuilles/beneficiaire/invitations/$userId');
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data['data'] ?? [];
        final items = List<Map<String, dynamic>>.from(list);
        for (var inv in items) {
          final tuteurId = inv['portefeuille']?['userId']?.toString() ?? '';
          inv['nomTuteur'] = getNomUtilisateur(tuteurId);
        }
        return items;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Répondre à une invitation
  Future<bool> repondreInvitation(String beneficiaireId, String action) async {
    try {
      final response = await dio.post(
        '/portefeuilles/beneficiaire/$beneficiaireId/repondre',
        queryParameters: {'action': action},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer mes bénéficiaires avec leurs noms réels
  Future<List<Map<String, dynamic>>> getMesBeneficiaires(String tuteurUserId) async {
    try {
      final response = await dio.get('/portefeuilles/beneficiaire/mes-beneficiaires/$tuteurUserId');
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data['data'] ?? [];
        final items = List<Map<String, dynamic>>.from(list);
        for (var b in items) {
          final bUserId = b['beneficiaireUserId']?.toString() ?? '';
          final lien = b['lienParente']?.toString();
          b['nomBeneficiaire'] = getNomUtilisateur(bUserId, fallbackLien: lien);
        }
        return items;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  Future<bool> supprimerBeneficiaire(String beneficiaireId) async {
    try {
      final response = await dio.delete('/portefeuilles/beneficiaire/$beneficiaireId');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}
