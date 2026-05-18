import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// ──────────────────────────────────────────────────────────
/// OnyxFi — Gemini API Client (GenUI Orchestrator)
/// ──────────────────────────────────────────────────────────
/// Singleton client that manages the Gemini API connection.
///
/// • Model: gemini-3-flash-preview
/// • System Instruction: Injected at init — forces the model
///   to always return strict GenUI JSON payloads.
/// • Response format: application/json
/// • All responses are parsed and validated before reaching
///   the ComponentRegistry to prevent runtime crashes.
/// ──────────────────────────────────────────────────────────

class GeminiClient {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  bool _isInitialized = false;

  // ── Singleton ──────────────────────────────────────────
  static final GeminiClient _instance = GeminiClient._internal();
  factory GeminiClient() => _instance;
  GeminiClient._internal();

  /// Whether the client has been successfully initialized.
  bool get isInitialized => _isInitialized;

  // ── System Instruction ─────────────────────────────────
  // This is the core prompt that turns Gemini into our
  // GenUI orchestrator. It MUST return valid JSON only.
  static const String _systemInstruction = '''
You are OnyxFi, an expert AI Personal Finance Advisor and UI Orchestrator. 
You do not interact with users using plain conversational text alone. Instead, you drive a Generative UI (GenUI) Flutter application. 
Every response you generate MUST be a valid, minified JSON object. Do not include markdown formatting (like ```json), do not include introductory or concluding text. ONLY output the JSON object.

Your goal is to guide the user through their financial journey by triggering the correct UI components in the Flutter frontend.

You have access to the following UI components in the app's catalog. Always choose the most appropriate one based on the conversation context:

1. "text_only": Used for basic conversational replies, greetings, or simple advice.
2. "goal_selection": Used ONLY when asking the user about their primary financial goals (e.g., House, Car, Retirement).
3. "dynamic_input": Used when you need the user to input a specific number (e.g., "What is your monthly salary?" or "How much do you pay for rent?").
4. "projection_chart": Used when the user asks for a visual projection, forecast, or breakdown of their budget/savings over time.
5. "alert_badge": Used when you detect a critical financial risk (e.g., "Warning: High credit card debt") or an actionable opportunity.

REQUIRED JSON RESPONSE STRUCTURE:
{
  "component_type": "<Choose ONE from the 5 options above>",
  "message": "<Your conversational response or instruction to the user>",
  "data": <Specific data required for the chosen component, or null if not needed>
}

DATA STRUCTURE EXAMPLES:
- For "goal_selection": "data": {"options": ["Buy a House", "Retirement", "Buy a Car", "Travel", "Emergency Fund"]}
- For "dynamic_input": "data": {"input_type": "number", "placeholder": "e.g., 5000", "currency": "USD"}
- For "projection_chart": "data": {"chart_type": "line", "x_axis": ["Jan", "Feb", "Mar"], "y_axis_label": "Balance", "series": [{"name": "Savings", "values": [1000, 2000, 3500]}]}
- For "text_only": "data": null
''';

  // ── Initialization ─────────────────────────────────────

