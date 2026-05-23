import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onyxfi_frontend/core/theme/app_theme.dart';
import 'package:onyxfi_frontend/views/auth_view.dart';
import 'package:onyxfi_frontend/views/onboarding_view.dart';
import 'package:onyxfi_frontend/views/dashboard_view.dart';
import 'package:onyxfi_frontend/models/onboarding_state.dart';
import 'package:onyxfi_frontend/models/auth_state.dart';

/// ──────────────────────────────────────────────────────────
/// OnyxFi — Agentic Personal Finance & Wealth Simulator
/// ──────────────────────────────────────────────────────────
/// Entry point. Loads environment variables, initializes
/// Supabase, registers Provider state management,
/// and applies the Midnight Ledger dark theme.
/// ──────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  // Initialize Supabase — must happen before any auth calls.
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      supabaseUrl != 'YOUR_SUPABASE_URL') {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      debugPrint('[Main] ✅ Supabase initialized.');
    } catch (e) {
      debugPrint('[Main] ❌ Supabase initialization failed: $e');
    }
  } else {
    debugPrint('[Main] ⚠️ Supabase credentials not set in .env — auth will not work.');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => OnboardingStateNotifier()),
        ChangeNotifierProvider(create: (_) => AuthStateNotifier()),
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
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthView(),
        '/onboarding': (context) => const OnboardingView(),
        '/': (context) => const OnboardingView(),
        '/dashboard': (context) => const DashboardView(),
      },
    );
  }
}
