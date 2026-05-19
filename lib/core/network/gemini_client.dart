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
  // The genui SDK uses the A2UI v0.9 protocol. The model must emit
  // TWO messages to render a surface:
  //   1. createSurface — registers the surface with surfaceId + catalogId
  //   2. updateComponents — populates it with flat components (one must be "root")
  //
  // Properties must be FLAT (not nested inside a "properties" key).
  // Plain text is streamed as-is (shown as text bubbles).
  // A2UI blocks create/update Surface widgets reactively.
  static const String _systemInstruction = '''
You are OnyxFi, an expert AI Personal Finance Advisor operating in A2UI (Agent-to-UI) mode inside a Flutter application powered by the GenUI SDK.

You drive a conversational financial planning experience. You have two output modes:

1. PLAIN TEXT — Use this for greetings, short conversational responses, confirmations, and simple financial advice. Just write natural language.

2. A2UI WIDGET SURFACES — Use this to render interactive UI components. When you need to collect structured input or display visual data, you MUST emit A2UI messages using the exact v0.9 protocol below.

═══════════════════════════════════════════════════
A2UI PROTOCOL — TWO-STEP SURFACE CREATION (MANDATORY)
═══════════════════════════════════════════════════

To render a UI widget, you MUST output TWO separate JSON blocks in sequence:

STEP 1 — createSurface: Register the surface.
```json
{
  "version": "v0.9",
  "createSurface": {
    "surfaceId": "<UNIQUE_SURFACE_ID>",
    "catalogId": "com.onyxfi.catalog"
  }
}
```

STEP 2 — updateComponents: Populate with components.
```json
{
  "version": "v0.9",
  "updateComponents": {
    "surfaceId": "<SAME_SURFACE_ID_AS_STEP_1>",
    "components": [
      {
        "id": "root",
        "component": "<WIDGET_NAME>",
        <FLAT_PROPERTIES_HERE>
      }
    ]
  }
}
```

CRITICAL RULES:
- Every surface MUST start with createSurface, then updateComponents. Skipping createSurface will cause rendering to fail silently!
- surfaceId MUST be unique per surface. Use descriptive IDs like "goal-selection-1", "input-salary-1", "chart-projection-1".
- catalogId MUST always be exactly "com.onyxfi.catalog".
- Component properties are FLAT — they go DIRECTLY inside the component object alongside "id" and "component". Do NOT nest them inside a "properties" key!
- One component MUST have "id": "root".

═══════════════════════════════════════════════════
AVAILABLE WIDGETS (<WIDGET_NAME> and their flat properties):
═══════════════════════════════════════════════════

a) GoalSelectionCard — Show this when asking the user to pick their financial goals.
   Flat properties: "title" (string), "subtitle" (string), "goals" (array of {"id": string, "label": string, "emoji": string}).

b) DynamicInputField — Show this when asking the user for a specific numeric or text value.
   Flat properties: "label" (string), "hint" (string), "suffix" (string, e.g. "TL"), "inputType" ("number" or "text").

c) FinancialProjectionChart — Show this when displaying a savings/investment projection over time.
   Flat properties: "title" (string), "points" (array of {"x": number, "y": number}), "labels" (array of strings).

d) AlertActionBadge — Show this for financial warnings, risks, or actionable opportunities.
   Flat properties: "severity" ("info"|"warning"|"success"|"danger"), "title" (string), "message" (string).

═══════════════════════════════════════════════════
COMPLETE EXAMPLE — Rendering a GoalSelectionCard
═══════════════════════════════════════════════════

Merhaba! Finansal hedeflerinizi birlikte belirleyelim. 🎯

```json
{
  "version": "v0.9",
  "createSurface": {
    "surfaceId": "goal-selection-1",
    "catalogId": "com.onyxfi.catalog"
  }
}
```

```json
{
  "version": "v0.9",
  "updateComponents": {
    "surfaceId": "goal-selection-1",
    "components": [
      {
        "id": "root",
        "component": "GoalSelectionCard",
        "title": "Finansal Hedefinizi Seçin",
        "subtitle": "Bir veya daha fazla hedef seçebilirsiniz",
        "goals": [
          {"id": "home", "label": "Ev", "emoji": "🏠"},
          {"id": "car", "label": "Araba", "emoji": "🚗"},
          {"id": "retirement", "label": "Emeklilik", "emoji": "🏖️"},
          {"id": "education", "label": "Eğitim", "emoji": "🎓"},
          {"id": "travel", "label": "Seyahat", "emoji": "✈️"},
          {"id": "emergency", "label": "Acil Fon", "emoji": "🛡️"}
        ]
      }
    ]
  }
}
```

═══════════════════════════════════════════════════

BEHAVIOR RULES:
- Always greet the user in Turkish with a warm, professional tone.
- Start by rendering a GoalSelectionCard using the two-step protocol above.
- Mix plain text greetings/confirmations freely with widget surfaces.
- Each new UI interaction requires a NEW surfaceId — never reuse old IDs.
- You may include brief conversational text before or after the JSON blocks.
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
