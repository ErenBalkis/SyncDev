import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:genui/genui.dart' as genui;
import 'package:genui/genui.dart' hide ChatMessage;
import 'package:onyxfi_frontend/main.dart';
import 'package:onyxfi_frontend/core/constants/colors.dart';
import 'package:onyxfi_frontend/core/theme/app_theme.dart';
import 'package:onyxfi_frontend/widgets/glass_container.dart';
import 'package:onyxfi_frontend/core/network/gemini_client.dart';
import 'package:onyxfi_frontend/core/network/api_client.dart';
import 'package:onyxfi_frontend/catalog/component_registry.dart';
import 'package:onyxfi_frontend/models/auth_state.dart';
import 'package:onyxfi_frontend/models/onboarding_state.dart';

/// ──────────────────────────────────────────────────────────
/// OnyxFi — Onboarding View (Ambient Transparent Glass)
/// ──────────────────────────────────────────────────────────
/// Stack layout:
///   Layer 0 — Dynamic background image (Black & Orange abstract)
///   Layer 1 — Legibility overlay (dark, moderate opacity)
///   Layer 2 — Ambient Solar Orange glow accents
///   Layer 3 — SafeArea with transparent glass UI
/// ──────────────────────────────────────────────────────────
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});
  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int _currentStep = 0;
  bool _isLoading = false;

  // GenUI Infrastructure
  late final SurfaceController _surfaceController;
  late final Conversation _conversation;
  
  String? _currentSurfaceId;
  String _currentAiText = '';

  @override
  void initState() {
    super.initState();
    
    final adapter = GeminiClient().buildTransportAdapter();
    _surfaceController = SurfaceController(
      catalogs: [OnyxCatalog.buildCatalog(onSubmit: _handleNextStep)],
    );
    _conversation = Conversation(
      controller: _surfaceController,
      transport: adapter,
    );

    _conversation.events.listen((event) {
      if (!mounted) return;
      debugPrint('[Onboarding] Event: ${event.runtimeType}');
      if (event is ConversationSurfaceAdded) {
        debugPrint('[Onboarding] ✅ Surface added: ${event.surfaceId}');
        setState(() => _currentSurfaceId = event.surfaceId);
      } else if (event is ConversationSurfaceRemoved) {
        debugPrint('[Onboarding] Surface removed: ${event.surfaceId}');
        if (_currentSurfaceId == event.surfaceId) {
          setState(() => _currentSurfaceId = null);
        }
      } else if (event is ConversationContentReceived) {
        debugPrint('[Onboarding] Text received: "${event.text.substring(0, event.text.length.clamp(0, 80))}"');
        setState(() => _currentAiText = event.text);
      } else if (event is ConversationComponentsUpdated) {
        debugPrint('[Onboarding] ✅ Components updated on: ${event.surfaceId}');
        // Re-render the surface if it's the current one
        if (_currentSurfaceId == event.surfaceId) {
          setState(() {});
        }
      } else if (event is ConversationWaiting) {
        debugPrint('[Onboarding] ⏳ Waiting for AI...');
        setState(() {
          _isLoading = true;
          _currentSurfaceId = null; // Clear surface between steps
          _currentAiText = '';
        });
      } else if (event is ConversationError) {
        debugPrint('[Onboarding] ❌ Error: ${event.error}');
        setState(() {
          _isLoading = false;
          _currentAiText = 'Bir hata oluştu: ${event.error}';
        });
      }
    });

    _conversation.state.addListener(() {
      if (!mounted) return;
      if (!_conversation.state.value.isWaiting && _isLoading) {
        setState(() {
          _isLoading = false;
          if (_currentStep < 4) _currentStep++;
        });
      }
    });
  }

  Future<void> _handleNextStep([String? userInput]) async {
    if (_isLoading) return;
    final prompt = userInput ?? 
      'Kullanıcı onboarding sürecini başlattı. Lütfen GoalSelectionCard '
      'widget\'ını iki adımlı A2UI protokolü ile (createSurface + updateComponents) '
      'render ederek finansal hedeflerini sor.';
      
    debugPrint('[Onboarding] Sending prompt: "${prompt.substring(0, prompt.length.clamp(0, 80))}"');
    await _conversation.sendRequest(genui.ChatMessage.user(prompt));
  }

  /// Sends onboarding data + auth UUID to FastAPI backend,
  /// then navigates to the dashboard.
  Future<void> _completeOnboarding() async {
    final auth = context.read<AuthStateNotifier>();
    final onboarding = context.read<OnboardingStateNotifier>();

    // Only attempt API call if we have an authenticated user
    if (auth.userId != null) {
      try {
        await ApiClient().createProfile(
          userId: auth.userId!,
          monthlyIncome: onboarding.monthlySalary ?? 0,
          currentSavings: onboarding.currentSavings ?? 0,
          monthlyExpenses: onboarding.monthlyExpenses ?? 0,
        );
        debugPrint('[Onboarding] ✅ Profile created via FastAPI.');
      } on ApiException catch (e) {
        debugPrint('[Onboarding] ❌ Profile creation failed: ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.message,
                style: AppTheme.bodySm.copyWith(color: AppColors.snowWhite),
              ),
              backgroundColor: AppColors.deepSlate,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('[Onboarding] ❌ Unexpected error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profil kaydedilemedi. İnternet bağlantınızı kontrol edin.',
                style: AppTheme.bodySm.copyWith(color: AppColors.snowWhite),
              ),
              backgroundColor: AppColors.deepSlate,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } else {
      debugPrint('[Onboarding] ⚠️ No authenticated user — skipping profile creation.');
    }

    // Navigate to dashboard regardless of API result
    if (mounted) {
      context.read<AppState>().completeOnboarding();
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgImage = context.watch<AppState>().backgroundImage;

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
            top: -80, left: -80,
            child: Container(
              width: 380, height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.solarOrange.withValues(alpha: 0.20), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120, right: -80,
            child: Container(
              width: 420, height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFFFF4500).withValues(alpha: 0.14), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Layer 3: UI Content ─────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Column(children: [
                _buildProgressBar(),
                const SizedBox(height: 32),
                Expanded(
                  child: Center(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(AppTheme.cardPaddingLarge),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_currentStep == 0) ...[
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                gradient: AppColors.orangeGradient,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [AppColors.orangeGlow],
                              ),
                              child: const Icon(Icons.auto_awesome, color: AppColors.solidWhite, size: 36),
                            ),
                            const SizedBox(height: 24),
                            Text('Merhaba! 👋', style: AppTheme.heading),
                            const SizedBox(height: 12),
                            Text(
                              'Finansal hedefleriniz belirleyelim ve size özel bir plan oluşturalım.',
                              style: AppTheme.body, textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _isLoading ? null : () => _handleNextStep(),
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.solidWhite))
                                  : const Text('Başlayalım'),
                            ),
                          ] else ...[
                            if (_isLoading)
                              const CircularProgressIndicator(color: AppColors.solarOrange)
                            else if (_currentSurfaceId != null)
                              Surface(surfaceContext: _surfaceController.contextFor(_currentSurfaceId!))
                            else if (_currentAiText.isNotEmpty)
                              Text(_currentAiText, style: AppTheme.body)
                            else
                              Text('Beklenmeyen bir hata oluştu.', style: AppTheme.body),
                            
                            const SizedBox(height: 32),
                            if (!_isLoading)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => _completeOnboarding(),
                                    child: const Text('Atla'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _handleNextStep('Devam et'),
                                    child: const Text('Devam'),
                                  ),
                                ],
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(
        4,
        (index) => Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: index <= _currentStep ? AppColors.solarOrange : AppColors.frostBorder,
              borderRadius: BorderRadius.circular(2),
              boxShadow: index <= _currentStep ? [BoxShadow(color: AppColors.solarOrange.withValues(alpha: 0.45), blurRadius: 8)] : [],
            ),
          ),
        ),
      ),
    );
  }
}
