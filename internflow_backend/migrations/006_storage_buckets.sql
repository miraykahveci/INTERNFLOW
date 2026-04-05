-- Migration 006: Supabase Storage bucket yapılandırması
-- Tarih: 2026-04-01
-- Açıklama: Belge yükleme ve şablon indirme için Storage bucket'ları

-- 1. Öğrenci belgelerini saklayan private bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false)
ON CONFLICT (id) DO NOTHING;

-- 2. Belge şablonlarını saklayan public bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('templates', 'templates', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Politikaları (documents bucket)
CREATE POLICY "Authenticated users can upload documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'documents');

CREATE POLICY "Authenticated users can view documents"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'documents');

-- Templates bucket public olduğu için ek policy gerekmez