import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ──────────────────────────────────────────────────────────
/// OnyxFi — Authentication State (ChangeNotifier)
/// ──────────────────────────────────────────────────────────
/// Manages Supabase auth lifecycle: signup, login, logout,
/// and session persistence. Exposes the authenticated user's
/// UUID so downstream providers and API calls can reference it.
///
/// UUID Source: Supabase Auth auto-generates a UUID for each
/// user on signup. We read it from `session.user.id`.
/// ──────────────────────────────────────────────────────────

class AuthStateNotifier extends ChangeNotifier {
  String? _userId;
  String? _userEmail;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  bool get isAuthenticated => _userId != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Reference to the Supabase auth client.
  SupabaseClient get _client => Supabase.instance.client;

  // ── Check Existing Session ────────────────────────────
  /// Call this at app startup to restore a persisted session.
  /// Returns `true` if a valid session exists.
  bool checkSession() {
    final session = _client.auth.currentSession;
    if (session != null) {
      _userId = session.user.id;
      _userEmail = session.user.email;
      notifyListeners();
      debugPrint('[AuthState] ✅ Session restored: $_userEmail ($_userId)');
      return true;
    }
    debugPrint('[AuthState] No existing session found.');
    return false;
  }

  // ── Sign Up ───────────────────────────────────────────
  /// Creates a new Supabase auth user with email + password.
  /// On success, stores the UUID in memory and notifies listeners.
  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        _userId = response.user!.id;
        _userEmail = response.user!.email;
        debugPrint('[AuthState] ✅ Sign up successful: $_userEmail ($_userId)');
        _setLoading(false);
        return true;
      } else {
        _setError('Kayıt başarısız oldu. Lütfen tekrar deneyin.');
        _setLoading(false);
        return false;
      }
    } on AuthException catch (e) {
      debugPrint('[AuthState] ❌ Sign up error: ${e.message}');
      _setError(_localizeAuthError(e.message));
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('[AuthState] ❌ Unexpected sign up error: $e');
      _setError('Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.');
      _setLoading(false);
      return false;
    }
  }

  // ── Sign In ───────────────────────────────────────────
  /// Authenticates an existing user with email + password.
  /// On success, stores the UUID in memory and notifies listeners.
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.session != null) {
        _userId = response.session!.user.id;
        _userEmail = response.session!.user.email;
        debugPrint('[AuthState] ✅ Sign in successful: $_userEmail ($_userId)');
        _setLoading(false);
        return true;
      } else {
        _setError('Giriş başarısız oldu. Lütfen bilgilerinizi kontrol edin.');
        _setLoading(false);
        return false;
      }
    } on AuthException catch (e) {
      debugPrint('[AuthState] ❌ Sign in error: ${e.message}');
      _setError(_localizeAuthError(e.message));
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('[AuthState] ❌ Unexpected sign in error: $e');
      _setError('Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.');
      _setLoading(false);
      return false;
    }
  }

  // ── Sign Out ──────────────────────────────────────────
  /// Clears the local session and Supabase auth state.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('[AuthState] Sign out error (non-fatal): $e');
    }
    _userId = null;
    _userEmail = null;
    _clearError();
    notifyListeners();
    debugPrint('[AuthState] Signed out.');
  }

  // ── Private Helpers ───────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    // Don't notify here — caller will notify after their operation.
  }

  /// Maps common Supabase auth error messages to Turkish equivalents.
  String _localizeAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already_exists')) {
      return 'Bu e-posta zaten kayıtlı. Giriş yapmayı deneyin.';
    }
    if (lower.contains('password') && lower.contains('short')) {
      return 'Şifre en az 6 karakter olmalıdır.';
    }
    if (lower.contains('email') && lower.contains('invalid')) {
      return 'Geçerli bir e-posta adresi girin.';
    }
    if (lower.contains('network') || lower.contains('socket')) {
      return 'İnternet bağlantınızı kontrol edin.';
    }
    return message;
  }
}
