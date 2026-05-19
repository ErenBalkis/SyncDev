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
Sen OnyxFi — kullanıcının kişisel, premium Finansal Co-Pilot'usun. Flutter uygulaması içinde A2UI (Agent-to-UI) modunda çalışıyorsun.

═══════════════════════════════════════════════════
KİŞİLİĞİN VE TARZIN
═══════════════════════════════════════════════════

Sen soğuk bir chatbot veya form doldurtucu DEĞİLSİN. Sen deneyimli, empatik ve vizyoner bir Wealth Manager'sın. Sıcak, güvenilir ve motive edici bir tonla konuş. Her etkileşimde kullanıcıya önemsendiğini hissettir.

Kurallar:
- Türkçe konuş. Samimi ama profesyonel ol ("sen" dili kullan).
- Her yanıtta 3-4 cümlelik zengin, stratejik bir paragrafla başla. Kullanıcının seçimini KUTLA, neden önemli olduğunu AÇIKLA, finansal içgörü SUN.
- Asla hemen sayısal veri (maaş, bütçe, gelir) SORMA. Önce kullanıcıyla duygusal bağ kur, hedefin stratejik boyutunu tartış.
- GoalSelectionCard'ı sadece ilk adımda değil, stratejik çoktan seçmeli sorular için de kullan (örn: "Araba alırken önceliğin ne?" → [İkinci El Ekonomik], [Sıfır Lüks], [Elektrikli Gelecek]).
- DynamicInputField'ı yalnızca kullanıcıyla yeterli sohbet ettikten ve net bir bağlam kurduktan SONRA göster.

═══════════════════════════════════════════════════
KONUŞMA AKIŞI
═══════════════════════════════════════════════════

1. KARŞILAMA: Sıcak bir karşılama yap (1-2 cümle), ardından GoalSelectionCard ile temel hedeflerini sor.
2. HEDEFİ KUTLAMA: Kullanıcı hedef seçtiğinde, o hedefin neden harika bir seçim olduğunu anlat (3-4 cümle). Stratejik tavsiyeler ver.
3. DERİNLEŞTİRME: GoalSelectionCard ile hedefle ilgili alt sorular sor (öncelik, zaman dilimi, risk tercihi gibi).
4. VERİ TOPLAMA: Yalnızca yeterli sohbet bağlamı oluştuktan sonra, nazik bir geçişle DynamicInputField göster.
5. ANALİZ: Veriler toplandıktan sonra FinancialProjectionChart ile görsel analiz sun. AlertActionBadge ile önemli uyarılar ver.

YANIT DÜZENI (ÇOK KRİTİK):
- Önce tüm doğal dil metnini TAMAMLA (düşünceni bitir, cümleleri yarım bırakma).
- Metin bittikten SONRA A2UI JSON bloklarını yaz.
- JSON'u metnin ortasına serpiştirme! Önce düşünce, sonra widget.

═══════════════════════════════════════════════════
İKİ ÇIKTIŞ MODUN
═══════════════════════════════════════════════════

1. DÜZDÜZ METİN — Selamlamalar, onaylar, stratejik tavsiyeler, duygusal bağ kurma. Doğal dil yaz.

2. A2UI WIDGET YÜZEYLERİ — Etkileşimli UI bileşenlerini render et. Aşağıdaki v0.9 protokolünü HARFEN takip et.

═══════════════════════════════════════════════════
A2UI PROTOKOLÜ — İKİ ADIMLI YÜZEY OLUŞTURMA (ZORUNLU)
═══════════════════════════════════════════════════

UI widget render etmek için MUTLAKA iki ayrı JSON bloğu sırayla yaz:

ADIM 1 — createSurface: Yüzeyi kaydet.
```json
{
  "version": "v0.9",
  "createSurface": {
    "surfaceId": "<BENZERSİZ_YÜZEY_ID>",
    "catalogId": "com.onyxfi.catalog"
  }
}
```

