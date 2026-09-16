import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/portefeuille_model.dart';
import '../models/transaction_model.dart';
import '../services/wallet_api_service.dart';

class WalletState {
  final bool isLoading;
  final String? error;
  final PortefeuilleModel? portefeuille;
  final List<TransactionModel> transactions;
  final List<Map<String, dynamic>> mesBeneficiaires;
  final List<Map<String, dynamic>> mesInvitations;

  const WalletState({
    this.isLoading = false,
    this.error,
    this.portefeuille,
    this.transactions = const [],
    this.mesBeneficiaires = const [],
    this.mesInvitations = const [],
  });

  WalletState copyWith({
    bool? isLoading,
    String? error,
    PortefeuilleModel? portefeuille,
    List<TransactionModel>? transactions,
    List<Map<String, dynamic>>? mesBeneficiaires,
    List<Map<String, dynamic>>? mesInvitations,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      portefeuille: portefeuille ?? this.portefeuille,
      transactions: transactions ?? this.transactions,
      mesBeneficiaires: mesBeneficiaires ?? this.mesBeneficiaires,
      mesInvitations: mesInvitations ?? this.mesInvitations,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final WalletApiService _apiService;

  WalletNotifier(this._apiService) : super(const WalletState());

  Future<void> loadUserWallet(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final p = await _apiService.getPortefeuille(userId);
      final txs = p != null ? await _apiService.getTransactions(userId) : <TransactionModel>[];
      final bens = await _apiService.getMesBeneficiaires(userId);
      final invs = await _apiService.getInvitations(userId);
      state = state.copyWith(isLoading: false, portefeuille: p, transactions: txs, mesBeneficiaires: bens, mesInvitations: invs);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> rechargerDonnees() async {
    if (state.portefeuille != null) {
      await loadUserWallet(state.portefeuille!.userId);
    }
  }

  Future<bool> recharger({
    required double montant,
    required String moyenPaiement,
    required String numeroTelephone,
  }) async {
    if (state.portefeuille == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ok = await _apiService.rechargerPortefeuille(
        portefeuilleId: state.portefeuille!.id,
        montant: montant,
        moyenPaiement: moyenPaiement,
        numeroTelephone: numeroTelephone,
      );
      if (ok) {
        final nouveauSolde = state.portefeuille!.solde + montant;
        final nouveauPortefeuille = PortefeuilleModel(
          id: state.portefeuille!.id,
          userId: state.portefeuille!.userId,
          solde: nouveauSolde,
          devise: state.portefeuille!.devise,
        );
        final nouvelleTx = TransactionModel(
          id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
          portefeuilleId: state.portefeuille!.id,
          montant: montant,
          typeTransaction: 'DEPOT',
          moyenPaiement: moyenPaiement,
          description: "Rechargement $moyenPaiement",
          dateTransaction: DateTime.now(),
        );
        state = state.copyWith(
          isLoading: false,
          portefeuille: nouveauPortefeuille,
          transactions: [nouvelleTx, ...state.transactions],
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: "Échec du rechargement");
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> payerConsultation({
    required String userId,
    required double montant,
    required String rdvId,
    String? medecinId,
    String? description,
  }) async {
    final currentUserId = (state.portefeuille?.userId.isNotEmpty == true)
        ? state.portefeuille!.userId
        : userId;
    try {
      final ok = await _apiService.payerConsultation(
        userId: currentUserId,
        rdvId: rdvId,
        montant: montant,
        medecinId: medecinId,
        description: description,
      );
      if (state.portefeuille != null) {
        final nouveauSolde = (state.portefeuille!.solde - montant).clamp(0.0, double.infinity);
        final nouveauPortefeuille = PortefeuilleModel(
          id: state.portefeuille!.id,
          userId: state.portefeuille!.userId,
          solde: nouveauSolde,
          devise: state.portefeuille!.devise,
        );
        final nouvelleTx = TransactionModel(
          id: 'tx-${DateTime.now().millisecondsSinceEpoch}',
          portefeuilleId: state.portefeuille!.id,
          montant: montant,
          typeTransaction: 'PAIEMENT_CONSULTATION',
          moyenPaiement: 'SOLDE_PORTEFEUILLE',
          description: description ?? 'Règlement Consultation Médicale',
          dateTransaction: DateTime.now(),
        );
        state = state.copyWith(
          portefeuille: nouveauPortefeuille,
          transactions: [nouvelleTx, ...state.transactions],
        );
      }
      return ok;
    } catch (e) {
      return false;
    }
  }
}

final walletApiServiceProvider = Provider<WalletApiService>((ref) {
  return WalletApiService();
});

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final api = ref.watch(walletApiServiceProvider);
  final authState = ref.watch(authProvider);
  final notifier = WalletNotifier(api);
  if (authState.user != null && authState.user!.id.isNotEmpty) {
    notifier.loadUserWallet(authState.user!.id);
  }
  return notifier;
});
