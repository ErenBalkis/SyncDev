import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ──────────────────────────────────────────────────────────
/// OnyxFi — FastAPI Backend Bridge (HTTP Client)
/// ──────────────────────────────────────────────────────────
/// Singleton that communicates with the Python FastAPI backend.
///
/// Base URL auto-detection:
///   - Android emulator  → http://10.0.2.2:8000
///   - iOS simulator     → http://localhost:8000
///   - Web / Desktop     → http://localhost:8000
///
/// Primary method: createProfile() — sends POST /profiles/
/// with onboarding data + authenticated user UUID.
/// ──────────────────────────────────────────────────────────

class ApiClient {
  // ── Singleton ──────────────────────────────────────────
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  /// Base URL for the FastAPI backend.
  /// Android emulator routes `10.0.2.2` → host machine's `localhost`.
  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {
      // Platform not available (web fallback already handled above)
    }
    return 'http://localhost:8000';
  }

  // ── POST /profiles/ ───────────────────────────────────
  /// Creates a user profile in the Supabase `user_profiles` table
  /// via the FastAPI backend.
  ///
  /// [userId] — Supabase Auth UUID (from AuthStateNotifier)
  /// [monthlyIncome] — from OnboardingStateNotifier.monthlySalary
  /// [currentSavings] — from OnboardingStateNotifier.currentSavings
  /// [monthlyExpenses] — from OnboardingStateNotifier.monthlyExpenses
  /// [currentAge] — defaults to 25
  /// [targetRetirementAge] — defaults to 50
  /// [riskTolerance] — defaults to "medium"
  ///
  /// Returns the created profile as a Map on success.
  /// Throws [ApiException] on failure.
  Future<Map<String, dynamic>> createProfile({
    required String userId,
    required double monthlyIncome,
    required double currentSavings,
    required double monthlyExpenses,
    int currentAge = 25,
    int targetRetirementAge = 50,
    String riskTolerance = 'medium',
  }) async {
    final url = Uri.parse('$_baseUrl/profiles/');

    final body = jsonEncode({
      'id': userId,
      'current_age': currentAge,
      'target_retirement_age': targetRetirementAge,
      'monthly_income': monthlyIncome,
      'current_savings': currentSavings,
      'monthly_expenses': monthlyExpenses,
      'risk_tolerance': riskTolerance,
    });

    debugPrint('[ApiClient] POST /profiles/ → $url');
    debugPrint('[ApiClient] Body: $body');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[ApiClient] ✅ Profile created successfully.');
        return data;
      } else {
        final errorDetail = _extractErrorDetail(response);
        debugPrint('[ApiClient] ❌ Server error ${response.statusCode}: $errorDetail');
        throw ApiException(
          'Profil oluşturulamadı (${response.statusCode}): $errorDetail',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      debugPrint('[ApiClient] ❌ Network error: $e');
      throw ApiException(
        'Sunucuya bağlanılamadı. Backend sunucusunun çalıştığından emin olun.',
      );
    } on FormatException catch (e) {
      debugPrint('[ApiClient] ❌ JSON parse error: $e');
      throw ApiException('Sunucu yanıtı okunamadı.');
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('[ApiClient] ❌ Unexpected error: $e');
      throw ApiException(
        'Beklenmeyen bir ağ hatası oluştu. Lütfen tekrar deneyin.',
      );
    }
  }

  // ── GET /profiles/{userId} ────────────────────────────
  /// Checks whether a profile exists for the given user.
  /// Returns the profile Map on success, or `null` if not found (404).
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final url = Uri.parse('$_baseUrl/profiles/$userId');
    debugPrint('[ApiClient] GET /profiles/$userId → $url');

    try {
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        debugPrint('[ApiClient] Profile not found (new user).');
        return null;
      } else {
        debugPrint('[ApiClient] ❌ GET profile error ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[ApiClient] ❌ GET profile network error: $e');
      // Non-fatal: if server is offline, treat as "no profile" → go to onboarding
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────

  /// Extracts the `detail` field from a FastAPI error response.
  String _extractErrorDetail(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      if (json is Map && json.containsKey('detail')) {
        return json['detail'].toString();
      }
    } catch (_) {}
    return response.body.length > 200
        ? '${response.body.substring(0, 200)}...'
        : response.body;
  }
}

/// Custom exception for API errors with optional HTTP status code.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}
