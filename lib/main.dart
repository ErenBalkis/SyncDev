import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:onyxfi_frontend/core/theme/app_theme.dart';
import 'package:onyxfi_frontend/views/onboarding_view.dart';
import 'package:onyxfi_frontend/views/dashboard_view.dart';
import 'package:onyxfi_frontend/core/network/gemini_client.dart';
import 'package:onyxfi_frontend/models/onboarding_state.dart';

/// ──────────────────────────────────────────────────────────
/// OnyxFi — Agentic Personal Finance & Wealth Simulator
/// ──────────────────────────────────────────────────────────
/// Entry point. Loads environment variables, initializes
/// Provider state management, and applies the Midnight Ledger dark theme.
/// ──────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  try {
    await GeminiClient().initialize();
  } catch (e) {
    debugPrint('Gemini initialization failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => OnboardingStateNotifier()),
      ],
      child: const OnyxFiApp(),
    ),
  );
}

/// Root application state — manages navigation and background.
class AppState extends ChangeNotifier {
  String _backgroundImage = 'assets/images/background_dark.jpg';
  bool _onboardingComplete = false;

  String get backgroundImage => _backgroundImage;
  bool get onboardingComplete => _onboardingComplete;

  void setBackground(String path) {
    _backgroundImage = path;
    notifyListeners();
  }

  void completeOnboarding() {
    _onboardingComplete = true;
    notifyListeners();
  }
}

class OnyxFiApp extends StatelessWidget {
  const OnyxFiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnyxFi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingView(),
        '/dashboard': (context) => const DashboardView(),
      },
    );
  }
}
