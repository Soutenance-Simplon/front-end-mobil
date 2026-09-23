import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/verify_phone_otp_screen.dart';
import '../features/auth/screens/setup_profile_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/dashboard_screen.dart';
import '../features/profile/screens/account_settings_screen.dart';
import '../features/profile/screens/family_screen.dart';
import '../features/profile/screens/add_family_member_screen.dart';
import '../features/notification/screens/ecran_notifications.dart';
import '../features/ia/screens/ecran_assistant_ia.dart';
import '../features/patient/screens/qr_scanner_screen.dart';
import '../features/dossier/screens/medical_record_screen.dart';
import '../features/dossier/screens/smart_prescription_screen.dart';
import '../features/dossier/screens/new_consultation_screen.dart';
import '../features/wallet/screens/wallet_screen.dart';
import '../features/rdv/screens/doctor_agenda_screen.dart';
import '../features/rdv/screens/appointments_screen.dart';
import '../features/rdv/screens/doctors_list_screen.dart';
import '../features/rdv/screens/doctor_detail_screen.dart';
import '../features/rdv/screens/book_appointment_screen.dart';
import '../features/rdv/screens/teleconsultation_room_screen.dart';
import '../features/medecin/models/medecin_model.dart';

const String loginRoute = 'login';
const String inscriptionRoute = 'inscription';
const String profileRoute = 'profile';
const String dashboardRoute = 'dashboard';

Map<String, dynamic> _toMap(Object? extra) {
  if (extra is Map<String, dynamic>) return extra;
  if (extra is Map) return Map<String, dynamic>.from(extra);
  return {};
}

