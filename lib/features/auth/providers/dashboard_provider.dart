import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/services/api_service.dart';
import 'package:frontend/features/auth/models/specialite_model.dart';


/// API singleton
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// SPECIALITES
final specialitesProvider = FutureProvider<List<Specialite>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getSpecialites();
});

/// TOP DOCTORS
final topDoctorsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getTopDoctors();
});
