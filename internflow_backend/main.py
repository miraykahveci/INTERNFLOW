import os
from fastapi import FastAPI
from supabase import create_client, Client
from dotenv import load_dotenv

# 1. .env dosyasını yükle
# dotenv_path belirtmek, dosyanın yerini bulmasını garantiye alır.
load_dotenv(dotenv_path=".env")

app = FastAPI()

# 2. Supabase Bilgilerini Al
url: str = os.getenv("SUPABASE_URL")
key: str = os.getenv("SUPABASE_KEY")

# 3. Güvenlik Kontrolü (Terminalde hata görmeni sağlar)
if not url or not key:
    print("\n❌ HATA: SUPABASE_URL veya SUPABASE_KEY bulunamadı!")
    print("👉 Lütfen internflow_backend içinde .env dosyası olduğundan")
    print("👉 Ve içinde değişkenlerin doğru yazıldığından emin ol.\n")
else:
    print("\n✅ Supabase yapılandırması yüklendi.\n")

# 4. Supabase İstemcisini Oluştur
# Eğer url veya key None gelirse burada hata vermemesi için kontrol ekledik
try:
    supabase: Client = create_client(url, key) if url and key else None
except Exception as e:
    print(f"❌ Supabase Client başlatılamadı: {e}")
    supabase = None

@app.get("/")
def read_root():
    return {"message": "InternFlow Backend Çalışıyor!"}

@app.get("/test-supabase")
def test_supabase():
    if not supabase:
        return {"status": "Hata", "message": "Supabase bağlantısı kurulamadı."}
    
    try:
        # Gerçek bir test: Supabase'den basit bir veri çekmeyi deneyebiliriz
        # Şimdilik sadece bağlantı objesinin varlığını kontrol ediyoruz
        return {"status": "Bağlantı Başarılı", "url": url}
    except Exception as e:
        return {"status": "Hata", "error": str(e)}