import 'consultation_model.dart';
import 'prescription_model.dart';
import 'allergie_model.dart';
import 'antecedent_model.dart';
import 'maladie_chronique_model.dart';
import 'vaccination_model.dart';
import 'document_medical_model.dart';
import 'hospitalisation_model.dart';

class DossierMedicalModel {
  final String id;
  final String patientId;
  final String groupeSanguin;
  final double? poidsKg;
  final double? tailleCm;
  final List<AllergieModel> allergies;
  final List<AntecedentModel> antecedents;
  final List<MaladieChroniqueModel> maladiesChroniques;
  final List<VaccinationModel> vaccinations;
  final List<ConsultationModel> consultations;
  final List<PrescriptionModel> prescriptions;
  final List<DocumentMedicalModel> documents;
  final List<HospitalisationModel> hospitalisations;

  DossierMedicalModel({
    required this.id,
    required this.patientId,
    this.groupeSanguin = 'O+',
    this.poidsKg = 72.5,
    this.tailleCm = 178,
    this.allergies = const [],
    this.antecedents = const [],
    this.maladiesChroniques = const [],
    this.vaccinations = const [],
    this.consultations = const [],
    this.prescriptions = const [],
    this.documents = const [],
    this.hospitalisations = const [],
  });

  factory DossierMedicalModel.fromJson(Map<String, dynamic> json) {
    return DossierMedicalModel(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? json['patientId']?.toString() ?? '',
      groupeSanguin: json['groupe_sanguin'] ?? json['groupeSanguin'] ?? 'O+',
      poidsKg: (json['poids_kg'] ?? json['poidsKg'] ?? 72.5).toDouble(),
      tailleCm: (json['taille_cm'] ?? json['tailleCm'] ?? 178).toDouble(),
      allergies: (json['allergies'] as List? ?? []).map((e) => AllergieModel.fromJson(e)).toList(),
      antecedents: (json['antecedents'] as List? ?? []).map((e) => AntecedentModel.fromJson(e)).toList(),
      maladiesChroniques: (json['maladies_chroniques'] as List? ?? json['maladiesChroniques'] as List? ?? []).map((e) => MaladieChroniqueModel.fromJson(e)).toList(),
      vaccinations: (json['vaccinations'] as List? ?? []).map((e) => VaccinationModel.fromJson(e)).toList(),
      consultations: (json['consultations'] as List? ?? []).map((e) => ConsultationModel.fromJson(e)).toList(),
      prescriptions: (json['prescriptions'] as List? ?? []).map((e) => PrescriptionModel.fromJson(e)).toList(),
      documents: (json['documents'] as List? ?? []).map((e) => DocumentMedicalModel.fromJson(e)).toList(),
      hospitalisations: (json['hospitalisations'] as List? ?? []).map((e) => HospitalisationModel.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'groupe_sanguin': groupeSanguin,
      'poids_kg': poidsKg,
      'taille_cm': tailleCm,
      'allergies': allergies.map((e) => e.toJson()).toList(),
      'antecedents': antecedents.map((e) => e.toJson()).toList(),
      'maladies_chroniques': maladiesChroniques.map((e) => e.toJson()).toList(),
      'vaccinations': vaccinations.map((e) => e.toJson()).toList(),
      'consultations': consultations.map((e) => e.toJson()).toList(),
      'prescriptions': prescriptions.map((e) => e.toJson()).toList(),
      'documents': documents.map((e) => e.toJson()).toList(),
      'hospitalisations': hospitalisations.map((e) => e.toJson()).toList(),
    };
  }
}
