import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onyxfi_frontend/main.dart';
import 'package:onyxfi_frontend/core/constants/colors.dart';
import 'package:onyxfi_frontend/core/theme/app_theme.dart';
import 'package:onyxfi_frontend/widgets/glass_container.dart';
import 'package:onyxfi_frontend/core/network/gemini_client.dart';
import 'package:onyxfi_frontend/catalog/component_registry.dart';

/// Onboarding View — Midnight Ledger Dark Theme.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});
  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int _currentStep = 0;
  bool _isLoading = false;
  Map<String, dynamic>? _genUIPayload;

  Future<void> _handleNextStep([String? userInput]) async {
    setState(() => _isLoading = true);
    try {
      final prompt = userInput ?? 'Kullanıcı onboarding sürecini başlattı. Lütfen hedeflerini sormak için uygun componenti döndür.';
      final payload = await GeminiClient().sendAndParseGenUI(prompt);
      if (mounted) {
        setState(() {
          _genUIPayload = GeminiClient.toRegistryFormat(payload);
          if (_genUIPayload == null && payload['component_type'] == 'text_only') {
            _genUIPayload = {'type': 'alert_badge', 'data': {'severity': 'info', 'title': 'OnyxFi AI', 'message': payload['message']}};
          }
          _currentStep++;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgImage = context.watch<AppState>().backgroundImage;

    return Scaffold(
      body: Stack(
        children: [
          // Layer 0: Background Image
          Positioned.fill(
            child: Image.asset(
              bgImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(gradient: AppColors.midnightGradient),
              ),
            ),
          ),
          // Layer 1: Dark legibility mask overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.midnightInk.withValues(alpha: 0.85),
                    AppColors.midnightInk.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),
          // Layer 2: Ambient glow & UI Content
          Positioned(top: -80, left: -80, child: Container(width: 350, height: 350, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.electricBlue.withValues(alpha: 0.1), Colors.transparent])))),
          Positioned(bottom: -120, right: -80, child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.growthMint.withValues(alpha: 0.06), Colors.transparent])))),

          SafeArea(child: Padding(padding: const EdgeInsets.all(AppTheme.cardPadding), child: Column(children: [
            _buildProgressBar(),
            const SizedBox(height: 32),
            Expanded(child: Center(child: GlassContainer(
              padding: const EdgeInsets.all(AppTheme.cardPaddingLarge),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_currentStep == 0) ...[
                  Text('Merhaba! 👋', style: AppTheme.heading),
                  const SizedBox(height: 12),
                  Text('Finansal hedeflerinizi belirleyelim ve size özel bir plan oluşturalım.', style: AppTheme.body, textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleNextStep(),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.solidWhite))
                        : const Text('Başlayalım'),
                  ),
                ] else ...[
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator(color: AppColors.electricBlue))
                  else if (_genUIPayload != null)
                    ComponentRegistry.build(
                      _genUIPayload!,
                      onSubmit: (msg) => _handleNextStep(msg),
                    )
                  else
                    const Text('Beklenmeyen bir hata oluştu.'),
                  const SizedBox(height: 32),
                  if (!_isLoading) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    OutlinedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'), child: const Text('Atla')),
                    ElevatedButton(onPressed: () => _handleNextStep('Devam et'), child: const Text('Devam')),
                  ]),
                ],
              ]),
            ))),
          ]))),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(children: List.generate(4, (index) => Expanded(child: Container(
      height: 4, margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: index <= _currentStep ? AppColors.electricBlue : AppColors.stoneGrey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
        boxShadow: index <= _currentStep ? [BoxShadow(color: AppColors.electricBlue.withValues(alpha: 0.4), blurRadius: 6)] : [],
      ),
    ))));
  }
}