Map<String, dynamic> _extractDoctorMap(Object? extra) {
  if (extra is MedecinModel) {
    return extra.toJson();
  }
  return _toMap(extra);
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',

  routes: [
    // ── AUTHENTIFICATION & ONBOARDING ──
    GoRoute(
      path: '/login',
      name: loginRoute,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/connexion',
      name: 'connexion',
      builder: (context, state) => const LoginScreen(),
    ),

    // Inscription : Choix Rôle (Patient / Médecin) puis formulaires dédiés (sans email)
    GoRoute(
      path: '/inscription',
      name: inscriptionRoute,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // Vérification OTP Téléphone / SMS avec pavé tactile numérique
    GoRoute(
      path: '/verify-phone-otp',
      name: 'verify-phone-otp',
      builder: (context, state) => VerifyPhoneOtpScreen(userInfo: _toMap(state.extra)),
    ),
    GoRoute(
      path: '/verification-otp',
      name: 'verification-otp',
      builder: (context, state) => VerifyPhoneOtpScreen(userInfo: _toMap(state.extra)),
    ),

    // Configuration finale du profil (Avatar, Date naissance, Genre, Adresse)
    GoRoute(
      path: '/setup-profile',
      name: 'setup-profile',
      builder: (context, state) => SetupProfileScreen(userInfo: _toMap(state.extra)),
    ),
    GoRoute(
      path: '/configuration-profil',
      name: 'configuration-profil',
      builder: (context, state) => SetupProfileScreen(userInfo: _toMap(state.extra)),
    ),

    // ── TABLEAU DE BORD (Accueil unifié Patient & Médecin) ──
    GoRoute(
      name: dashboardRoute,
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      name: 'tableau-de-bord',
      path: '/tableau-de-bord',
      builder: (context, state) => const DashboardScreen(),
    ),

    // ── PROFIL, FAMILLE & PARAMÈTRES ──
    GoRoute(
      path: '/profile',
      name: profileRoute,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/account-settings',
      name: 'account-settings',
      builder: (context, state) => const AccountSettingsScreen(),
    ),
    GoRoute(
      path: '/family',
      name: 'family',
      builder: (context, state) => const FamilyScreen(),
    ),
    GoRoute(
      path: '/add-family-member',
      name: 'add-family-member',
      builder: (context, state) => const AddFamilyMemberScreen(),
    ),

    // ── NOTIFICATIONS & IA SANTÉ ──
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const EcranNotifications(),
    ),
    GoRoute(
      path: '/assistant-ia',
      name: 'assistant-ia',
      builder: (context, state) => const EcranAssistantIa(),
    ),

    // ── PASS VITAL & SCANNER QR CODE ──
    GoRoute(
      path: '/qr-scanner',
      name: 'qr-scanner',
      builder: (context, state) {
        final extra = _toMap(state.extra);
        return QrScannerScreen(
          initialTabIndex: (extra['tab'] as int?) ?? 0,
          isMedecinScan: extra['isMedecin'] as bool?,
        );
      },
    ),

    // ── DOSSIER MÉDICAL & PRESCRIPTIONS ──
    GoRoute(
      path: '/medical-record',
      name: 'medical-record',
      builder: (context, state) => const MedicalRecordScreen(),
    ),
    GoRoute(
      path: '/dossier-medical',
      name: 'dossier-medical',
      builder: (context, state) => const MedicalRecordScreen(),
    ),
    GoRoute(
      path: '/smart-prescription',
      name: 'smart-prescription',
      builder: (context, state) {
        final extra = state.extra != null ? _extractDoctorMap(state.extra) : null;
        return SmartPrescriptionScreen(patientInfo: extra);
      },
    ),
    GoRoute(
      path: '/new-consultation',
      name: 'new-consultation',
      builder: (context, state) {
        final extra = state.extra != null ? _extractDoctorMap(state.extra) : null;
        return NewConsultationScreen(patientInfo: extra);
      },
    ),

    // ── PORTEFEUILLE SANTÉ WAVE / ORANGE MONEY ──
    GoRoute(
      path: '/wallet',
      name: 'wallet',
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(
      path: '/portefeuille',
      name: 'portefeuille',
      builder: (context, state) => const WalletScreen(),
    ),

    // ── RENDEZ-VOUS, ANNUAIRE & TÉLÉCONSULTATION ──
    GoRoute(
      path: '/doctor-agenda',
      name: 'doctor-agenda',
      builder: (context, state) => const DoctorAgendaScreen(),
    ),
    GoRoute(
      path: '/agenda-medecin',
      name: 'agenda-medecin',
      builder: (context, state) => const DoctorAgendaScreen(),
    ),
    GoRoute(
      path: '/appointments',
      name: 'appointments',
      builder: (context, state) => const AppointmentsScreen(),
    ),
    GoRoute(
      path: '/mes-rendez-vous',
      name: 'mes-rendez-vous',
      builder: (context, state) => const AppointmentsScreen(),
    ),
    GoRoute(
      path: '/doctors',
      name: 'doctors',
      builder: (context, state) => const DoctorsListScreen(),
    ),
    GoRoute(
      path: '/liste-medecins',
      name: 'liste-medecins',
      builder: (context, state) => const DoctorsListScreen(),
    ),
    GoRoute(
      path: '/doctor-detail',
      name: 'doctor-detail',
      builder: (context, state) => DoctorDetailScreen(doctor: _extractDoctorMap(state.extra)),
    ),
    GoRoute(
      path: '/detail-medecin',
      name: 'detail-medecin',
      builder: (context, state) => DoctorDetailScreen(doctor: _extractDoctorMap(state.extra)),
    ),
    GoRoute(
      path: '/book-appointment',
      name: 'book-appointment',
      builder: (context, state) => BookAppointmentScreen(doctor: _extractDoctorMap(state.extra)),
    ),
    GoRoute(
      path: '/prise-rendez-vous',
      name: 'prise-rendez-vous',
      builder: (context, state) => BookAppointmentScreen(doctor: _extractDoctorMap(state.extra)),
    ),
    GoRoute(
      path: '/teleconsultation-room',
      name: 'teleconsultation-room',
      builder: (context, state) {
        final extra = state.extra ?? {};
        return TeleconsultationRoomScreen(rdvData: extra);
      },
    ),
  ],
);
