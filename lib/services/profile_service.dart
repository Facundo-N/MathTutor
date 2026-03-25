// lib/services/profile_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import 'math_api_service.dart';

class ProfileService {
  static const String _baseUrl = MathApiService.baseUrl;

  /// Fetch user profile from backend
  static Future<UserProfile?> getProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/profile/$userId'),
      );

      if (response.statusCode == 200) {
        return UserProfile.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null; // Profile doesn't exist yet
      } else {
        throw Exception('Error fetching profile: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Create or update user profile
  static Future<UserProfile> updateProfile(UserProfile profile) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profile.toJson()),
      );

      if (response.statusCode == 200) {
        return UserProfile.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error updating profile: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
