# FinAjan - Proje Mimari ve Tasarım Belgesi (Design Document)

## 1. Proje Özeti (MVP Hedefi)
FinAjan, kullanıcıların kişisel finans durumlarını (maaş, birikim, gider) analiz ederek onlara emeklilik simülasyonları ve yatırım hedefleri sunan yapay zeka tabanlı bir sohbet asistanıdır.
Sistem, klasik metin tabanlı sohbet yerine, backend'den gelen JSON verilerine göre ön yüzde anında grafikler ve etkileşimli kartlar çizen "GenUI (Üretken Arayüz)" konseptine dayanmaktadır.

## 2. Teknoloji Yığını (Tech Stack)
- **Backend:** Python 3.10+, FastAPI, Uvicorn, Pydantic
- **Veritabanı:** Supabase (PostgreSQL tabanlı, supabase-py istemcisi ile)
- **Frontend:** Flutter (Backend'den gelen ui_structure JSON'larını yorumlayıp çizen Server-Driven UI yapısı)
- **Yapay Zeka:** Gemini 2.5 Pro (MVP aşamasında API bağlantısı yerine statik/mock verilerle simüle edilecektir)

## 3. Veritabanı Şeması (Supabase)
Tüm Pydantic modelleri ve SQL işlemleri aşağıdaki şemaya kesinlikle sadık kalmalıdır:

1. `user_profiles` Tablosu:
   - `id` (UUID, Primary Key)
   - `current_age` (Int, default 25)
   - `target_retirement_age` (Int, default 50)
   - `monthly_income` (Numeric, aylık gelir)
   - `current_savings` (Numeric, mevcut birikim)
   - `monthly_expenses` (Numeric, aylık gider)
   - `risk_tolerance` (Text, 'low', 'medium', 'high')

2. `agent_interactions` Tablosu:
   - `id` (BigInt, Primary Key)
   - `user_id` (UUID, user_profiles tablosuna referans)
   - `user_message` (Text, kullanıcının sorusu)
   - `gemini_response` (Text, yapay zekanın metin cevabı)
   - `ui_structure` (JSONB, Frontend'in çizeceği GenUI bileşen verisi)

## 4. API Uç Noktaları (Endpoints)
FastAPI `main.py` içinde şu uç noktalar bulunmalıdır:
- `POST /profiles/`: Yeni profil oluşturur.
- `GET /profiles/{user_id}`: Kullanıcı profilini getirir.
- `POST /chat/`: Kullanıcıdan mesaj alır, `agent_interactions` tablosuna kaydeder. (Not: Yapay zeka entegrasyonu MVP'de mock/sahte olarak çalışacak).
- `GET /chat/{user_id}`: Kullanıcının sohbet geçmişini ve `ui_structure` verilerini getirir.

## 5. GenUI (Üretken Arayüz) Veri Standartları
`ui_structure` JSON alanı, Flutter tarafında sorunsuz çizilebilmesi için her zaman şu esnek standarda uymalıdır:
```json
{
  "type": "chart_pie | info_card | action_slider",
  "data": {},
  "metadata": {}
}
```
Örnek Mock ui_structure (Emeklilik Grafiği):
```json
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
```

## 6. Geliştirme ve AI Kuralları (Strict Rules)
Kod yazarken Pydantic BaseModel'leri kesinlikle kullanılmalı ve veri doğrulaması (validation) yapılmalıdır.

Sadece istenen dosyayı/fonksiyonu değiştir. Projenin geri kalanını baştan yazma.

Supabase bağlantısı .env dosyası üzerinden os.getenv ile sağlanmalıdır.

Python kodlarında karmaşıklığı önlemek adına basit modüler yapı kullanılmalı, gereksiz kütüphane eklenmemelidir.