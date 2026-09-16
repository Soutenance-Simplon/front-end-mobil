import 'dart:convert';
import '../../auth/models/user_model.dart';
import '../../dossier/models/dossier_medical_model.dart';
import '../models/patient_model.dart';

/// Service centralisé garantissant l'unicité absolue du QR Code pour chaque utilisateur.
/// Règle fondatrice : Tout utilisateur (médecin, patient, citoyen) a UN SEUL ET UNIQUE QR CODE.
/// Le QR Code ne change jamais selon le mode ou l'écran consulté.
class PassVitalHelper {
  /// Retourne un identifiant stable et unique pour l'utilisateur.
  /// Déterministe et immuable.
  static String getUniqueUserId(UserModel? user, {PatientModel? patient}) {
    if (user != null && user.id.trim().isNotEmpty) {
      return user.id.trim();
    }
    if (patient != null && patient.userId.trim().isNotEmpty) {
      return patient.userId.trim();
    }
    if (patient != null && patient.id.trim().isNotEmpty) {
      return patient.id.trim();
    }
    // Fallback déterministe basé sur le téléphone ou l'email (immuable)
    if (user != null && user.telephone.trim().isNotEmpty) {
      final cleanTel = user.telephone.replaceAll(RegExp(r'[^0-9]'), '');
      return "PT-$cleanTel";
    }
    if (user != null && user.email.trim().isNotEmpty) {
      final cleanEmail = user.email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
      return "PT-$cleanEmail";
    }
    return "PT-DIAM-YARAAM-CITOYEN";
  }

  /// Jeton sécurisé officiel du Pass Santé
  static String getUniqueQrToken(UserModel? user, {PatientModel? patient}) {
    if (patient?.qrUrgenceToken != null && patient!.qrUrgenceToken!.trim().isNotEmpty) {
      return patient.qrUrgenceToken!.trim();
    }
    final uid = getUniqueUserId(user, patient: patient);
    final clean = uid.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    return "QR-$clean";
  }

  /// Nom civil officiel pour le Pass Santé (nom civil immuable, sans préfixe dynamique)
  static String getCivilFullName(UserModel? user, {PatientModel? patient}) {
    if (user != null) {
      final prenom = user.firstName.trim();
      final nom = user.lastName.trim();
      if (prenom.isNotEmpty || nom.isNotEmpty) {
        if (prenom.toLowerCase() == nom.toLowerCase()) {
          return prenom;
        }
        return "$prenom $nom".trim();
      }
      if (user.fullName.trim().isNotEmpty) {
        return user.fullName.trim();
      }
    }
    if (patient != null) {
      final prenom = patient.prenom.trim();
      final nom = patient.nom.trim();
      if (prenom.isNotEmpty || nom.isNotEmpty) {
        return "$prenom $nom".trim();
      }
    }
    return "Citoyen Diam-Yaraam";
  }

  /// Construit le payload JSON UNIQUE et CANONIQUE du QR Code.
  /// Ce QR Code est STRICTEMENT IDENTIQUE :
  /// - Sur le Tableau de Bord (Accueil)
  /// - Sur l'écran Mon Pass Vital
  /// - Que l'utilisateur soit en mode Praticien ou Patient
  static String buildCanonicalQrPayload({
    required UserModel? user,
    DossierMedicalModel? dossier,
    PatientModel? patient,
  }) {
    final userId = getUniqueUserId(user, patient: patient);
    final civilFullName = getCivilFullName(user, patient: patient);
    final telephone = user?.telephone.isNotEmpty == true
        ? user!.telephone.trim()
        : (patient?.telephone?.isNotEmpty == true ? patient!.telephone!.trim() : "Non renseigné");

    final bloodGroup = (dossier != null && dossier.groupeSanguin.isNotEmpty)
        ? dossier.groupeSanguin.trim()
        : "Non renseigné";

    final allergies = dossier?.allergies
            .map((a) => "${a.nomAllergene}${a.severite.isNotEmpty ? ' (${a.severite})' : ''}")
            .toList() ??
        [];
    final maladies = dossier?.maladiesChroniques.map((m) => m.nomMaladie).toList() ?? [];
    final antecedents = dossier?.antecedents.map((a) => a.description).toList() ?? [];
    final traitements = dossier?.prescriptions
            .expand((p) => p.lignes)
            .map((l) => "${l.medicament} ${l.dosage} (${l.posologie})")
            .toList() ??
        [];

    final contactNom = (patient?.personneContact != null && patient!.personneContact!.trim().isNotEmpty)
        ? patient.personneContact!.trim()
        : "Non renseigné";
    final contactTel = (patient?.telephoneContact != null && patient!.telephoneContact!.trim().isNotEmpty)
        ? patient.telephoneContact!.trim()
        : telephone;
    final contactLien = (patient?.lienParenteContact != null && patient!.lienParenteContact!.trim().isNotEmpty)
        ? patient.lienParenteContact!.trim()
        : "Proche";

    final Map<String, dynamic> payload = {
      "type": "DIAM_YARAAM_PASS",
      "patient_id": userId,
      "nom_complet": civilFullName,
      "telephone": telephone,
      "groupe_sanguin": bloodGroup,
      "allergies_majeures": allergies,
      "maladies_chroniques": maladies,
      "contact_urgence_nom": contactNom,
      "contact_urgence_tel": contactTel,
      "contact_urgence_lien": contactLien,
    };

    return jsonEncode(payload);
  }
}
