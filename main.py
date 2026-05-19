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

import json
import os
import re
import traceback
from typing import Any, Dict, List, Optional
from uuid import UUID

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from google.genai import types


from database import supabase
from models import (
    ProfileCreate,
    ProfileResponse,
    ChatRequest,
    ChatResponse,
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
GEMINI_MODEL = "gemini-2.5-flash"



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
