"""
LLM Service - Doğal Dil Üretimi 

Bu modül insan tarafından okunacak metinler üretir:
  - summarize()          → Defterin akademik özeti
  - explain_similarity() → İki defter arasındaki benzerliğin açıklaması

STUB PATTERN: Geliştirme aşamasında GEMINI_MODE=stub iken sahte yanıt döner.
Sunum öncesi GEMINI_MODE=live yapılıp gerçek Gemini API'ye bağlanır.
Bu sayede geliştirmede API maliyeti/quota tüketimi olmaz, pipeline test edilebilir.

Mimari not: Embedding ve similarity LLM gerektirmez (mekanik işlem).
LLM sadece doğal dil üretimi (NLG) için kullanılır. Doğru araç, doğru iş.
Stub pattern + dependency injection ile API'siz geliştirme mümkün.
"""

import os


class LLMService:

    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY")
        configured_mode = os.getenv("GEMINI_MODE", "").lower().strip()
        if configured_mode in ("stub", "live"):
            self.mode = configured_mode
        else:
            self.mode = "live" if self.api_key else "stub"

        print(f"[LLMService] Mode: {self.mode}")

    # ======================================================================
    # PUBLIC API — Pipeline bu iki fonksiyonu çağırır
    # ======================================================================
    async def summarize(self, text: str) -> str:
        """Defterin akademik özetini üretir"""
        if self.mode == "stub":
            return self._stub_summary(text)
        return await self._real_summarize(text)

    async def explain_similarity(self, text1: str, text2: str) -> str:
        """İki metin arasındaki benzerliği açıklar (intihal yorumu)"""
        if self.mode == "stub":
            return self._stub_explanation(text1, text2)
        return await self._real_explain(text1, text2)

    # ======================================================================
    # STUB METHODS — Gemini API gelene kadar kullanılır
    # ======================================================================
    def _stub_summary(self, text: str) -> str:
        """Sahte ama mantıklı özet (metin istatistiğine dayalı)"""
        word_count = len(text.split())
        char_count = len(text)
        preview = text.strip().replace("\n", " ")[:150]

        return (
            "[STUB ÖZET — Gemini API entegrasyonu sunum öncesi aktive edilecek]\n\n"
            f"Bu staj defteri yaklaşık {word_count} kelime ve {char_count} karakter "
            f"içermektedir. Defterde öğrencinin staj sürecinde gerçekleştirdiği "
            f"teknik çalışmalar, kullandığı araçlar ve edindiği deneyimler yer almaktadır.\n\n"
            f"Metnin başlangıcı: \"{preview}...\"\n\n"
            f"(Gerçek özet, Gemini 1.5 Flash ile üretilecektir.)"
        )

    def _stub_explanation(self, text1: str, text2: str) -> str:
        """Sahte intihal açıklaması"""
        return (
            "[STUB AÇIKLAMA — Gemini API entegrasyonu sunum öncesi aktive edilecek]\n\n"
            "İki staj defteri arasında yüksek semantik benzerlik tespit edilmiştir. "
            "Defterler farklı kelimeler kullanılmış olsa dahi benzer iş süreçlerini, "
            "teknik yaklaşımları ve ifade kalıplarını içeriyor olabilir.\n\n"
            "(Gerçek bağlamsal analiz, Gemini 1.5 Flash ile üretilecektir.)"
        )

    # ======================================================================
    # REAL METHODS — Sunum öncesi implement edilecek (şimdilik hatalı)
    # ======================================================================
    async def _real_summarize(self, text: str) -> str:
        """
        Gerçek Gemini ile özet üretimi.
        SUNUM ÖNCESİ implement edilecek. Şu an çağrılırsa hata verir.
        """
        # TODO (sunum öncesi):
        # import google.generativeai as genai
        # genai.configure(api_key=self.api_key)
        # model = genai.GenerativeModel("gemini-1.5-flash")
        # prompt = f"Şu staj defterinin akademik özetini 2-3 paragraf yaz:\n\n{text}"
        # response = await model.generate_content_async(prompt)
        # return response.text
        raise NotImplementedError(
            "Gemini live mode henüz aktif değil. GEMINI_MODE=stub kullanın "
            "veya sunum öncesi _real_summarize'ı implement edin."
        )

    async def _real_explain(self, text1: str, text2: str) -> str:
        """
        Gerçek Gemini ile intihal açıklaması.
        SUNUM ÖNCESİ implement edilecek.
        """
        raise NotImplementedError(
            "Gemini live mode henüz aktif değil. GEMINI_MODE=stub kullanın."
        )


# ==========================================================================
# Singleton
# ==========================================================================
_llm_instance: LLMService | None = None


def get_llm_service() -> LLMService:
    """Singleton: tek LLMService instance döner"""
    global _llm_instance
    if _llm_instance is None:
        _llm_instance = LLMService()
    return _llm_instance


# ==========================================================================
# TEST ALANI — python -m app.ai.llm_service
# ==========================================================================
if __name__ == "__main__":
    import asyncio
    from dotenv import load_dotenv
    load_dotenv()

    print("=" * 60)
    print("LLM Service Test (Stub Mode)")
    print("=" * 60)

    service = get_llm_service()

    async def run_test():
        test_text = (
            "Bugün şirkette React projesi üzerinde çalıştım. "
            "Authentication modülünü geliştirdim, JWT token entegrasyonu yaptım. "
            "Kod review sürecine katıldım ve birim testleri yazdım."
        )

        print("\n--- ÖZET TESTİ ---")
        summary = await service.summarize(test_text)
        print(summary)

        print("\n--- İNTİHAL AÇIKLAMASI TESTİ ---")
        explanation = await service.explain_similarity(test_text, test_text)
        print(explanation)

    asyncio.run(run_test())

    print("\n" + "=" * 60)
    print("✅ TEST BAŞARILI! Stub yanıtlar üretildi.")
    print("(Sunum öncesi GEMINI_MODE=live ile gerçek API'ye geçilecek)")
    print("=" * 60)