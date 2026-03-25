// lib/providers/user_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class UserProvider with ChangeNotifier {
  String? _userId;
  UserProfile? _profile;
  bool _isLoading = true;

  String? get userId => _userId;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get hasProfile =>
      _profile != null && _profile!.selectedContexts.isNotEmpty;

  /// Initialize user: load UUID from prefs or generate new one
  Future<void> initUser() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_uuid');

    if (_userId == null) {
      _userId = const Uuid().v4();
      debugPrint('🆕 Generando nuevo UUID: $_userId');
      await prefs.setString('user_uuid', _userId!);
    } else {
      debugPrint('🆔 Cargado UUID existente: $_userId');
    }

    // Try to load profile from backend
    try {
      _profile = await ProfileService.getProfile(_userId!);
    } catch (e) {
      debugPrint('⚠️ Error loading profile: $e');
      // Fallback: empty profile if network error
      _profile = UserProfile(userId: _userId!);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Update profile preferences (Onboarding)
  Future<void> updatePreferences({
    List<String>? contexts,
    String? objective,
    String? tone,
    String? scaffolding,
    List<String>? specificInterests,
  }) async {
    if (_userId == null) return;

    final currentProfile = _profile ?? UserProfile(userId: _userId!);
    final newProfile = currentProfile.copyWith(
      selectedContexts: contexts,
      learningObjective: objective,
      preferredTone: tone,
      scaffoldingLevel: scaffolding,
      specificInterests: specificInterests,
    );

    try {
      _profile = await ProfileService.updateProfile(newProfile);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating preferences: $e');
      rethrow;
    }
  }
}
