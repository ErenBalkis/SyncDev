import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onyxfi_frontend/core/constants/colors.dart';
import 'package:onyxfi_frontend/core/theme/app_theme.dart';
import 'package:onyxfi_frontend/core/network/api_client.dart';
import 'package:onyxfi_frontend/models/auth_state.dart';
import 'package:onyxfi_frontend/widgets/glass_container.dart';
import 'package:onyxfi_frontend/main.dart';

/// ──────────────────────────────────────────────────────────
/// OnyxFi — Authentication View (Ambient Transparent Glass)
/// ──────────────────────────────────────────────────────────
/// Stack layout:
///   Layer 0 — Dynamic background image (Black & Orange abstract)
///   Layer 1 — Legibility overlay (dark, moderate opacity)
///   Layer 2 — Ambient Solar Orange glow accents
///   Layer 3 — SafeArea with transparent glass auth form
///
/// Strict design: NO BLUE. Only Solar Orange + Midnight Ink +
/// frost-white glass borders. Premium spatial-computing feel.
/// ──────────────────────────────────────────────────────────

class AuthView extends StatefulWidget {
  const AuthView({super.key});
  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late final AnimationController _glowPulse;

  @override
  void initState() {
    super.initState();
    _glowPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _glowPulse.dispose();
    super.dispose();
  }

  // ── Submit Handler ─────────────────────────────────────
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthStateNotifier>();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    bool success;
    if (_isLoginMode) {
      success = await auth.signIn(email, password);
    } else {
      success = await auth.signUp(email, password);
    }

    if (!mounted) return;

    if (success && auth.userId != null) {
      // Check if user already has a profile → route accordingly
      await _routeAfterAuth(auth.userId!);
    }
    // Errors are displayed via AuthStateNotifier.errorMessage
  }

  /// Checks backend for existing profile to decide routing.
  Future<void> _routeAfterAuth(String userId) async {
    try {
      final profile = await ApiClient().getProfile(userId);
      if (!mounted) return;

      if (profile != null) {
        // Returning user → Dashboard
        debugPrint('[AuthView] Profile exists → Dashboard');
        context.read<AppState>().completeOnboarding();
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // New user → Onboarding
        debugPrint('[AuthView] No profile → Onboarding');
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } catch (e) {
      debugPrint('[AuthView] Profile check failed: $e');
      if (!mounted) return;
      // If backend is offline, default to onboarding
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sunucu bağlantısı kurulamadı. Yeni kullanıcı akışına yönlendiriliyorsunuz.',
            style: AppTheme.bodySm.copyWith(color: AppColors.snowWhite),
          ),
          backgroundColor: AppColors.deepSlate,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  // ── Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bgImage = context.watch<AppState>().backgroundImage;
    final auth = context.watch<AuthStateNotifier>();

    return Scaffold(
      body: Stack(
        children: [
          // ── Layer 0: Dynamic Background Image ──────────
          Positioned.fill(
            child: Image.asset(
              bgImage,
              fit: BoxFit.cover,
              errorBuilder: (context, e, stackTrace) => Container(
                decoration: const BoxDecoration(gradient: AppColors.midnightGradient),
              ),
            ),
          ),

          // ── Layer 1: Legibility Overlay ────────────────
          Positioned.fill(
            child: Container(color: AppColors.legibilityOverlay),
          ),

          // ── Layer 2: Ambient Solar Orange Glows ────────
          Positioned(
            top: -120,
            right: -100,
            child: AnimatedBuilder(
              animation: _glowPulse,
              builder: (context, child) => Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.solarOrange.withValues(
                        alpha: 0.16 + (_glowPulse.value * 0.08),
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF4500).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 3: Auth Form ─────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.cardPadding,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(AppTheme.cardPaddingLarge),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Logo / Brand Mark ──────────
                          AnimatedBuilder(
                            animation: _glowPulse,
                            builder: (context, child) => Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: AppColors.orangeGradient,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.solarOrange.withValues(
                                      alpha: 0.30 + (_glowPulse.value * 0.15),
                                    ),
                                    blurRadius: 24 + (_glowPulse.value * 10),
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: AppColors.solidWhite,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Title ──────────────────────
                          Text('OnyxFi', style: AppTheme.heading),
                          const SizedBox(height: 6),
                          Text(
                            _isLoginMode
                                ? 'Hesabınıza giriş yapın'
                                : 'Yeni hesap oluşturun',
                            style: AppTheme.body,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),

                          // ── Email Field ────────────────
                          _buildInputField(
                            controller: _emailCtrl,
                            hint: 'E-posta adresiniz',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'E-posta gereklidir';
                              }
                              if (!v.contains('@') || !v.contains('.')) {
                                return 'Geçerli bir e-posta girin';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // ── Password Field ─────────────
                          _buildInputField(
                            controller: _passwordCtrl,
                            hint: 'Şifreniz',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: AppColors.stoneGrey,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Şifre gereklidir';
                              }
                              if (v.length < 6) {
                                return 'Şifre en az 6 karakter olmalı';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // ── Confirm Password (Register only) ──
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _isLoginMode
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _buildInputField(
                                      controller: _confirmCtrl,
                                      hint: 'Şifrenizi onaylayın',
                                      icon: Icons.lock_outline_rounded,
                                      obscure: _obscureConfirm,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: AppColors.stoneGrey,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscureConfirm = !_obscureConfirm,
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v != _passwordCtrl.text) {
                                          return 'Şifreler eşleşmiyor';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                          ),

                          // ── Error Message ──────────────
                          if (auth.errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.crimsonPulse.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.crimsonPulse.withValues(alpha: 0.30),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.crimsonPulse,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      auth.errorMessage!,
                                      style: AppTheme.bodySm.copyWith(
                                        color: AppColors.crimsonPulse,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // ── Submit Button ──────────────
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.solarOrange,
                                foregroundColor: AppColors.solidWhite,
                                disabledBackgroundColor:
                                    AppColors.solarOrange.withValues(alpha: 0.40),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.pillRadius),
                                ),
                                elevation: 0,
                              ).copyWith(
                                overlayColor: WidgetStateProperty.all(
                                  AppColors.solidWhite.withValues(alpha: 0.10),
                                ),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.solidWhite,
                                      ),
                                    )
                                  : Text(
                                      _isLoginMode ? 'Giriş Yap' : 'Kayıt Ol',
                                      style: AppTheme.buttonLabel,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ── Toggle Login / Register ────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLoginMode
                                    ? 'Hesabınız yok mu?'
                                    : 'Zaten hesabınız var mı?',
                                style: AppTheme.bodySm,
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoginMode = !_isLoginMode;
                                    _confirmCtrl.clear();
                                  });
                                  // Clear any previous error
                                  context.read<AuthStateNotifier>()
                                    .signOut(); // Reset error state
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.solarOrange,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: Text(
                                  _isLoginMode ? 'Kayıt Olun' : 'Giriş Yapın',
                                  style: AppTheme.bodySm.copyWith(
                                    color: AppColors.solarOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable Glass Input Field ─────────────────────────
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: AppTheme.pillRadius,
      opacity: 0.04,
      borderWidth: 1.5,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: AppTheme.body.copyWith(color: AppColors.snowWhite),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.body.copyWith(color: AppColors.stoneGrey),
          prefixIcon: Icon(icon, color: AppColors.stoneGrey, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          errorStyle: TextStyle(
            color: AppColors.crimsonPulse,
            fontSize: 12,
            fontFamily: 'Inter',
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
