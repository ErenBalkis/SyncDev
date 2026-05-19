"""
models.py – Pydantic Veri Modelleri
====================================
Supabase tablolarına karşılık gelen istek (request) ve
yanıt (response) şemalarını tanımlar.

Tablolar:
  - user_profiles
  - agent_interactions  (ui_structure alanı GenUI için kritik)

Bu dosya design.md belgesindeki şemaya kesinlikle sadık kalır.
"""

from datetime import datetime
from typing import Any, Dict, List, Optional
from uuid import UUID
# pyrefly: ignore [missing-import]
from pydantic import BaseModel, Field


# ─────────────────────────────────────────────
# 1) user_profiles tablosu
# ─────────────────────────────────────────────

class ProfileCreate(BaseModel):
    """Yeni bir kullanıcı profili oluşturmak için istek gövdesi."""
    id: UUID = Field(..., description="Kullanıcının benzersiz UUID'si")
    current_age: int = Field(
        default=25,
        description="Kullanıcının mevcut yaşı",
    )
    target_retirement_age: int = Field(
        default=50,
        description="Hedeflenen emeklilik yaşı",
    )
    monthly_income: float = Field(
        ...,
        description="Aylık gelir (TL)",
    )
    current_savings: float = Field(
        ...,
        description="Mevcut birikim (TL)",
    )
    monthly_expenses: float = Field(
        ...,
        description="Aylık gider (TL)",
    )
    risk_tolerance: str = Field(
        default="medium",
        description="Risk toleransı ('low', 'medium', 'high')",
    )


class ProfileResponse(ProfileCreate):
    """Veritabanından dönen kullanıcı profili."""
    pass


# ─────────────────────────────────────────────
# 2) GenUI ui_structure veri standardı
#
#    design.md'ye göre her zaman şu yapıda:
#    {
#      "type": "chart_pie | info_card | action_slider",
#      "data": {},
#      "metadata": {}
#    }
# ─────────────────────────────────────────────

class UIStructure(BaseModel):
    """
    GenUI bileşen tanımı.
    Flutter tarafı bu yapıyı okuyarak ekranda dinamik widget oluşturur.

    Standart format:
    {
      "type": "chart_pie",
      "data": {
        "labels": ["Mevcut Birikim", "Hedefe Kalan"],
        "values": [25000, 75000]
      },
      "metadata": {
        "title": "Emeklilik Hedefi İlerlemesi",
        "color_scheme": "dark"
      }
    }
    """
    type: str = Field(
        ...,
        description="Bileşen türü (ör: 'chart_pie', 'info_card', 'action_slider')",
    )
    data: Dict[str, Any] = Field(
        default_factory=dict,
        description="Bileşene ait veri payload'u (grafiğin değerleri, kartın içeriği vb.)",
    )
    metadata: Dict[str, Any] = Field(
        default_factory=dict,
        description="Görsel ve davranışsal meta bilgiler (başlık, renk şeması vb.)",
    )


# ─────────────────────────────────────────────
# 3) agent_interactions tablosu
# ─────────────────────────────────────────────

# 1. Flutter'dan Sadece Bu Gelecek (Girdi)
class ChatRequest(BaseModel):
    """Flutter'dan backend'e gelen istek."""
    user_id: UUID = Field(..., description="Etkileşimin ait olduğu kullanıcı UUID'si")
    user_message: str = Field(
        ...,
        min_length=1,
        description="Kullanıcının sorusu / mesajı (boş olamaz)",
    )

# 2. Swagger ve Flutter'a Dönecek Cevap (Çıktı)
class ChatResponse(BaseModel):
    """Veritabanından dönen sohbet etkileşimi ve GenUI yapısı."""
    id: int
    user_id: UUID
    user_message: str
    gemini_response: str
    ui_structure: Optional[Dict[str, Any]] = None
    created_at: Optional[datetime] = Field(
        default=None,
        description="Etkileşimin oluşturulma zamanı (Supabase tarafından otomatik atanır)",
    )
    