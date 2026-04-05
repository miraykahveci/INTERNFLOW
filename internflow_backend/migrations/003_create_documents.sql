-- Migration 003: Belgeler tablosu
-- Tarih: 2026-03-20
-- Açıklama: Öğrencilerin yüklediği staj belgelerini saklayan tablo

CREATE TYPE document_type AS ENUM ('staj_defteri', 'basvuru_formu', 'sgk_belgesi', 'anket');

CREATE TABLE documents (
    doc_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    intern_id UUID REFERENCES internship(intern_id) ON DELETE CASCADE,
    file_url TEXT NOT NULL,
    doc_type document_type NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RLS Politikaları
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can insert documents"
ON documents FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Authenticated users can read documents"
ON documents FOR SELECT
TO authenticated
USING (true);