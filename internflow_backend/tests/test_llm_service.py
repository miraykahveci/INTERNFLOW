"""
LLM Service Birim Testleri
===========================
Gemini API entegrasyonu, stub fallback ve retry mekanizması testleri.
Gerçek Gemini API çağrılmıyor - unittest.mock ile izole edilir.
"""

import os
import pytest
import asyncio
from unittest.mock import patch, MagicMock, AsyncMock
from app.ai.llm_service import (
    LLMService,
    get_llm_service,
    MODEL_NAME,
    MAX_INPUT_CHARS,
)


# ============================================================
# 1. Mode Selection (Live vs Stub)
# ============================================================

class TestModeSelection:
    """Mod seçimi testleri: API key varlığı + GEMINI_MODE override."""

    @patch.dict(os.environ, {"GEMINI_API_KEY": "", "GEMINI_MODE": ""}, clear=True)
    def test_no_api_key_falls_back_to_stub(self):
        """API key yoksa stub moduna düşmeli."""
        service = LLMService()
        assert service.mode == "stub"

    @patch.dict(os.environ, {"GEMINI_API_KEY": "test-key", "GEMINI_MODE": "stub"}, clear=True)
    def test_explicit_stub_mode_override(self):
        """GEMINI_MODE=stub ise API key olsa bile stub kullanılmalı."""
        service = LLMService()
        assert service.mode == "stub"

    @patch.dict(os.environ, {"GEMINI_API_KEY": "fake-key"}, clear=True)
    @patch("app.ai.llm_service.genai.Client")
    def test_with_api_key_uses_live_mode(self, mock_client):
        """API key varsa live moduna geçmeli."""
        service = LLMService()
        assert service.mode == "live"
        mock_client.assert_called_once_with(api_key="fake-key")

    @patch.dict(os.environ, {"GEMINI_API_KEY": "fake-key"}, clear=True)
    @patch("app.ai.llm_service.genai.Client", side_effect=Exception("Connection failed"))
    def test_client_init_failure_falls_back_to_stub(self, mock_client):
        """Gemini client başlatma hatası → stub'a düşmeli (graceful degradation)."""
        service = LLMService()
        assert service.mode == "stub"


# ============================================================
# 2. Stub Summary
# ============================================================

class TestStubSummary:
    """Stub özet fonksiyonu testleri."""

    def setup_method(self):
        # Stub mode'da çalış
        with patch.dict(os.environ, {"GEMINI_API_KEY": "", "GEMINI_MODE": "stub"}, clear=True):
            self.service = LLMService()

    def test_stub_summary_contains_stub_marker(self):
        """Stub özet [STUB özet] etiketi içermeli."""
        result = self.service._stub_summary("Test metin")
        assert "[STUB ÖZET" in result

    def test_stub_summary_counts_words(self):
        """Stub özet kelime sayısını doğru saymalı."""
        text = "bir iki üç dört beş"  
        result = self.service._stub_summary(text)
        assert "5 kelime" in result

    def test_stub_summary_counts_chars(self):
        """Stub özet karakter sayısını doğru saymalı."""
        text = "abc"  
        result = self.service._stub_summary(text)
        assert "3 karakter" in result

    def test_stub_summary_includes_preview(self):
        """Stub özet metnin başlangıcını içermeli."""
        text = "Bu defter Türkiye'deki staj deneyimini anlatmaktadır."
        result = self.service._stub_summary(text)
        assert "Bu defter Türkiye" in result


# ============================================================
# 3. Stub Explanation
# ============================================================

class TestStubExplanation:
    """Stub intihal açıklama fonksiyonu testleri."""

    def setup_method(self):
        with patch.dict(os.environ, {"GEMINI_API_KEY": "", "GEMINI_MODE": "stub"}, clear=True):
            self.service = LLMService()

    def test_stub_explanation_contains_stub_marker(self):
        """Stub açıklama [STUB AÇIKLAMA] etiketi içermeli."""
        result = self.service._stub_explanation("metin1", "metin2")
        assert "[STUB AÇIKLAMA" in result

    def test_stub_explanation_mentions_similarity(self):
        """Stub açıklama 'benzerlik' kelimesi içermeli."""
        result = self.service._stub_explanation("metin1", "metin2")
        assert "benzerlik" in result.lower()


# ============================================================
# 4. Public API: summarize (stub mode)
# ============================================================

class TestSummarizeStubMode:
    """Stub mode'da summarize() public API testleri."""

    def setup_method(self):
        with patch.dict(os.environ, {"GEMINI_API_KEY": "", "GEMINI_MODE": "stub"}, clear=True):
            self.service = LLMService()

    @pytest.mark.asyncio
    async def test_summarize_returns_stub_in_stub_mode(self):
        """Stub mode'da summarize() stub yanıt dönmeli."""
        result = await self.service.summarize("Test metin")
        assert "[STUB ÖZET" in result

    @pytest.mark.asyncio
    async def test_summarize_does_not_call_gemini_in_stub(self):
        """Stub mode'da Gemini'ye çağrı yapılmamalı."""
        # _client None olmalı stub mode'da
        assert self.service._client is None


