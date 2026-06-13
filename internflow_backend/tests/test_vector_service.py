"""
Vector Service (Embedding) Birim Testleri
==========================================
Hem LocalEmbeddingStrategy (PyTorch/sentence-transformers) hem de
APIEmbeddingStrategy (Hugging Face Inference API) test edilir.
Tüm dış bağımlılıklar MOCK'lanır - gerçek model yüklemesi/API çağrısı YOK.
"""

import os
import pytest
from unittest.mock import patch, MagicMock
import requests

pytest.importorskip("sentence_transformers")

from app.ai.vector_service import (
    EmbeddingStrategy,
    LocalEmbeddingStrategy,
    APIEmbeddingStrategy,
    _create_embedding_service,
    get_embedder,
)


# ============================================================
# 1. EmbeddingStrategy (Abstract Base Class)
# ============================================================

class TestEmbeddingStrategyABC:
    """Abstract base class davranış testleri."""

    def test_cannot_instantiate_abstract_class(self):
        """EmbeddingStrategy doğrudan örnek alınamamalı."""
        with pytest.raises(TypeError):
            EmbeddingStrategy()

    def test_abstract_methods_defined(self):
        """ABC abstract method'ları tanımlı olmalı."""
        assert hasattr(EmbeddingStrategy, "generate_embedding")
        assert hasattr(EmbeddingStrategy, "name")


# ============================================================
# 2. LocalEmbeddingStrategy
# ============================================================

class TestLocalEmbeddingStrategy:
    """Lokal sentence-transformers stratejisi testleri."""

    @patch("sentence_transformers.SentenceTransformer")
    def test_local_strategy_loads_correct_model(self, mock_st):
        """LocalEmbeddingStrategy doğru model adıyla başlatılmalı."""
        strategy = LocalEmbeddingStrategy()

        mock_st.assert_called_once_with(
            "sentence-transformers/paraphrase-multilingual-mpnet-base-v2"
        )

    @patch("sentence_transformers.SentenceTransformer")
    def test_local_strategy_name(self, mock_st):
        """name property 'local-mpnet' dönmeli."""
        strategy = LocalEmbeddingStrategy()
        assert strategy.name == "local-mpnet"

    @patch("sentence_transformers.SentenceTransformer")
    def test_local_generate_embedding_returns_list(self, mock_st):
        """generate_embedding list[float] dönmeli."""
        # Mock model setup
        mock_vector = MagicMock()
        mock_vector.tolist.return_value = [0.1, 0.2, 0.3, 0.4]

        mock_model = MagicMock()
        mock_model.encode.return_value = mock_vector
        mock_st.return_value = mock_model

        strategy = LocalEmbeddingStrategy()
        result = strategy.generate_embedding("test metin")

        assert isinstance(result, list)
        assert result == [0.1, 0.2, 0.3, 0.4]

    @patch("sentence_transformers.SentenceTransformer")
    def test_local_uses_normalize_embeddings(self, mock_st):
        """encode normalize_embeddings=True ile çağrılmalı."""
        mock_vector = MagicMock()
        mock_vector.tolist.return_value = [0.1]

        mock_model = MagicMock()
        mock_model.encode.return_value = mock_vector
        mock_st.return_value = mock_model

        strategy = LocalEmbeddingStrategy()
        strategy.generate_embedding("test")

        # encode normalize_embeddings=True ile çağrıldı mı?
        call_kwargs = mock_model.encode.call_args.kwargs
        assert call_kwargs["normalize_embeddings"] is True


# ============================================================
# 3. APIEmbeddingStrategy - Token Validation
# ============================================================

class TestAPIEmbeddingStrategyInit:
    """APIEmbeddingStrategy başlatma testleri."""

    @patch.dict(os.environ, {}, clear=True)
    def test_raises_error_without_token(self):
        """HF_API_TOKEN olmadan başlatılamaz."""
        with pytest.raises(ValueError, match="HF_API_TOKEN"):
            APIEmbeddingStrategy()

    @patch.dict(os.environ, {"HF_API_TOKEN": "hf_test_token"}, clear=True)
    def test_creates_correct_headers(self):
        """Authorization header doğru oluşmalı."""
        strategy = APIEmbeddingStrategy()
        assert strategy.headers["Authorization"] == "Bearer hf_test_token"
        assert strategy.headers["Content-Type"] == "application/json"

    @patch.dict(os.environ, {"HF_API_TOKEN": "hf_test"}, clear=True)
    def test_api_strategy_name(self):
        """name property 'api-hf-mpnet' dönmeli."""
        strategy = APIEmbeddingStrategy()
        assert strategy.name == "api-hf-mpnet"


