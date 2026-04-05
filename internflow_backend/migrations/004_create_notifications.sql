-- Migration 004: Bildirimler tablosu
-- Tarih: 2026-03-20
-- Açıklama: Öğrenci ve akademisyenlere gönderilen sistem bildirimlerini saklayan tablo

CREATE TYPE notification_type AS ENUM ('info', 'warning', 'success', 'error');

CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    type notification_type NOT NULL DEFAULT 'info',
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RLS Politikaları
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert notifications"
ON notifications FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Users can view their own notifications"
ON notifications FOR SELECT
TO authenticated
USING (auth.uid() = user_id);