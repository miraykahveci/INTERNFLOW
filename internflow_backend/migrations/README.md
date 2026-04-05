# Veritabanı Migration Dosyaları

Bu klasör, InternFlow projesinin PostgreSQL veritabanı şemasını adım adım oluşturan SQL migration dosyalarını içerir.

## Çalıştırma Sırası

Migration dosyaları numaralandırılmış sırayla çalıştırılmalıdır:

| Dosya | Açıklama | Dönem |
|-------|----------|-------|
| `001_create_users.sql` | Kullanıcılar tablosu ve rolleri | Vize |
| `002_create_internship.sql` | Staj başvuru ve süreç tablosu | Vize |
| `003_create_documents.sql` | Belge yükleme tablosu | Vize |
| `004_create_notifications.sql` | Bildirim sistemi tablosu | Vize |
| `005_create_analysis_result.sql` | AI analiz sonuçları (pgvector) | Final |
| `006_storage_buckets.sql` | Supabase Storage yapılandırması | Vize |

## Kurulum

Supabase Dashboard → SQL Editor üzerinden dosyaları sırayla çalıştırın:

```bash
# Veya supabase CLI ile:
supabase db push
```

## Ortam

- **Veritabanı:** PostgreSQL 15 (Supabase)
- **Eklentiler:** pgvector (AI analiz modülü için)
- **Güvenlik:** Row Level Security (RLS) tüm tablolarda aktif