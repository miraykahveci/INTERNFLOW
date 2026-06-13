import os
import requests
from abc import ABC, abstractmethod


# ==========================================================================
# 1. ARAYÜZ 
# ==========================================================================
class EmbeddingStrategy(ABC):

    @abstractmethod
    def generate_embedding(self, text: str) -> list[float]:
        pass

    @property
    @abstractmethod
    def name(self) -> str:
        pass


# ==========================================================================
# 2. LOKAL MOTOR 
# sentence-transformers ile PyTorch tabanlı
# ==========================================================================
class LocalEmbeddingStrategy(EmbeddingStrategy):
   

    MODEL_NAME = "sentence-transformers/paraphrase-multilingual-mpnet-base-v2"

    def __init__(self):
        
        from sentence_transformers import SentenceTransformer

        print(f"[LocalEmbedder] Model yükleniyor: {self.MODEL_NAME}")
        print("[LocalEmbedder] İlk seferde ~470 MB indirir, sonra cache'ten okur...")
        self.model = SentenceTransformer(self.MODEL_NAME)
        print("[LocalEmbedder] Model hazır ✓")

    @property
    def name(self) -> str:
        return "local-mpnet"

    def generate_embedding(self, text: str) -> list[float]:
        vector = self.model.encode(text, normalize_embeddings=True)
        return vector.tolist()


# ==========================================================================
# 3. API MOTORU (Production - Hugging Face sunucu
#   HTTP istek
# ==========================================================================
class APIEmbeddingStrategy(EmbeddingStrategy):

   
    API_URL = (
        "https://api-inference.huggingface.co/pipeline/feature-extraction/"
        "sentence-transformers/paraphrase-multilingual-mpnet-base-v2"
    )

    def __init__(self):
        self.hf_token = os.getenv("HF_API_TOKEN")
        if not self.hf_token:
            raise ValueError(
                "HF_API_TOKEN bulunamadı! .env'ye ekleyin: HF_API_TOKEN=hf_xxx"
            )
        self.headers = {
            "Authorization": f"Bearer {self.hf_token}",
            "Content-Type": "application/json",
        }
        print("[APIEmbedder] HF Inference API moduna hazır ✓")

    @property
    def name(self) -> str:
        return "api-hf-mpnet"

    def generate_embedding(self, text: str) -> list[float]:
        try:
            response = requests.post(
                self.API_URL,
                headers=self.headers,
                json={
                    "inputs": text,
                    "options": {"wait_for_model": True},  
                },
                timeout=30,
            )
            response.raise_for_status()
            result = response.json()

            
            if isinstance(result, list):
                if len(result) > 0 and isinstance(result[0], list):
                    return result[0] 
                return result
            raise ValueError(f"Beklenmeyen API cevabı: {type(result)}")

        except requests.exceptions.HTTPError as e:
            raise RuntimeError(
                f"HF API hatası ({response.status_code}): {response.text}"
            ) from e
        except requests.exceptions.Timeout:
            raise RuntimeError("HF API zaman aşımı (30 saniye)")


# ==========================================================================
# 4. FACTORY 
# ==========================================================================
def _create_embedding_service() -> EmbeddingStrategy:
    mode = os.getenv("EMBEDDING_MODE", "local").lower()
    print(f"[Factory] EMBEDDING_MODE = '{mode}'")

    if mode == "local":
        return LocalEmbeddingStrategy()
    elif mode == "api":
        return APIEmbeddingStrategy()
    else:
        raise ValueError(
            f"Geçersiz EMBEDDING_MODE: '{mode}'. 'local' veya 'api' olmalı."
        )


# ==========================================================================
# 5. SINGLETON 
# ==========================================================================
_embedder_instance: EmbeddingStrategy | None = None


def get_embedder() -> EmbeddingStrategy:
    """
    Singleton: Tek embedder instance kullanılır.
    Lokal modda modeli her çağrıda yeniden RAM'e yüklemeyi önler.
    """
    global _embedder_instance
    if _embedder_instance is None:
        _embedder_instance = _create_embedding_service()
    return _embedder_instance


# ==========================================================================
# TEST 
# ==========================================================================
if __name__ == "__main__":
    from dotenv import load_dotenv
    load_dotenv()

    print("=" * 60)
    print("Embedding Service Test")
    print("=" * 60)

    service = get_embedder()
    print(f"\nAktif strateji: {service.name}\n")

    test_metinleri = [
        "Bugün TÜBİTAK BİLGEM'de siber güvenlik laboratuvarında çalıştım.",
        "Penetration testing araçlarıyla ağ güvenliği analizi gerçekleştirdim.",
        "Bugün pasta yaptım, 2 yumurta ve 1 bardak un kullandım.",  # Alakasız
    ]

    vectors = []
    for i, metin in enumerate(test_metinleri, 1):
        print(f"[{i}] Vektör üretiliyor: '{metin[:45]}...'")
        vector = service.generate_embedding(metin)
        vectors.append(vector)
        print(f"    ✓ Boyut: {len(vector)}, İlk 3 değer: {[round(v, 3) for v in vector[:3]]}")

    # Cosine similarity testi
    print("\n" + "=" * 60)
    print("Cosine Similarity Testi (intihal mantığının özü)")
    print("=" * 60)

    def cosine_sim(v1, v2):
        import math
        dot = sum(a * b for a, b in zip(v1, v2))
        norm1 = math.sqrt(sum(a * a for a in v1))
        norm2 = math.sqrt(sum(b * b for b in v2))
        return dot / (norm1 * norm2)

    sim_benzer = cosine_sim(vectors[0], vectors[1])
    sim_alakasiz = cosine_sim(vectors[0], vectors[2])

    print(f"\n  Siber güvenlik ↔ Penetration testing : {sim_benzer:.4f}  (YÜKSEK olmalı)")
    print(f"  Siber güvenlik ↔ Pasta tarifi         : {sim_alakasiz:.4f}  (DÜŞÜK olmalı)")

    print("\n" + "=" * 60)
    if sim_benzer > sim_alakasiz:
        print("✅ TEST BAŞARILI! Model anlamsal benzerliği doğru yakaladı.")
    else:
        print("⚠️ Beklenmeyen sonuç, kontrol et.")
    print("=" * 60)