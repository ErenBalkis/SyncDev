"""
main.py – FinAjan FastAPI Uygulaması
=====================================
Flutter frontend'in bağlanacağı REST API uç noktalarını barındırır.
Gemini 2.5 Pro ile gerçek yapay zeka entegrasyonu sağlanır.

Uç noktalar (design.md'ye uygun):
  - POST /profiles/        → Yeni profil oluşturur
  - GET  /profiles/{user_id} → Kullanıcı profilini getirir
  - POST /chat/             → Sohbet mesajı alır, Gemini AI yanıtı döner
  - GET  /chat/{user_id}    → Sohbet geçmişini ve ui_structure'ları getirir

Çalıştırma:
  uvicorn main:app --reload
"""

import asyncio
import json
import os
import re
import traceback
from typing import Any, AsyncGenerator, Dict, List, Optional
from uuid import UUID

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from google import genai
from google.genai import types


from database import supabase
from models import (
    ProfileCreate,
    ProfileResponse,
    ChatRequest,
    ChatResponse,
    StreamChatRequest,
)

# .env'den GEMINI_API_KEY'i yükle
load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
if not GEMINI_API_KEY:
    raise EnvironmentError(
        "GEMINI_API_KEY ortam değişkeni tanımlanmalıdır. "
        "Lütfen .env dosyanızı kontrol edin."
    )

# ─────────────────────────────────────────────
# Gemini İstemcisi ve Yapılandırma
# ─────────────────────────────────────────────
gemini_client = genai.Client(api_key=GEMINI_API_KEY)
GEMINI_MODEL = "gemini-3-flash-preview"



# ─────────────────────────────────────────────
# FastAPI uygulamasını oluştur
# ─────────────────────────────────────────────
app = FastAPI(
    title="FinAjan API",
    description=(
        "Kullanıcılara finansal fırsatları sunan ve dinamik GenUI arayüzleri "
        "üreten FinAjan projesinin backend API'si."
    ),
    version="0.2.0",
)

# Flutter web/mobil'den gelen isteklere izin ver (CORS)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # Geliştirme aşaması için tüm kaynaklara açık
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─────────────────────────────────────────────
# 1) Sağlık Kontrolü (Health Check)
# ─────────────────────────────────────────────
@app.get("/", tags=["Genel"])
def health_check():
    """API'nin ayakta olduğunu doğrulayan basit uç nokta."""
    return {
        "durum": "çalışıyor",
        "proje": "FinAjan",
        "versiyon": "0.2.0",
        "mesaj": "FinAjan API'sine hoş geldiniz! 🚀",
    }


# ─────────────────────────────────────────────
# A2UI v0.9 System Instruction (Flutter'dan taşındı)
# ─────────────────────────────────────────────
# Bu prompt, GenUI SDK'nın Flutter tarafında Surface widget'ları
# oluşturabilmesi için Gemini'nin A2UI protokolünü takip etmesini sağlar.
# Daha önce gemini_client.dart içindeydi, artık backend'de yaşıyor.
A2UI_SYSTEM_INSTRUCTION = """
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
        <DÜZDÜZ_ÖZELLİKLER>
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
"""


def _build_profile_context(user_id_str: str) -> str:
    """Supabase'den kullanıcı profilini çeker ve AI bağlam bloğu oluşturur.
    Profil bulunamazsa (onboarding aşaması), genel bir bağlam döner."""
    try:
        profile_result = (
            supabase.table("user_profiles")
            .select("current_age, monthly_income, current_savings, monthly_expenses, risk_tolerance")
            .eq("id", user_id_str)
            .execute()
        )
    except Exception as exc:
        print(f"[chat/stream] Profil çekilirken hata: {exc}")
        return (
            "\n\n═══ KULLANICI PROFİLİ ═══\n"
            "Profil verisi alınamadı. Genel tavsiyeler ver.\n"
        )

    if not profile_result.data:
        return (
            "\n\n═══ KULLANICI PROFİLİ ═══\n"
            "Kullanıcı henüz finansal hedeflerini belirlemedi, onboarding aşamasında. "
            "Profil verileri mevcut değil — genel karşılama ve hedef belirleme akışını takip et.\n"
        )

    p = profile_result.data[0]
    return (
        "\n\n═══ KULLANICI PROFİLİ (Supabase) ═══\n"
        f"- Yaş: {p.get('current_age', 'Bilinmiyor')}\n"
        f"- Aylık Gelir: {p.get('monthly_income', 0)} TL\n"
        f"- Mevcut Birikim: {p.get('current_savings', 0)} TL\n"
        f"- Aylık Gider: {p.get('monthly_expenses', 0)} TL\n"
        f"- Risk Toleransı: {p.get('risk_tolerance', 'medium')}\n"
        "Bu bilgilere dayanarak kişiselleştirilmiş, veriye dayalı tavsiyeler ver.\n"
    )


