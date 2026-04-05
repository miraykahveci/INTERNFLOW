-- Migration 001: Kullanıcılar tablosu
-- Tarih: 2026-03-18
-- Açıklama: Öğrenci ve akademisyen bilgilerini tutan ana tablo

CREATE TYPE user_role AS ENUM ('student', 'academician', 'admin');

CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name VARCHAR(50) NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    role user_role NOT NULL,
    student_number INT,
    gpa FLOAT,
    title VARCHAR(50),
    department VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- RLS Politikaları
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view users"
ON users FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id
  OR
  auth.jwt() ->> 'role' = 'authenticated'
);