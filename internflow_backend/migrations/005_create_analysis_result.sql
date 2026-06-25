-- Migration 005: AI Analiz sonuçları tablosu
-- Tarih: 2026-03-20
-- Açıklama: Yapay zeka modülünün ürettiği özet, benzerlik ve risk sonuçlarını saklayan tablo


CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE analysis_result (
    analysis_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID REFERENCES documents(doc_id) ON DELETE CASCADE,
    similar_document_id UUID REFERENCES documents(doc_id) ON DELETE SET NULL,
    ai_summary TEXT,
    embedding vector(768),
    is_risky BOOLEAN DEFAULT FALSE,
    plagiarism_score FLOAT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);