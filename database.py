"""
database.py – Supabase İstemci Bağlantısı
==========================================
Bu modül, Supabase Python istemcisini (client) oluşturur ve
uygulama genelinde tek bir bağlantı nesnesi olarak sunar.

Ortam değişkenleri .env dosyasından okunur:
  - SUPABASE_URL  : Supabase proje URL'si
  - SUPABASE_KEY  : Supabase anon / service-role anahtarı
"""

import os

from dotenv import load_dotenv
from supabase import create_client, Client

# .env dosyasındaki değişkenleri yükle
load_dotenv()

# Ortam değişkenlerini oku
SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY: str = os.getenv("SUPABASE_KEY") or os.getenv("SUPABASE_ANON_KEY", "")

# Değerlerin varlığını kontrol et — eksikse anlamlı hata ver
if not SUPABASE_URL or not SUPABASE_KEY:
    raise EnvironmentError(
        "SUPABASE_URL ve SUPABASE_KEY ortam değişkenleri tanımlanmalıdır. "
        "Lütfen .env dosyanızı kontrol edin."
    )

# Supabase istemcisini oluştur (uygulama boyunca tekil kullanılır)
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