# ============================================================
# 4. APIEmbeddingStrategy - HTTP Call (Mock'lı)
# ============================================================

class TestAPIEmbeddingStrategyHttp:
    """APIEmbeddingStrategy HTTP istek testleri (mock'lı)."""

    @patch.dict(os.environ, {"HF_API_TOKEN": "hf_test"}, clear=True)
    @patch("app.ai.vector_service.requests.post")
    def test_generate_embedding_success(self, mock_post):
        """Başarılı API yanıtı → vektör dönmeli."""
        # Mock response - direkt liste
        mock_response = MagicMock()
        mock_response.json.return_value = [0.1, 0.2, 0.3]
        mock_response.raise_for_status.return_value = None
        mock_post.return_value = mock_response

        strategy = APIEmbeddingStrategy()
        result = strategy.generate_embedding("test metin")

        assert result == [0.1, 0.2, 0.3]

    @patch.dict(os.environ, {"HF_API_TOKEN": "hf_test"}, clear=True)
    @patch("app.ai.vector_service.requests.post")
    def test_generate_embedding_nested_list_response(self, mock_post):
        """API nested list dönerse [0] alınmalı."""
        # Bazı modeller [[0.1, 0.2, 0.3]] formatında döner
        mock_response = MagicMock()
        mock_response.json.return_value = [[0.1, 0.2, 0.3]]
        mock_response.raise_for_status.return_value = None
        mock_post.return_value = mock_response

        strategy = APIEmbeddingStrategy()
        result = strategy.generate_embedding("test")

        assert result == [0.1, 0.2, 0.3]

    @patch.dict(os.environ, {"HF_API_TOKEN": "hf_test"}, clear=True)
    @patch("app.ai.vector_service.requests.post")
    def test_generate_embedding_uses_correct_url(self, mock_post):
        """Doğru API URL'i çağrılmalı."""
        mock_response = MagicMock()
        mock_response.json.return_value = [0.1]
        mock_response.raise_for_status.return_value = None
        mock_post.return_value = mock_response

        strategy = APIEmbeddingStrategy()
        strategy.generate_embedding("test")

        # URL parametresi doğru mu?
        call_args = mock_post.call_args
        assert "sentence-transformers" in call_args[0][0]
        assert "paraphrase-multilingual-mpnet" in call_args[0][0]

    @patch.dict(os.environ, {"HF_API_TOKEN": "hf_test"}, clear=True)
    @patch("app.ai.vector_service.requests.post")
    def test_http_error_raises_runtime_error(self, mock_post):
        """HTTP hatası RuntimeError'a dönüşmeli."""
        mock_response = MagicMock()
        mock_response.status_code = 500
        mock_response.text = "Internal Server Error"
        mock_response.raise_for_status.side_effect = requests.exceptions.HTTPError()
        mock_post.return_value = mock_response

        strategy = APIEmbeddingStrategy()

        with pytest.raises(RuntimeError, match="HF API hatası"):
            strategy.generate_embedding("test")

    @patch.dict(os.environ, {"HF_API_TOKEN": "hf_test"}, clear=True)
    @patch("app.ai.vector_service.requests.post")
    def test_timeout_raises_runtime_error(self, mock_post):
        """Timeout hatası RuntimeError'a dönüşmeli."""
        mock_post.side_effect = requests.exceptions.Timeout()

        strategy = APIEmbeddingStrategy()

        with pytest.raises(RuntimeError, match="zaman aşımı"):
            strategy.generate_embedding("test")

    @patch.dict(os.environ, {"HF_API_TOKEN": "hf_test"}, clear=True)
    @patch("app.ai.vector_service.requests.post")
    def test_unexpected_response_raises_value_error(self, mock_post):
        """Beklenmeyen response formatı RuntimeError dönmeli."""
        # Dict dönsün (liste değil)
        mock_response = MagicMock()
        mock_response.json.return_value = {"error": "unexpected"}
        mock_response.raise_for_status.return_value = None
        mock_post.return_value = mock_response

        strategy = APIEmbeddingStrategy()

        with pytest.raises(Exception):
            strategy.generate_embedding("test")