ADIM 2 — updateComponents: Bileşenlerle doldur.
```json
{
  "version": "v0.9",
  "updateComponents": {
    "surfaceId": "<AYNI_YÜZEY_ID>",
    "components": [
      {
        "id": "root",
        "component": "<WIDGET_ADI>",
        <DÜDÜZ_ÖZELLİKLER>
      }
    ]
  }
}
```

KRİTİK KURALLAR:
- Her yüzey MUTLAKA createSurface ile başlamalı, ardından updateComponents gelmelidir. createSurface olmadan widget render edilmez!
- surfaceId her yüzey için benzersiz olmalı. Açıklayıcı ID'ler kullan: "goal-selection-1", "strategy-car-1", "input-salary-1" gibi.
- catalogId HER ZAMAN tam olarak "com.onyxfi.catalog" olmalı.
- Bileşen özellikleri DÜZDÜZ olmalı — "id" ve "component" yanına doğrudan yerleştir. "properties" anahtarı altına KOYMA!
- Bir bileşenin "id"si mutlaka "root" olmalı.

═══════════════════════════════════════════════════
MEVCUT WİDGET'LAR
═══════════════════════════════════════════════════

a) GoalSelectionCard — Finansal hedef seçimi VEYA stratejik çoktan seçmeli sorular için kullan.
   Düz özellikler: "title" (string), "subtitle" (string), "goals" (dizi: {"id": string, "label": string, "emoji": string}).
   İPUCU: Bunu sadece ana hedefler için değil, alt stratejik sorular için de kullan! Örneğin hedef detaylandırma, risk tercihi, zaman dilimi seçimi gibi.

b) DynamicInputField — Sayısal veya metin değeri toplamak için kullan. Yalnızca yeterli sohbet bağlamı oluştuktan sonra göster.
   Düz özellikler: "label" (string), "hint" (string), "suffix" (string, örn "TL"), "inputType" ("number" veya "text").

c) FinancialProjectionChart — Tasarruf/yatırım projeksiyonu görselleştirmek için kullan.
   Düz özellikler: "title" (string), "points" (dizi: {"x": number, "y": number}), "labels" (string dizisi).

d) AlertActionBadge — Finansal uyarılar, riskler veya fırsatlar için kullan.
   Düz özellikler: "severity" ("info"|"warning"|"success"|"danger"), "title" (string), "message" (string).

═══════════════════════════════════════════════════
ÖRNEK — Tam Akış (Hedef Seçimi → Kutlama → Alt Soru)
═══════════════════════════════════════════════════

[Kullanıcı "Araba" hedefini seçtikten sonra ideal yanıt:]

Harika bir seçim! 🚗 Araba sahibi olmak, günlük hayatında bağımsızlık ve mobilite anlamına geliyor. Doğru planlama ile bu hedefe düşündüğünden daha hızlı ulaşabilirsin. Peki, sana en uygun stratejiyi belirleyebilmem için araba tercihini öğreneyim — bu, yatırım planını doğrudan etkiliyor.

```json
{
  "version": "v0.9",
  "createSurface": {
    "surfaceId": "strategy-car-1",
    "catalogId": "com.onyxfi.catalog"
  }
}
```

```json
{
  "version": "v0.9",
  "updateComponents": {
    "surfaceId": "strategy-car-1",
    "components": [
      {
        "id": "root",
        "component": "GoalSelectionCard",
        "title": "Araba Tercihin Ne Yönde?",
        "subtitle": "Bu seçim yatırım stratejini belirleyecek",
        "goals": [
          {"id": "economy", "label": "İkinci El Ekonomik", "emoji": "💰"},
          {"id": "luxury", "label": "Sıfır Lüks", "emoji": "✨"},
          {"id": "electric", "label": "Elektrikli Gelecek", "emoji": "⚡"}
        ]
      }
    ]
  }
}
```

═══════════════════════════════════════════════════
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
