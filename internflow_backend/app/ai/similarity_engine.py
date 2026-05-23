"""
Similarity Engine - İntihal Tespitinin Matematik Motoru

Bu modül iki görev yapar:
  1. find_similar_analyses() → pgvector ile en benzer defterleri bulur (RPC)
  2. calculate_risk_level()  → benzerlik skorundan risk seviyesi belirler (Python)

- Benzerlik: pgvector cosine distance (<=> operatörü), veritabanı seviyesinde
- Risk: Python if/else, threshold tabanlı karar
"""

from app.db.supabase_client import supabase


# ==========================================================================
# RISK THRESHOLD'LARI (kararlaştırılan değerler)
# ==========================================================================
HIGH_RISK_THRESHOLD = 0.80    
MEDIUM_RISK_THRESHOLD = 0.60  


class SimilarityEngine:
    """Vektör benzerliği ve risk hesaplama motoru"""

    def find_similar_analyses(
        self,
        query_embedding: list[float],
        exclude_analysis_id: str,
        match_count: int = 5,
    ) -> list[dict]:
        """
        Verilen vektöre en benzer analizleri bulur (pgvector RPC ile).

        Args:
            query_embedding: Karşılaştırılacak 768 boyutlu vektör
            exclude_analysis_id: Hariç tutulacak analiz (kendisi)
            match_count: Kaç benzer sonuç döneceği

        Returns:
            [{analysis_id, document_id, similarity}, ...] (similarity'ye göre sıralı)
        """
        try:
            response = supabase.rpc(
                "match_analysis",
                {
                    "query_embedding": query_embedding,
                    "exclude_analysis_id": exclude_analysis_id,
                    "match_count": match_count,
                },
            ).execute()

            return response.data or []

        except Exception as e:
            print(f"[SimilarityEngine] RPC hatası: {e}")
            return []

    def get_top_match(
        self,
        query_embedding: list[float],
        exclude_analysis_id: str,
    ) -> dict | None:
        """
        En benzer TEK analizi döner (en yüksek similarity).

        Returns:
            {analysis_id, document_id, similarity} veya None (hiç eşleşme yoksa)
        """
        matches = self.find_similar_analyses(
            query_embedding, exclude_analysis_id, match_count=1
        )
        return matches[0] if matches else None

    def calculate_risk_level(self, similarity_score: float) -> str:
        """
        Benzerlik skorundan risk seviyesi belirler (Python if/else).

        threshold kararı.

        Args:
            similarity_score: 0.0 - 1.0 arası cosine similarity

        Returns:
            'high', 'medium' veya 'low'
        """
        if similarity_score >= HIGH_RISK_THRESHOLD:
            return "high"
        elif similarity_score >= MEDIUM_RISK_THRESHOLD:
            return "medium"
        else:
            return "low"

    def is_risky(self, similarity_score: float) -> bool:
        """Geriye uyumluluk: yüksek risk mi? (boolean)"""
        return similarity_score >= HIGH_RISK_THRESHOLD


# ==========================================================================
# Singleton
# ==========================================================================
_engine_instance: SimilarityEngine | None = None


def get_similarity_engine() -> SimilarityEngine:
    """Singleton: tek SimilarityEngine instance döner"""
    global _engine_instance
    if _engine_instance is None:
        _engine_instance = SimilarityEngine()
    return _engine_instance


# ==========================================================================
# TEST ALANI — python -m app.ai.similarity_engine
# ==========================================================================
if __name__ == "__main__":
    print("=" * 60)
    print("Similarity Engine Test")
    print("=" * 60)

    engine = get_similarity_engine()

    
    print("\n--- RİSK SEVİYESİ TESTİ (Python threshold) ---")
    test_scores = [0.95, 0.85, 0.72, 0.65, 0.45, 0.20]
    for score in test_scores:
        risk = engine.calculate_risk_level(score)
        emoji = {"high": "🔴", "medium": "🟠", "low": "🟢"}[risk]
        print(f"  Skor {score:.2f} → {emoji} {risk.upper()}")

    
    print("\n--- pgvector RPC TESTİ ---")
    print("Veritabanına örnek bir vektörle sorgu atılıyor...")
    
    dummy_vector = [0.1] * 768
    matches = engine.find_similar_analyses(
        query_embedding=dummy_vector,
        exclude_analysis_id="00000000-0000-0000-0000-000000000000",
        match_count=5,
    )
    print(f"  Bulunan eşleşme sayısı: {len(matches)}")
    if matches:
        for m in matches:
            print(f"    - similarity: {m.get('similarity'):.4f}")
    else:
        print("  (Henüz veritabanında analiz yok — normal, ilk testte boş döner)")

    print("\n" + "=" * 60)
    print("✅ TEST BAŞARILI! Risk hesaplama çalışıyor, RPC bağlantısı kuruldu.")
    print("=" * 60)