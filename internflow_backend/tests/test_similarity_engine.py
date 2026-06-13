"""
Similarity Engine Birim Testleri
=================================
Cosine similarity hesaplama ve risk sınıflandırma mantığı.
pgvector RPC çağrıları unittest.mock ile izole edilir.
"""

import pytest
from unittest.mock import patch, MagicMock
from app.ai.similarity_engine import (
    SimilarityEngine,
    get_similarity_engine,
    HIGH_RISK_THRESHOLD,
    MEDIUM_RISK_THRESHOLD,
)


# ============================================================
# 1. Risk Threshold Sabitleri
# ============================================================

class TestRiskThresholds:
    """Risk eşik değerleri doğru tanımlı olmalı."""

    def test_high_risk_threshold_value(self):
        """HIGH_RISK_THRESHOLD 0.80 olmalı."""
        assert HIGH_RISK_THRESHOLD == 0.80

    def test_medium_risk_threshold_value(self):
        """MEDIUM_RISK_THRESHOLD 0.60 olmalı."""
        assert MEDIUM_RISK_THRESHOLD == 0.60

    def test_high_greater_than_medium(self):
        """HIGH threshold MEDIUM'dan büyük olmalı."""
        assert HIGH_RISK_THRESHOLD > MEDIUM_RISK_THRESHOLD


# ============================================================
# 2. calculate_risk_level — Threshold Mantığı
# ============================================================

class TestCalculateRiskLevel:
    """Risk seviyesi hesaplama testleri."""

    def setup_method(self):
        self.engine = SimilarityEngine()

    def test_very_high_score_is_high_risk(self):
        """0.95 skor → HIGH risk."""
        assert self.engine.calculate_risk_level(0.95) == "high"

    def test_perfect_match_is_high_risk(self):
        """1.0 skor (mükemmel eşleşme) → HIGH risk."""
        assert self.engine.calculate_risk_level(1.0) == "high"

    def test_threshold_high_boundary(self):
        """Tam 0.80 sınırı → HIGH risk (>=)."""
        assert self.engine.calculate_risk_level(0.80) == "high"

    def test_just_below_high_is_medium(self):
        """0.79 → MEDIUM risk."""
        assert self.engine.calculate_risk_level(0.79) == "medium"

    def test_mid_range_is_medium(self):
        """0.70 → MEDIUM risk."""
        assert self.engine.calculate_risk_level(0.70) == "medium"

    def test_threshold_medium_boundary(self):
        """Tam 0.60 sınırı → MEDIUM risk (>=)."""
        assert self.engine.calculate_risk_level(0.60) == "medium"

    def test_just_below_medium_is_low(self):
        """0.59 → LOW risk."""
        assert self.engine.calculate_risk_level(0.59) == "low"

    def test_low_score_is_low_risk(self):
        """0.30 → LOW risk."""
        assert self.engine.calculate_risk_level(0.30) == "low"

    def test_zero_score_is_low_risk(self):
        """0.0 → LOW risk."""
        assert self.engine.calculate_risk_level(0.0) == "low"


# ============================================================
# 3. is_risky — Boolean Geriye Uyumluluk
# ============================================================

class TestIsRisky:
    """is_risky() boolean wrapper testleri."""

    def setup_method(self):
        self.engine = SimilarityEngine()

    def test_high_score_is_risky(self):
        """Yüksek skor risky olmalı."""
        assert self.engine.is_risky(0.95) is True

    def test_threshold_score_is_risky(self):
        """Tam threshold (0.80) risky olmalı."""
        assert self.engine.is_risky(0.80) is True

    def test_medium_score_not_risky(self):
        """MEDIUM seviye risky değil."""
        assert self.engine.is_risky(0.70) is False

    def test_low_score_not_risky(self):
        """Düşük skor risky değil."""
        assert self.engine.is_risky(0.30) is False


# ============================================================
# 4. find_similar_analyses — pgvector RPC Mock'lu
# ============================================================