async def _stream_gemini_sse(
    user_message: str,
    system_instruction: str,
) -> AsyncGenerator[str, None]:
    """Gemini'den streaming yanıt alır ve SSE formatında yield eder."""
    try:
        stream = gemini_client.models.generate_content_stream(
            model=GEMINI_MODEL,
            contents=user_message,
            config=types.GenerateContentConfig(
                system_instruction=system_instruction,
                temperature=0.7,
                top_p=0.95,
                top_k=40,
                max_output_tokens=8192,
            ),
        )
        for chunk in stream:
            if chunk.text:
                # SSE format: "data: <text>\n\n"
                yield f"data: {chunk.text}\n\n"
    except Exception as exc:
        error_msg = f"Sistemde anlık bir yoğunluk var. Lütfen tekrar deneyin. (Hata: {exc})"
        print(f"[chat/stream] ❌ Gemini stream hatası: {exc}")
        yield f"data: {error_msg}\n\n"

    # Sentinel: stream bitti
    yield "data: [DONE]\n\n"


# ─────────────────────────────────────────────
# 2) Yeni Profil Oluştur
# ─────────────────────────────────────────────
@app.post(
    "/profiles/",
    response_model=ProfileResponse,
    tags=["Profiller"],
)
def create_profile(profile: ProfileCreate):
    """
    Yeni bir kullanıcı profili oluşturur.
    Kullanıcının yaşı, gelir, birikim, gider ve risk toleransı bilgilerini kaydeder.
    """
    payload = profile.model_dump()
    # UUID'yi string'e çevir (Supabase uyumu)
    payload["id"] = str(payload["id"])

    result = (
        supabase.table("user_profiles")
        .insert(payload)
        .execute()
    )

    if not result.data:
        raise HTTPException(status_code=500, detail="Profil oluşturulurken hata oluştu.")

    return result.data[0]


# ─────────────────────────────────────────────
# 2.5) Streaming Sohbet — A2UI GenUI Akışı (YENİ)
# ─────────────────────────────────────────────
@app.post(
    "/chat/stream",
    tags=["Sohbet"],
)
async def chat_stream(req: StreamChatRequest):
    """
    Flutter GenUI istemcisinin bağlandığı streaming uç noktası.

    Akış:
      1. Supabase'den kullanıcı profilini çeker (yoksa genel bağlam kullanır)
      2. A2UI v0.9 sistem talimatı + profil bağlamını birleştirir
      3. Gemini'ye streaming istek atar
      4. Gelen chunk'ları SSE formatında Flutter'a iletir
      5. Stream bitince [DONE] sentinel gönderir

    Flutter tarafı her "data: <chunk>" satırını alıp
    A2uiTransportAdapter.addChunk() ile GenUI pipeline'ına besler.
    """
    user_id_str = str(req.user_id)

    # Profil bağlamını oluştur (yoksa graceful fallback)
    profile_context = _build_profile_context(user_id_str)

    # Tam sistem talimatı = A2UI protokolü + kullanıcı profil bağlamı
    full_system_instruction = A2UI_SYSTEM_INSTRUCTION + profile_context

    print(f"[chat/stream] 🚀 Streaming başlatılıyor — user: {user_id_str}")
    print(f"[chat/stream] Mesaj: \"{req.user_message[:80]}...\"")

    return StreamingResponse(
        _stream_gemini_sse(req.user_message, full_system_instruction),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",  # Nginx proxy desteği
        },
    )


