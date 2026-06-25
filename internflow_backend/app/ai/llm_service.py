import os
import asyncio
from google import genai


# ==========================================================================
# SABİTLER
# ==========================================================================
MODEL_NAME = "gemini-3.1-flash-lite"
MAX_INPUT_CHARS = 15000


class LLMService:

    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY")
        configured_mode = os.getenv("GEMINI_MODE", "").lower().strip()
        if configured_mode in ("stub", "live"):
            self.mode = configured_mode
        else:
            self.mode = "live" if self.api_key else "stub"

        self._client = None
        if self.mode == "live":
            try:
                self._client = genai.Client(api_key=self.api_key)
                print(f"[LLMService] ✓ Gemini client kuruldu ({MODEL_NAME})")
            except Exception as e:
                print(f"[LLMService] ⚠ Gemini client kurulamadı: {e}")
                print(f"[LLMService] ⚠ Stub moduna düşülüyor.")
                self.mode = "stub"

        print(f"[LLMService] Mode: {self.mode}")

    # ======================================================================
    # PUBLIC API
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
    # STUB METHODS
    # ======================================================================
    def _stub_summary(self, text: str) -> str:
        word_count = len(text.split())
        char_count = len(text)
        preview = text.strip().replace("\n", " ")[:150]

        return (
            "[STUB ÖZET — Gemini API entegrasyonu sunum öncesi aktive edilecek]\n\n"
            f"Bu staj defteri yaklaşık {word_count} kelime ve {char_count} karakter "
            f"içermektedir. Defterde öğrencinin staj sürecinde gerçekleştirdiği "
            f"teknik çalışmalar, kullandığı araçlar ve edindiği deneyimler yer almaktadır.\n\n"
            f"Metnin başlangıcı: \"{preview}...\"\n\n"
            f"(Gerçek özet, Gemini ile üretilecektir.)"
        )

    def _stub_explanation(self, text1: str, text2: str) -> str:
        return (
            "[STUB AÇIKLAMA — Gemini API entegrasyonu sunum öncesi aktive edilecek]\n\n"
            "İki staj defteri arasında yüksek semantik benzerlik tespit edilmiştir. "
            "Defterler farklı kelimeler kullanılmış olsa dahi benzer iş süreçlerini, "
            "teknik yaklaşımları ve ifade kalıplarını içeriyor olabilir.\n\n"
            "(Gerçek bağlamsal analiz, Gemini ile üretilecektir.)"
        )

    # ======================================================================
    # PROMPT ENGINEERING
    # ======================================================================
    def _build_summary_prompt(self, text: str) -> str:
        truncated_text = text[:MAX_INPUT_CHARS]
        truncated_note = " [Defter bu noktadan sonra kesildi]" if len(text) > MAX_INPUT_CHARS else ""

        return f"""Sen, üniversite stajlarını değerlendiren bir akademik denetleyicisin.
Görevin: aşağıda verilen staj defterinin akademik bir özetini hazırlamaktır.

KURALLAR:
- Çıktı 3-4 paragraf olmalı, toplam 250-300 kelime.
- Üçüncü tekil şahıs kullan ("öğrenci", "stajyer"). Asla "ben" deme.
- Akademik, nesnel bir ton kullan; överek/yererek değerlendirme yapma.
- Şu bilgilere değin: stajın yapıldığı alan, kullanılan teknolojiler/araçlar, 
  öğrencinin üstlendiği görevler, öne çıkan kazanımlar.
- [MASKED_EMAIL], [MASKED_TICKET] gibi etiketler görürsen YOK SAY — 
  bunlar kişisel veri maskelemesidir.
- Madde işareti, başlık veya numaralandırma KULLANMA. Akıcı paragraf yaz.
- Türkçe yaz.

STAJ DEFTERİ:
\"\"\"
{truncated_text}{truncated_note}
\"\"\"

ÖZET:"""

    def _build_explanation_prompt(self, text1: str, text2: str) -> str:
        t1 = text1[:MAX_INPUT_CHARS // 2]
        t2 = text2[:MAX_INPUT_CHARS // 2]

        return f"""Sen, üniversite stajlarında intihal denetimi yapan bir akademik yardımcısın.
Görevin: aşağıda verilen iki staj defterinin neden anlamsal olarak benzer 
göründüğünü, akademisyenin değerlendirmesine yardımcı olacak şekilde açıklamaktır.

KURALLAR:
- Çıktı 2-3 paragraf olmalı, toplam 150-250 kelime.
- Kesin yargı içeren ifadeler ("intihal kesindir") KULLANMA. 
  Bunun yerine "benzerlik gözlemlenmiştir", "örtüşme tespit edilmiştir" gibi 
  betimleyici ifadeler kullan.
- Hangi konularda örtüşme olduğunu somut olarak belirt (örn. "her iki defterde de 
  token-tabanlı kimlik doğrulama anlatılmıştır").
- Sondaki paragrafta NİHAİ KARARIN AKADEMİSYENE AİT olduğunu belirt.
- [MASKED_*] etiketleri kişisel veri maskelemesidir; analizini bunlara dayanma.
- Madde işareti, başlık veya numaralandırma KULLANMA. Akıcı paragraf yaz.
- Türkçe yaz.

DEFTER A:
\"\"\"
{t1}
\"\"\"

DEFTER B:
\"\"\"
{t2}
\"\"\"

AÇIKLAMA:"""

    # ======================================================================
    # REAL METHODS 
    # ======================================================================
    async def _real_summarize(self, text: str) -> str:
        """Gerçek Gemini ile özet üretimi (retry mekanizmalı)."""
        if not self._client:
            raise RuntimeError("Gemini client başlatılmamış — API key kontrol edin.")

        prompt = self._build_summary_prompt(text)
        return await self._call_gemini_with_retry(
            prompt=prompt,
            fallback=lambda: self._stub_summary(text),
            operation_name="Özet"
        )

    async def _real_explain(self, text1: str, text2: str) -> str:
        """Gerçek Gemini ile intihal açıklaması (retry mekanizmalı)."""
        if not self._client:
            raise RuntimeError("Gemini client başlatılmamış — API key kontrol edin.")

        prompt = self._build_explanation_prompt(text1, text2)
        return await self._call_gemini_with_retry(
            prompt=prompt,
            fallback=lambda: self._stub_explanation(text1, text2),
            operation_name="İntihal açıklama"
        )

    # ======================================================================
    # RETRY MEKANİZMASI
    # ======================================================================
    async def _call_gemini_with_retry(
        self,
        prompt: str,
        fallback,
        operation_name: str,
        max_retries: int = 5,
        initial_delay: float = 1.5,
    ) -> str:
        for attempt in range(max_retries):
            try:
                response = await asyncio.to_thread(
                    self._client.models.generate_content,
                    model=MODEL_NAME,
                    contents=prompt,
                )
                result = response.text.strip() if response.text else ""
                if not result:
                    raise ValueError("Gemini boş yanıt döndürdü")
                if attempt > 0:
                    print(f"[LLMService] ✓ {operation_name}: {attempt + 1}. denemede başarılı")
                return result

            except Exception as e:
                err_str = str(e)
                is_retryable = (
                    "503" in err_str or "UNAVAILABLE" in err_str or
                    "500" in err_str or "INTERNAL" in err_str or
                    "429" in err_str or "deadline" in err_str.lower() or
                    "timeout" in err_str.lower()
                )
                if not is_retryable or attempt == max_retries - 1:
                    print(f"[LLMService] ⚠ {operation_name} kalıcı hata: {e}")
                    break
                delay = initial_delay * (2 ** attempt)
                print(f"[LLMService] ↻ {operation_name} retry {attempt + 1}/{max_retries} ({delay}sn bekle): {e}")
                await asyncio.sleep(delay)

        print(f"[LLMService] ⚠ {operation_name} tüm denemeler başarısız → fallback")
        return fallback()


# ==========================================================================
# Singleton
# ==========================================================================
_llm_instance: LLMService | None = None


def get_llm_service() -> LLMService:
    global _llm_instance
    if _llm_instance is None:
        _llm_instance = LLMService()
    return _llm_instance


# ==========================================================================
# TEST ALANI
# ==========================================================================
if __name__ == "__main__":
    from dotenv import load_dotenv
    load_dotenv()

    print("=" * 60)
    print("LLM Service Test")
    print("=" * 60)

    service = get_llm_service()

    async def run_test():
        test_text = (
            "Bugün şirkette React projesi üzerinde çalıştım. "
            "Authentication modülünü geliştirdim, JWT token entegrasyonu yaptım. "
            "Kod review sürecine katıldım ve birim testleri yazdım. "
            "Mentorum [MASKED_EMAIL] üzerinden geri bildirim verdi."
        )

        print("\n--- ÖZET TESTİ ---")
        summary = await service.summarize(test_text)
        print(summary)

        print("\n--- İNTİHAL AÇIKLAMASI TESTİ ---")
        explanation = await service.explain_similarity(test_text, test_text)
        print(explanation)

    asyncio.run(run_test())

    print("\n" + "=" * 60)
    print(f"✅ TEST TAMAMLANDI! (Mode: {service.mode})")
    print("=" * 60)