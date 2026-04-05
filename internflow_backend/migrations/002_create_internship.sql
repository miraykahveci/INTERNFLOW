-- Migration 002: Staj süreci tablosu
-- Tarih: 2026-03-18
-- Açıklama: Öğrenci staj başvurularını ve süreç durumlarını yöneten tablo

CREATE TYPE internship_status AS ENUM ('pending', 'approved', 'active', 'completed', 'rejected');

CREATE TABLE internship (
    intern_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    academician_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    company_name VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status internship_status DEFAULT 'pending',
    internship_type VARCHAR DEFAULT 'summer',
    company_sector VARCHAR,
    company_address TEXT,
    company_email VARCHAR,
    supervisor_name VARCHAR,
    has_sgk BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);