# ============================================================
# 5. Public API: explain_similarity (stub mode)
# ============================================================

class TestExplainSimilarityStubMode:
    """Stub mode'da explain_similarity() testleri."""

    def setup_method(self):
        with patch.dict(os.environ, {"GEMINI_API_KEY": "", "GEMINI_MODE": "stub"}, clear=True):
            self.service = LLMService()

    @pytest.mark.asyncio
    async def test_explain_returns_stub_in_stub_mode(self):
        """Stub mode'da explain_similarity stub dönmeli."""
        result = await self.service.explain_similarity("metin1", "metin2")
        assert "[STUB AÇIKLAMA" in result


# ============================================================
# 6. Live Mode: Gemini Mock'lı Başarılı Çağrı
# ============================================================

class TestLiveModeSuccess:
    """Live mode'da Gemini başarılı yanıt senaryoları (mock'lu)."""

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"GEMINI_API_KEY": "fake-key"}, clear=True)
    @patch("app.ai.llm_service.genai.Client")
    async def test_summarize_returns_gemini_text(self, mock_client_class):
        """Gemini başarılı yanıt dönerse o text dönmeli."""
        # ARRANGE - Gemini mock yanıtı
        mock_response = MagicMock()
        mock_response.text = "Bu, yapay zekanın ürettiği özet metnidir."

        mock_client = MagicMock()
        mock_client.models.generate_content.return_value = mock_response
        mock_client_class.return_value = mock_client

        # ACT
        service = LLMService()
        result = await service.summarize("Test staj defteri metni")

        # ASSERT
        assert "yapay zekanın" in result
        assert mock_client.models.generate_content.called

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"GEMINI_API_KEY": "fake-key"}, clear=True)
    @patch("app.ai.llm_service.genai.Client")
    async def test_explain_returns_gemini_text(self, mock_client_class):
        """Explain için Gemini başarılı yanıt dönmeli."""
        mock_response = MagicMock()
        mock_response.text = "İki defter arasında belirgin örtüşme tespit edilmiştir."

        mock_client = MagicMock()
        mock_client.models.generate_content.return_value = mock_response
        mock_client_class.return_value = mock_client

        service = LLMService()
        result = await service.explain_similarity("metin1", "metin2")

        assert "örtüşme" in result

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"GEMINI_API_KEY": "fake-key"}, clear=True)
    @patch("app.ai.llm_service.genai.Client")
    async def test_summarize_uses_correct_model(self, mock_client_class):
        """Gemini doğru model adıyla çağrılmalı."""
        mock_response = MagicMock()
        mock_response.text = "Özet"

        mock_client = MagicMock()
        mock_client.models.generate_content.return_value = mock_response
        mock_client_class.return_value = mock_client

        service = LLMService()
        await service.summarize("test")

        # generate_content call argümanlarını kontrol et
        call_kwargs = mock_client.models.generate_content.call_args.kwargs
        assert call_kwargs["model"] == MODEL_NAME


# ============================================================
# 7. Live Mode: Fallback Senaryoları
# ============================================================

class TestLiveModeFallback:
    """Live mode'da hata durumunda stub'a fallback testleri."""

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"GEMINI_API_KEY": "fake-key"}, clear=True)
    @patch("app.ai.llm_service.genai.Client")
    async def test_empty_response_falls_back_to_stub(self, mock_client_class):
        """Gemini boş yanıt dönerse stub'a fallback olmalı."""
        # Gemini boş yanıt
        mock_response = MagicMock()
        mock_response.text = ""

        mock_client = MagicMock()
        mock_client.models.generate_content.return_value = mock_response
        mock_client_class.return_value = mock_client

        service = LLMService()
        result = await service.summarize("test")

    
        assert "[STUB ÖZET" in result

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"GEMINI_API_KEY": "fake-key"}, clear=True)
    @patch("app.ai.llm_service.genai.Client")
    async def test_non_retryable_error_immediate_fallback(self, mock_client_class):
        """Retryable olmayan hata → hemen fallback (retry yok)."""
        mock_client = MagicMock()
        mock_client.models.generate_content.side_effect = Exception("Authentication failed")
        mock_client_class.return_value = mock_client

        service = LLMService()
        result = await service.summarize("test")

        # Non-retryable → 1 deneme, sonra fallback
        assert "[STUB ÖZET" in result
        assert mock_client.models.generate_content.call_count == 1


# ============================================================
# 8. Retry Mekanizması
# ============================================================