  /// Initializes the Gemini model with API key from .env,
  /// injects the System Instruction, and starts a chat session.
  ///
  /// Must be called once before any [sendMessage] calls.
  /// Throws an [Exception] if the API key is missing.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY') {
      throw Exception(
        '[GeminiClient] GEMINI_API_KEY is not set. '
        'Please add your key to the .env file.',
      );
    }

    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,

      // System Instruction — injected as Content so the model
      // always behaves as our GenUI orchestrator.
      systemInstruction: Content.system(_systemInstruction),

      generationConfig: GenerationConfig(
        temperature: 0.7,
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 8192,
        // Force JSON-only output — no markdown wrapping.
        responseMimeType: 'application/json',
      ),

      // NOTE on Thinking Config:
      // The Python SDK supports `thinking_config: ThinkingConfig(thinking_level="HIGH")`
      // but the current Dart `google_generative_ai` package (v0.4.x) does not yet
      // expose a `thinkingConfig` parameter in GenerativeModel or GenerationConfig.
      // When the Dart SDK adds support, enable it here:
      // thinkingConfig: ThinkingConfig(thinkingLevel: ThinkingLevel.high),
    );

    // Start a persistent chat session to maintain conversation context.
    _chat = _model.startChat();
    _isInitialized = true;

    debugPrint('[GeminiClient] ✅ Initialized with gemini-3-flash-preview');
  }

  // ── Core Messaging ─────────────────────────────────────

  /// Sends a raw user message and returns the model's text response.
  ///
  /// The response should always be a JSON string thanks to the
  /// System Instruction + `responseMimeType: 'application/json'`.
  Future<String> sendMessage(String message) async {
    _ensureInitialized();

    final response = await _chat.sendMessage(Content.text(message));
    final text = response.text;

    if (text == null || text.isEmpty) {
      debugPrint('[GeminiClient] ⚠️ Empty response from model.');
      return '{"component_type": "text_only", "message": "Bir hata oluştu, lütfen tekrar deneyin.", "data": null}';
    }

    return text;
  }

  // ── GenUI JSON Parsing ─────────────────────────────────

  /// Sends a message and parses the JSON response into a
  /// structured Map ready for [ComponentRegistry.build()].
  ///
  /// Returns a fallback "text_only" payload if parsing fails,
  /// ensuring the UI never crashes during the hackathon demo.
  Future<Map<String, dynamic>> sendAndParseGenUI(String message) async {
    try {
      final responseText = await sendMessage(message);
      final decoded = jsonDecode(responseText);

      if (decoded is Map<String, dynamic>) {
        // Validate that the required keys exist.
        if (!decoded.containsKey('component_type')) {
          debugPrint('[GeminiClient] ⚠️ Missing "component_type" in response.');
          return _fallbackPayload(
            decoded['message'] as String? ?? responseText,
          );
        }
        return decoded;
      }

      debugPrint('[GeminiClient] ⚠️ Response is not a JSON object.');
      return _fallbackPayload(responseText);
    } catch (e) {
      debugPrint('[GeminiClient] ❌ Parse error: $e');
      return _fallbackPayload('Yanıt işlenirken bir hata oluştu.');
    }
  }

  /// Extracts the `component_type` from a parsed GenUI payload.
  /// Maps it to the catalog type expected by [ComponentRegistry].
  ///
  /// Mapping:
  /// - "goal_selection" → "goal_selection"
  /// - "dynamic_input"  → "dynamic_input"
  /// - "projection_chart" → "projection_chart"
  /// - "alert_badge"    → "alert_badge"
  /// - "text_only"      → null (render as plain chat bubble)
  static String? extractComponentType(Map<String, dynamic> payload) {
    final type = payload['component_type'] as String?;
    if (type == null || type == 'text_only') return null;
    return type;
  }

  /// Extracts the conversational message text from a GenUI payload.
  static String extractMessage(Map<String, dynamic> payload) {
    return payload['message'] as String? ?? '';
  }

  /// Extracts the component data from a GenUI payload.
  /// Returns null if the component is "text_only".
  static Map<String, dynamic>? extractData(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  /// Convenience method: Converts a GenUI payload into the format
  /// expected by ComponentRegistry ({"type": ..., "data": ...}).
  static Map<String, dynamic>? toRegistryFormat(
    Map<String, dynamic> payload,
  ) {
    final componentType = extractComponentType(payload);
    if (componentType == null) return null; // text_only, no widget needed.

    return {
      'type': componentType,
      'data': extractData(payload) ?? {},
    };
  }

  // ── Chat Session Management ────────────────────────────

  /// Resets the chat session, clearing all conversation history.
  /// Useful when the user restarts the onboarding flow.
  void resetChat() {
    _ensureInitialized();
    _chat = _model.startChat();
    debugPrint('[GeminiClient] 🔄 Chat session reset.');
  }

  // ── Private Helpers ────────────────────────────────────

  /// Ensures the client is initialized before any API call.
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        '[GeminiClient] Not initialized. Call initialize() first.',
      );
    }
  }

  /// Creates a safe fallback payload so the UI always has
  /// something to render, even when the API response is malformed.
  static Map<String, dynamic> _fallbackPayload(String message) {
    return {
      'component_type': 'text_only',
      'message': message,
      'data': null,
    };
  }
}
