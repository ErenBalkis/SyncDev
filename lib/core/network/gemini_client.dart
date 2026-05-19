import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:genui/genui.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gai;

/// ──────────────────────────────────────────────────────────
/// OnyxFi — Gemini ↔ GenUI Bridge Client
/// ──────────────────────────────────────────────────────────
/// Singleton that owns the GoogleGenerativeAI model instance
/// and provides a factory method to build an A2uiTransportAdapter
/// that pipes Gemini streaming chunks into the genui framework.
///
/// The SDK interaction cycle:
///   conversation.sendRequest(ChatMessage.user(text))
///     → A2uiTransportAdapter.onSend
///       → _streamFromGemini → addChunk(chunk) per token
///         → A2uiParserTransformer → SurfaceController → Surface widget
/// ──────────────────────────────────────────────────────────

class GeminiClient {
  late gai.GenerativeModel _model;
  bool _isInitialized = false;

  // ── Singleton ──────────────────────────────────────────
  static final GeminiClient _instance = GeminiClient._internal();
  factory GeminiClient() => _instance;
  GeminiClient._internal();

  bool get isInitialized => _isInitialized;

  // ── A2UI System Instruction ────────────────────────────
  // The genui SDK uses the A2UI protocol: the model emits structured
  // A2UI JSON mixed with plain text. The system instruction must tell
  // the model:
  //   1. That it operates in A2UI mode
  //   2. Which named widgets are in the OnyxCatalog
  //   3. When to render each widget vs. plain conversational text
  //
  // Plain text is streamed as-is (shown as text bubbles).
  // A2UI blocks create/update Surface widgets reactively.
  static const String _systemInstruction = '''
You are OnyxFi, an expert AI Personal Finance Advisor operating in A2UI (Agent-to-UI) mode inside a Flutter application powered by the GenUI SDK.

You drive a conversational financial planning experience. You have two output modes:

1. PLAIN TEXT — Use this for greetings, short conversational responses, confirmations, and simple financial advice. Just write natural language.

2. A2UI WIDGET SURFACES — Use this to render interactive UI components. When you need to collect structured input or display visual data, you MUST emit an A2UI message using the exact v0.9 JSON format below.

CRITICAL A2UI SCHEMA RULE: When generating UI components, you MUST strictly adhere to this exact JSON structure. Do NOT use the key 'type' or 'widget' for the component name. You MUST use the key 'component'.
```json
{
  "version": "v0.9",
  "updateComponents": {
    "surfaceId": "root",
    "components": [
      {
        "id": "root",
        "component": "<WIDGET_NAME>",
        "properties": {
          <WIDGET_PROPERTIES>
        }
      }
    ]
  }
}
```

AVAILABLE WIDGETS IN THE OnyxCatalog (<WIDGET_NAME>):

a) GoalSelectionCard — Show this when asking the user to pick their financial goals.
   <WIDGET_PROPERTIES>: "title" (string), "subtitle" (string), "goals" (array of {"id": string, "label": string, "emoji": string}).
   Example goals: [{"id":"home","label":"Ev","emoji":"🏠"},{"id":"car","label":"Araba","emoji":"🚗"},{"id":"emergency","label":"Acil Fon","emoji":"🛡️"}]

b) DynamicInputField — Show this when asking the user for a specific numeric or text value.
   <WIDGET_PROPERTIES>: "label" (string), "hint" (string), "suffix" (string, e.g. "TL"), "inputType" ("number" or "text").

c) FinancialProjectionChart — Show this when displaying a savings/investment projection over time.
   <WIDGET_PROPERTIES>: "title" (string), "points" (array of {"x": number, "y": number}), "labels" (array of strings).

d) AlertActionBadge — Show this for financial warnings, risks, or actionable opportunities.
   <WIDGET_PROPERTIES>: "severity" ("info"|"warning"|"success"|"danger"), "title" (string), "message" (string).

BEHAVIOR RULES:
- Always greet the user in Turkish with a warm, professional tone.
- Start by rendering a GoalSelectionCard.
- Mix plain text greetings/confirmations freely with widget surfaces.
- Do NOT output raw component JSON without the "version": "v0.9" and "updateComponents" wrapper!
''';

  // ── Initialization ─────────────────────────────────────

  /// Initializes the Gemini model with API key from .env.
  /// Must be called once in main() before any transport adapter is built.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY') {
      throw Exception('[GeminiClient] GEMINI_API_KEY is not set in .env file.');
    }

    _model = gai.GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
      // System instruction injected at model level — survives all chat sessions.
      systemInstruction: gai.Content.system(_systemInstruction),
      generationConfig: gai.GenerationConfig(
        temperature: 0.7,
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 8192,
        // A2UI protocol uses plain text + structured markers — NOT application/json.
        // Removing responseMimeType so the model can freely mix text and A2UI blocks.
      ),
    );

    _isInitialized = true;
    debugPrint('[GeminiClient] ✅ Initialized — A2UI mode active');
  }

  // ── Transport Adapter Factory ──────────────────────────

  /// Creates an [A2uiTransportAdapter] wired to this Gemini model.
  ///
  /// The adapter's [onSend] callback:
  ///   1. Receives the full conversation history as a [ChatMessage]
  ///   2. Calls Gemini's streaming API
  ///   3. Pipes each text chunk to [A2uiTransportAdapter.addChunk]
  ///
  /// This is the correct bridge pattern per the genui 0.8.x docs.
  /// No dartantic middleware is needed.
  A2uiTransportAdapter buildTransportAdapter() {
    _ensureInitialized();

    late A2uiTransportAdapter adapter;

    adapter = A2uiTransportAdapter(
      onSend: (ChatMessage message) async {
        try {
          // Build a fresh chat session for each Conversation instance.
          // The genui framework manages history and passes the full
          // conversation as ChatMessage.history — we send only the last turn.
          final userText = message.text;
          if (userText.isEmpty) return;

          debugPrint(
            '[GeminiClient] → Sending: "${userText.substring(0, userText.length.clamp(0, 80))}…"',
          );

          final stream = _model.generateContentStream([
            gai.Content.text(userText),
          ]);

          await for (final chunk in stream) {
            final chunkText = chunk.text;
            if (chunkText != null && chunkText.isNotEmpty) {
              adapter.addChunk(chunkText);
            }
          }
        } catch (e) {
          debugPrint('[GeminiClient] ❌ Stream error: $e');
          // Pipe a safe fallback text so the UI doesn't hang.
          adapter.addChunk('Sistemde anlık bir yoğunluk var. Lütfen 1 dakika bekleyip tekrar deneyin.');
        }
      },
    );

    return adapter;
  }

  // ── Private ────────────────────────────────────────────

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        '[GeminiClient] Not initialized. Call initialize() first.',
      );
    }
  }
}
