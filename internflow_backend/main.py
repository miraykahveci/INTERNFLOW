from fastapi import FastAPI

# Uygulamamızı oluşturuyoruz
app = FastAPI(title="InternFlow API", version="1.0")

# Ana sayfaya girildiğinde çalışacak fonksiyon
@app.get("/")
def read_root():
    return {"mesaj": "InternFlow Backend Sistemine Hos Geldiniz!", "durum": "Aktif"}