class TestFindSimilarAnalyses:
    """Supabase RPC ile pgvector benzerlik arama testleri."""

    def setup_method(self):
        self.engine = SimilarityEngine()
        self.dummy_vector = [0.1] * 768
        self.exclude_id = "00000000-0000-0000-0000-000000000000"

    @patch("app.ai.similarity_engine.supabase")
    def test_returns_matches_from_rpc(self, mock_supabase):
        """RPC başarılı dönerse eşleşmeler döndürülmeli."""
        # ARRANGE - mock setup
        mock_response = MagicMock()
        mock_response.data = [
            {"document_id": "doc-1", "similarity": 0.95},
            {"document_id": "doc-2", "similarity": 0.85},
        ]
        mock_supabase.rpc.return_value.execute.return_value = mock_response

        # ACT
        result = self.engine.find_similar_analyses(
            query_embedding=self.dummy_vector,
            exclude_document_id=self.exclude_id,
            match_count=5,
        )

        # ASSERT
        assert len(result) == 2
        assert result[0]["similarity"] == 0.95

    @patch("app.ai.similarity_engine.supabase")
    def test_calls_rpc_with_correct_params(self, mock_supabase):
        """RPC doğru parametrelerle çağrılmalı."""
        mock_supabase.rpc.return_value.execute.return_value = MagicMock(data=[])

        self.engine.find_similar_analyses(
            query_embedding=self.dummy_vector,
            exclude_document_id=self.exclude_id,
            match_count=3,
        )

        # match_analysis fonksiyonu çağrılmış mı?
        mock_supabase.rpc.assert_called_once()
        call_args = mock_supabase.rpc.call_args
        assert call_args[0][0] == "match_analysis"
        assert call_args[0][1]["match_count"] == 3

    @patch("app.ai.similarity_engine.supabase")
    def test_returns_empty_list_when_no_matches(self, mock_supabase):
        """Hiç eşleşme yoksa boş liste dönmeli."""
        mock_response = MagicMock()
        mock_response.data = []
        mock_supabase.rpc.return_value.execute.return_value = mock_response

        result = self.engine.find_similar_analyses(
            query_embedding=self.dummy_vector,
            exclude_document_id=self.exclude_id,
        )

        assert result == []

    @patch("app.ai.similarity_engine.supabase")
    def test_returns_empty_when_rpc_returns_none(self, mock_supabase):
        """RPC None döndürürse boş liste dönmeli."""
        mock_response = MagicMock()
        mock_response.data = None
        mock_supabase.rpc.return_value.execute.return_value = mock_response

        result = self.engine.find_similar_analyses(
            query_embedding=self.dummy_vector,
            exclude_document_id=self.exclude_id,
        )

        assert result == []

    @patch("app.ai.similarity_engine.supabase")
    def test_handles_rpc_exception_gracefully(self, mock_supabase):
        """RPC exception atarsa boş liste dönmeli (graceful fallback)."""
        mock_supabase.rpc.side_effect = Exception("Database connection error")

        result = self.engine.find_similar_analyses(
            query_embedding=self.dummy_vector,
            exclude_document_id=self.exclude_id,
        )

        assert result == []

    @patch("app.ai.similarity_engine.supabase")
    def test_default_match_count_is_5(self, mock_supabase):
        """match_count parametresi verilmezse 5 olmalı."""
        mock_supabase.rpc.return_value.execute.return_value = MagicMock(data=[])

        self.engine.find_similar_analyses(
            query_embedding=self.dummy_vector,
            exclude_document_id=self.exclude_id,
        )

        call_args = mock_supabase.rpc.call_args
        assert call_args[0][1]["match_count"] == 5


# ============================================================
# 5. get_top_match — En Yüksek Skoru Döndür
# ============================================================

class TestGetTopMatch:
    """En yüksek skorlu eşleşmeyi döndürme testleri."""

    def setup_method(self):
        self.engine = SimilarityEngine()
        self.dummy_vector = [0.1] * 768
        self.exclude_id = "00000000-0000-0000-0000-000000000000"

    @patch("app.ai.similarity_engine.supabase")
    def test_returns_top_match_when_exists(self, mock_supabase):
        """En yüksek eşleşme varsa onu döndürmeli."""
        mock_response = MagicMock()
        mock_response.data = [
            {"document_id": "doc-1", "similarity": 0.95},
        ]
        mock_supabase.rpc.return_value.execute.return_value = mock_response

        result = self.engine.get_top_match(
            query_embedding=self.dummy_vector,
            exclude_document_id=self.exclude_id,
        )

        assert result is not None
        assert result["similarity"] == 0.95

    @patch("app.ai.similarity_engine.supabase")
    def test_returns_none_when_no_matches(self, mock_supabase):
        """Hiç eşleşme yoksa None dönmeli."""
        mock_response = MagicMock()
        mock_response.data = []
        mock_supabase.rpc.return_value.execute.return_value = mock_response

        result = self.engine.get_top_match(
            query_embedding=self.dummy_vector,
            exclude_document_id=self.exclude_id,
        )

        assert result is None

    @patch("app.ai.similarity_engine.supabase")
    def test_get_top_match_uses_match_count_1(self, mock_supabase):
        """get_top_match RPC'ye match_count=1 ile istek atmalı."""
        mock_supabase.rpc.return_value.execute.return_value = MagicMock(data=[])

        self.engine.get_top_match(
            query_embedding=self.dummy_vector,
            exclude_document_id=self.exclude_id,
        )

        call_args = mock_supabase.rpc.call_args
        assert call_args[0][1]["match_count"] == 1


# ============================================================
# 6. Singleton Pattern
# ============================================================

class TestSingleton:
    """get_similarity_engine singleton testleri."""

    def test_returns_singleton_instance(self):
        """get_similarity_engine aynı instance'ı dönmeli."""
        engine1 = get_similarity_engine()
        engine2 = get_similarity_engine()
        assert engine1 is engine2

    def test_singleton_is_similarity_engine_type(self):
        """Singleton SimilarityEngine tipinde olmalı."""
        engine = get_similarity_engine()
        assert isinstance(engine, SimilarityEngine)


# ============================================================
# 7. Real World Scenarios - Demo Senaryolar
# ============================================================

class TestRealWorldScenarios:
    """Gerçek demo senaryoları (Miray-Ahmet, Leyla, Meryem)."""

    def setup_method(self):
        self.engine = SimilarityEngine()

    def test_ahmet_miray_scenario_high_risk(self):
        """Ahmet-Miray %97 benzerlik → HIGH risk."""
        assert self.engine.calculate_risk_level(0.97) == "high"
        assert self.engine.is_risky(0.97) is True

    def test_leyla_ahmet_scenario_high_risk(self):
        """Leyla-Ahmet %95 benzerlik → HIGH risk."""
        assert self.engine.calculate_risk_level(0.95) == "high"

    def test_meryem_clean_diary_low_risk(self):
        """Meryem temiz defter %44 → LOW risk."""
        assert self.engine.calculate_risk_level(0.445) == "low"
        assert self.engine.is_risky(0.445) is False