# ============================================================
# 5. Factory Function
# ============================================================

class TestFactoryFunction:
    """_create_embedding_service factory testleri."""

    @patch.dict(os.environ, {"EMBEDDING_MODE": "local"}, clear=True)
    @patch("sentence_transformers.SentenceTransformer")
    def test_local_mode_creates_local_strategy(self, mock_st):
        """mode='local' → LocalEmbeddingStrategy dönmeli."""
        service = _create_embedding_service()
        assert isinstance(service, LocalEmbeddingStrategy)

    @patch.dict(os.environ, {"EMBEDDING_MODE": "api", "HF_API_TOKEN": "hf_test"}, clear=True)
    def test_api_mode_creates_api_strategy(self):
        """mode='api' → APIEmbeddingStrategy dönmeli."""
        service = _create_embedding_service()
        assert isinstance(service, APIEmbeddingStrategy)

    @patch.dict(os.environ, {"EMBEDDING_MODE": "invalid"}, clear=True)
    def test_invalid_mode_raises_error(self):
        """Geçersiz mode → ValueError fırlatılmalı."""
        with pytest.raises(ValueError, match="Geçersiz EMBEDDING_MODE"):
            _create_embedding_service()

    @patch.dict(os.environ, {}, clear=True)
    @patch("sentence_transformers.SentenceTransformer")
    def test_default_mode_is_local(self, mock_st):
        """EMBEDDING_MODE env yoksa default 'local' olmalı."""
        service = _create_embedding_service()
        assert isinstance(service, LocalEmbeddingStrategy)

    @patch.dict(os.environ, {"EMBEDDING_MODE": "LOCAL"}, clear=True)
    @patch("sentence_transformers.SentenceTransformer")
    def test_mode_is_case_insensitive(self, mock_st):
        """mode büyük/küçük harf duyarsız olmalı."""
        service = _create_embedding_service()
        assert isinstance(service, LocalEmbeddingStrategy)


# ============================================================
# 6. Singleton Pattern
# ============================================================

class TestSingleton:
    """get_embedder singleton testleri."""

    def setup_method(self):
        """Her test öncesi singleton sıfırla."""
        import app.ai.vector_service as vs
        vs._embedder_instance = None

    @patch.dict(os.environ, {"EMBEDDING_MODE": "local"}, clear=True)
    @patch("sentence_transformers.SentenceTransformer")
    def test_returns_same_instance(self, mock_st):
        """get_embedder aynı instance'ı dönmeli."""
        embedder1 = get_embedder()
        embedder2 = get_embedder()
        assert embedder1 is embedder2

    @patch.dict(os.environ, {"EMBEDDING_MODE": "local"}, clear=True)
    @patch("sentence_transformers.SentenceTransformer")
    def test_singleton_is_embedding_strategy(self, mock_st):
        """Singleton EmbeddingStrategy tipinde olmalı."""
        embedder = get_embedder()
        assert isinstance(embedder, EmbeddingStrategy)


# ============================================================
# 7. Integration: Strategy Pattern Çalışıyor
# ============================================================

class TestStrategyPattern:
    """Strategy pattern davranış testleri."""

    @patch("sentence_transformers.SentenceTransformer")
    def test_local_strategy_is_embedding_strategy(self, mock_st):
        """LocalEmbeddingStrategy EmbeddingStrategy tipinde."""
        strategy = LocalEmbeddingStrategy()
        assert isinstance(strategy, EmbeddingStrategy)

    @patch.dict(os.environ, {"HF_API_TOKEN": "hf_test"}, clear=True)
    def test_api_strategy_is_embedding_strategy(self):
        """APIEmbeddingStrategy EmbeddingStrategy tipinde."""
        strategy = APIEmbeddingStrategy()
        assert isinstance(strategy, EmbeddingStrategy)

    @patch("sentence_transformers.SentenceTransformer")
    def test_strategies_have_different_names(self, mock_st):
        """İki strateji farklı isimlere sahip olmalı."""
        with patch.dict(os.environ, {"HF_API_TOKEN": "hf_test"}, clear=True):
            local = LocalEmbeddingStrategy()
            api = APIEmbeddingStrategy()
            assert local.name != api.name