class TestRetryMechanism:
    """Retry mekanizması testleri (503, 429, timeout)."""

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"GEMINI_API_KEY": "fake-key"}, clear=True)
    @patch("app.ai.llm_service.asyncio.sleep", new_callable=AsyncMock)  
    @patch("app.ai.llm_service.genai.Client")
    async def test_503_error_triggers_retry(self, mock_client_class, mock_sleep):
        """503 hatası retry'ı tetiklemeli."""
        mock_client = MagicMock()
        # İlk denemede 503, ikincide başarılı
        mock_success_response = MagicMock()
        mock_success_response.text = "Başarılı özet"

        mock_client.models.generate_content.side_effect = [
            Exception("503 Service Unavailable"),
            mock_success_response,
        ]
        mock_client_class.return_value = mock_client

        service = LLMService()
        result = await service.summarize("test")

        # 2. denemede başarılı
        assert "Başarılı özet" in result
        assert mock_client.models.generate_content.call_count == 2

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"GEMINI_API_KEY": "fake-key"}, clear=True)
    @patch("app.ai.llm_service.asyncio.sleep", new_callable=AsyncMock)
    @patch("app.ai.llm_service.genai.Client")
    async def test_429_rate_limit_triggers_retry(self, mock_client_class, mock_sleep):
        """429 rate limit hatası retry'ı tetiklemeli."""
        mock_client = MagicMock()
        mock_success_response = MagicMock()
        mock_success_response.text = "Sonuç"

        mock_client.models.generate_content.side_effect = [
            Exception("429 Too Many Requests"),
            mock_success_response,
        ]
        mock_client_class.return_value = mock_client

        service = LLMService()
        result = await service.summarize("test")

        assert "Sonuç" in result
        assert mock_client.models.generate_content.call_count == 2

    @pytest.mark.asyncio
    @patch.dict(os.environ, {"GEMINI_API_KEY": "fake-key"}, clear=True)
    @patch("app.ai.llm_service.asyncio.sleep", new_callable=AsyncMock)
    @patch("app.ai.llm_service.genai.Client")
    async def test_max_retries_exhausted_falls_back(self, mock_client_class, mock_sleep):
        """Tüm retry'lar başarısız olursa fallback'e düşmeli."""
        mock_client = MagicMock()
        mock_client.models.generate_content.side_effect = Exception("503 Persistent Error")
        mock_client_class.return_value = mock_client

        service = LLMService()
        result = await service.summarize("test metin")

        # 5 deneme yapmalı (max_retries=5)
        assert mock_client.models.generate_content.call_count == 5
        # Sonra stub fallback
        assert "[STUB ÖZET" in result


# ============================================================
# 9. Prompt Engineering
# ============================================================

class TestPromptEngineering:
    """Prompt builder fonksiyonlarının testleri."""

    def setup_method(self):
        with patch.dict(os.environ, {"GEMINI_API_KEY": "", "GEMINI_MODE": "stub"}, clear=True):
            self.service = LLMService()

    def test_summary_prompt_includes_input_text(self):
        """Özet prompt'u giriş metnini içermeli."""
        text = "Test staj metni"
        prompt = self.service._build_summary_prompt(text)
        assert "Test staj metni" in prompt

    def test_summary_prompt_truncates_long_text(self):
        """Uzun metin MAX_INPUT_CHARS'da kesilmeli."""
        long_text = "a" * (MAX_INPUT_CHARS + 1000)
        prompt = self.service._build_summary_prompt(long_text)
        assert "[Defter bu noktadan sonra kesildi]" in prompt

    def test_summary_prompt_does_not_truncate_short_text(self):
        """Kısa metin truncate edilmemeli."""
        short_text = "kısa"
        prompt = self.service._build_summary_prompt(short_text)
        assert "[Defter bu noktadan sonra kesildi]" not in prompt

    def test_explanation_prompt_includes_both_texts(self):
        """Açıklama prompt'u her iki metni de içermeli."""
        prompt = self.service._build_explanation_prompt("METİN_A", "METİN_B")
        assert "METİN_A" in prompt
        assert "METİN_B" in prompt

    def test_summary_prompt_mentions_academic_tone(self):
        """Özet prompt'u akademik ton talimatı içermeli."""
        prompt = self.service._build_summary_prompt("test")
        assert "akademik" in prompt.lower()

    def test_explanation_prompt_mentions_no_definitive_judgment(self):
        """Açıklama prompt'u kesin yargı içermeme talimatı içermeli."""
        prompt = self.service._build_explanation_prompt("a", "b")
        assert "intihal kesindir" in prompt.lower() or "akademisyene ait" in prompt.lower()


# ============================================================
# 10. Singleton Pattern
# ============================================================

class TestSingleton:
    """get_llm_service singleton testleri."""

    def test_returns_same_instance(self):
        """get_llm_service aynı instance'ı dönmeli."""
        service1 = get_llm_service()
        service2 = get_llm_service()
        assert service1 is service2

    def test_singleton_is_llm_service_type(self):
        """Singleton LLMService tipinde olmalı."""
        service = get_llm_service()
        assert isinstance(service, LLMService)


# ============================================================
# 11. Constants
# ============================================================

class TestConstants:
    """Sabit değerlerin tanımlı olduğu testler."""

    def test_model_name_is_gemini_flash_lite(self):
        """MODEL_NAME doğru olmalı."""
        assert MODEL_NAME == "gemini-flash-lite-latest"

    def test_max_input_chars_is_positive(self):
        """MAX_INPUT_CHARS pozitif olmalı."""
        assert MAX_INPUT_CHARS > 0
        assert MAX_INPUT_CHARS == 15000