# ─────────────────────────────────────────────
# 3) Kullanıcı Profilini Getir
# ─────────────────────────────────────────────
@app.get(
    "/profiles/{user_id}",
    response_model=ProfileResponse,
    tags=["Profiller"],
)
def get_profile(user_id: UUID):
    """Belirli bir kullanıcının profil bilgilerini döndürür."""
    result = (
        supabase.table("user_profiles")
        .select("*")
        .eq("id", str(user_id))
        .execute()
    )

    if not result.data:
        raise HTTPException(status_code=404, detail="Kullanıcı profili bulunamadı.")

    return result.data[0]


# ─────────────────────────────────────────────
# 4) Sohbet Mesajı Gönder (Gerçek Gemini AI)
# ─────────────────────────────────────────────
@app.post(
    "/chat/",
    response_model=ChatResponse,
    tags=["Sohbet"],
)
def create_chat(chat: ChatRequest):
    """
    Kullanıcıdan mesaj alır, Supabase'den profil bilgilerini çeker,
    Gemini 2.5 Pro'ya yapısal çıktı (Structured Output) isteği atar,
    sonucu agent_interactions tablosuna kaydeder ve frontend'e döner.
    """
    user_id_str = str(chat.user_id)
    user_msg = chat.user_message

    # ── 1. Kullanıcı profilini Supabase'den çek ──────────────────
    try:
        profile_result = (
            supabase.table("user_profiles")
            .select("current_age, monthly_income, current_savings, monthly_expenses, risk_tolerance")
            .eq("id", user_id_str)
            .execute()
        )
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Kullanıcı profili çekilirken hata: {exc}",
        )

    if not profile_result.data:
        raise HTTPException(
            status_code=404,
            detail="Kullanıcı profili bulunamadı. Lütfen önce profil oluşturun.",
        )

    profile = profile_result.data[0]

    # ── 2. Gemini için sistem promptu oluştur ────────────────────
    system_prompt = (
        "Sen bir profesyonel finans asistanısın. Kullanıcının aşağıdaki finansal bilgilerine hakimsin:\n"
        f"- Yaş: {profile['current_age']}\n"
        f"- Aylık Gelir: {profile['monthly_income']} TL\n"
        f"- Mevcut Birikim: {profile['current_savings']} TL\n"
        f"- Aylık Gider: {profile['monthly_expenses']} TL\n"
        f"- Risk Toleransı: {profile['risk_tolerance']}\n\n"
        "Bu bilgilere dayanarak kullanıcının sorularına profesyonel, analitik ve veriye dayalı "
        "cevaplar ver. Cevabında somut rakamlar ve öneriler kullan. Türkçe yanıt ver.\n\n"
        "Ayrıca cevabınla birlikte Flutter tarafında çizilecek bir GenUI bileşeni üret. "
        "ui_structure alanında:\n"
        "- type: 'chart_pie', 'info_card' veya 'action_slider' olabilir.\n"
        "- data: Bileşene özel veriyi içerir (örn: labels ve values dizileri).\n"
        "- metadata: Başlık (title) ve renk şeması (color_scheme: 'dark' veya 'light') içerir.\n\n"
        "\nÖNEMLİ KURALLAR:\n"
        "1. Yanıtını MUTLAKA aşağıdaki JSON formatında ver:\n"
        '{\n'
        '  "gemini_response": "Kullanıcıya verilecek metin cevabı buraya",\n'
        '  "ui_structure": {\n'
        '    "type": "chart_pie",\n'
        '    "data": {"labels": ["A", "B"], "values": [100, 200]},\n'
        '    "metadata": {"title": "Başlık", "color_scheme": "dark"}\n'
        '  }\n'
        '}\n'
        "2. gemini_response alanında çift tırnak karakteri kullanma, tek tırnak kullan.\n"
        "3. JSON formatına kesinlikle uygun, geçerli bir yanıt üret.\n"
        "4. ui_structure.type değeri 'chart_pie', 'info_card' veya 'action_slider' olmalı."
    )

    user_content = f"Kullanıcının sorusu: {user_msg}"

    # ── 3. Gemini'a yapısal çıktı isteği at ──────────────────────
    try:
        response = gemini_client.models.generate_content(
            model=GEMINI_MODEL,
            contents=user_content,
            config=types.GenerateContentConfig(
                system_instruction=system_prompt,
                response_mime_type="application/json",
            ),
        )
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Gemini API çağrısı sırasında hata: {exc}",
        )

    # ── 4. Gemini yanıtını ayrıştır ──────────────────────────────
    def _clean_and_parse_json(raw_text: str) -> dict:
        """Gemini'nin döndürdüğü ham metni temizleyerek JSON'a çevir."""
        # Markdown code fence varsa kaldır
        cleaned = raw_text.strip()
        if cleaned.startswith("```"):
            cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned)
            cleaned = re.sub(r"\s*```$", "", cleaned)

        # Kontrol karakterlerini temizle (tab ve newline hariç)
        cleaned = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f]', '', cleaned)

        return json.loads(cleaned)

    gemini_response_text = None
    ui_structure_dict = None

    # Yol 1: Ham metni temizleyerek parse et
    try:
        raw_json = _clean_and_parse_json(response.text)
        gemini_response_text = raw_json["gemini_response"]
        ui_structure_dict = raw_json["ui_structure"]
    except Exception:
        pass  # Retry'a geç

    # Yol 2: Hâlâ başarısızsa, daha kısa/sade bir yanıt iste (retry)
    if gemini_response_text is None:
        try:
            retry_response = gemini_client.models.generate_content(
                model=GEMINI_MODEL,
                contents=(
                    f"Aşağıdaki soruya KISA ve ÖZ bir yanıt ver. "
                    f"JSON içinde özel karakter kullanma.\n\n"
                    f"Soru: {user_msg}"
                ),
                config=types.GenerateContentConfig(
                    system_instruction=system_prompt,
                    response_mime_type="application/json",
                    temperature=0.2,
                ),
            )
            raw_json = _clean_and_parse_json(retry_response.text)
            gemini_response_text = raw_json["gemini_response"]
            ui_structure_dict = raw_json["ui_structure"]
        except Exception as exc:
            raise HTTPException(
                status_code=500,
                detail=(
                    f"Gemini yanıtı ayrıştırılırken hata (yeniden deneme dahil): {exc}\n"
                    f"Ham yanıt: {response.text[:500]}"
                ),
            )

    # ── 5. Supabase agent_interactions tablosuna kaydet ──────────
    payload = {
        "user_id": user_id_str,
        "user_message": user_msg,
        "gemini_response": gemini_response_text,
        "ui_structure": ui_structure_dict,
    }

    try:
        result = (
            supabase.table("agent_interactions")
            .insert(payload)
            .execute()
        )
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Etkileşim veritabanına kaydedilirken hata: {exc}\n{traceback.format_exc()}",
        )

    if not result.data:
        raise HTTPException(
            status_code=500,
            detail="Sohbet kaydedilirken hata oluştu (boş yanıt).",
        )

    # ── 6. Kaydedilen veriyi frontend'e dön ──────────────────────
    return result.data[0]


# ─────────────────────────────────────────────
# 5) Kullanıcının Sohbet Geçmişini Getir (Değişmedi)
# ─────────────────────────────────────────────
@app.get(
    "/chat/{user_id}",
    response_model=List[ChatResponse],
    tags=["Sohbet"],
)
def get_chat_history(user_id: UUID):
    """
    Belirli bir kullanıcının sohbet geçmişini ve ui_structure verilerini döndürür.
    Flutter bu verileri alıp ui_structure üzerinden dinamik GenUI ekranları oluşturur.
    """
    result = (
        supabase.table("agent_interactions")
        .select("*")
        .eq("user_id", str(user_id))
        .order("id", desc=False)
        .execute()
    )
    return result.data


# ─────────────────────────────────────────────
# Doğrudan çalıştırma desteği
# ─────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
