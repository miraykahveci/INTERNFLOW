import os
import httpx
from datetime import datetime, timezone, timedelta
from typing import Optional, Dict, Any
from supabase import create_client, Client


CACHE_FRESHNESS_DAYS = 30


def _get_supabase_admin_client() -> Client:
    url = os.getenv("SUPABASE_URL")
    service_key = os.getenv("SUPABASE_SERVICE_KEY")
    if not url or not service_key:
        raise ValueError("SUPABASE_URL veya SUPABASE_SERVICE_KEY .env dosyasında yok")
    return create_client(url, service_key)


async def _fetch_remote_metadata(url: str) -> Optional[Dict[str, Any]]:
   
    try:
        async with httpx.AsyncClient(timeout=10.0, follow_redirects=True) as client:
            response = await client.head(url)
            response.raise_for_status()
            return {
                'last_modified': response.headers.get('Last-Modified'),
                'content_length': int(response.headers.get('Content-Length', 0)),
                'etag': response.headers.get('ETag'),
                'status_code': response.status_code,
            }
    except Exception as e:
        print(f"[yonerge] HEAD request hatası: {e}")
        return None


async def _download_pdf(url: str) -> Optional[bytes]:
    """Okulun sitesinden PDF'i indir (full GET)"""
    try:
        async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
            response = await client.get(url)
            response.raise_for_status()
            return response.content
    except Exception as e:
        print(f"[yonerge] PDF indirme hatası: {e}")
        return None


def _parse_last_modified(header_value: Optional[str]) -> Optional[datetime]:
   
    if not header_value:
        return None
    try:
        
        return datetime.strptime(header_value, "%a, %d %b %Y %H:%M:%S %Z").replace(
            tzinfo=timezone.utc
        )
    except Exception:
        return None


def _is_cache_fresh(last_checked: Optional[str]) -> bool:
   
    if not last_checked:
        return False
    try:
        if isinstance(last_checked, str):
            last_checked_dt = datetime.fromisoformat(last_checked.replace('Z', '+00:00'))
        else:
            last_checked_dt = last_checked
        age = datetime.now(timezone.utc) - last_checked_dt
        return age < timedelta(days=CACHE_FRESHNESS_DAYS)
    except Exception:
        return False
    
def _storage_file_exists(supabase: Client, bucket: str, path: str) -> bool:
    
    try:
        
        files = supabase.storage.from_(bucket).list()
        target_filename = path.split('/')[-1]  # Sadece dosya adı
        return any(f.get('name') == target_filename for f in files)
    except Exception as e:
        print(f"[yonerge] Storage existence check hatası: {e}")
        return False


async def get_yonerge_info() -> Dict[str, Any]:
   
    supabase = _get_supabase_admin_client()

    
    result = supabase.table('yonerge_cache').select('*').eq('id', 1).single().execute()
    cache = result.data

    if not cache:
        return {
            'success': False,
            'error': 'Yönerge cache kaydı bulunamadı',
        }

    source_url = cache['source_url']
    storage_bucket = cache['storage_bucket']
    storage_path = cache['storage_path']

    
    cache_fresh = _is_cache_fresh(cache.get('last_checked'))

    
    file_exists_in_storage = _storage_file_exists(supabase, storage_bucket, storage_path)

    
    if cache_fresh and cache.get('last_modified') and file_exists_in_storage:
        return _build_response(cache, supabase, source='cache')

    
    force_download = not file_exists_in_storage

    if force_download:
        print(f"[yonerge] ⚠️ Storage'da dosya yok, force refresh!")

    
    print(f"[yonerge] Uzaktan kontrol ediliyor: {source_url}")
    remote_metadata = await _fetch_remote_metadata(source_url)

    if not remote_metadata:
        
        if cache.get('last_modified') and file_exists_in_storage:
            return _build_response(cache, supabase, source='cache_fallback')
        return {
            'success': False,
            'error': 'Okul sitesine erişilemiyor',
        }

    remote_last_modified = _parse_last_modified(remote_metadata['last_modified'])
    cache_last_modified = cache.get('last_modified')
    if cache_last_modified and isinstance(cache_last_modified, str):
        cache_last_modified = datetime.fromisoformat(
            cache_last_modified.replace('Z', '+00:00')
        )

    
    pdf_needs_download = force_download or (
        cache_last_modified is None
        or remote_last_modified is None
        or remote_last_modified != cache_last_modified
    )

    if pdf_needs_download:
        
        reason = "force_download (dosya Storage'da yok)" if force_download else "PDF değişmiş veya yok"
        print(f"[yonerge] {reason}, indiriliyor...")
        pdf_bytes = await _download_pdf(source_url)

        if not pdf_bytes:
            return {
                'success': False,
                'error': 'PDF indirilemedi',
            }

        
        try:
            print(f"[yonerge] Storage'a yazılıyor: bucket={storage_bucket}, path={storage_path}, size={len(pdf_bytes)} bytes")
            upload_result = supabase.storage.from_(storage_bucket).upload(
                path=storage_path,
                file=pdf_bytes,
                file_options={
                    'content-type': 'application/pdf',
                    'upsert': 'true',
                },
            )
            print(f"[yonerge] ✅ Upload sonucu: {upload_result}")
            print(f"[yonerge] ✅ PDF Storage'a kaydedildi: {storage_bucket}/{storage_path}")
        except Exception as e:
            print(f"[yonerge] ❌ Storage upload HATASI: {type(e).__name__}: {e}")
            import traceback
            traceback.print_exc()
            return {
                'success': False,
                'error': f'Storage yazma hatası: {str(e)}',
            }

    
    update_data = {
        'last_checked': datetime.now(timezone.utc).isoformat(),
        'updated_at': datetime.now(timezone.utc).isoformat(),
    }
    if remote_last_modified:
        update_data['last_modified'] = remote_last_modified.isoformat()
    if remote_metadata.get('content_length'):
        update_data['file_size'] = remote_metadata['content_length']
    if remote_metadata.get('etag'):
        update_data['etag'] = remote_metadata['etag']

    supabase.table('yonerge_cache').update(update_data).eq('id', 1).execute()

    
    result = supabase.table('yonerge_cache').select('*').eq('id', 1).single().execute()
    return _build_response(
        result.data,
        supabase,
        source='refreshed' if pdf_needs_download else 'metadata_check',
    )


def _build_response(cache: Dict[str, Any], supabase: Client, source: str) -> Dict[str, Any]:
    """Frontend için uygun response oluştur"""
    
    try:
        public_url = supabase.storage.from_(cache['storage_bucket']).get_public_url(
            cache['storage_path']
        )
    except Exception:
        public_url = None

    return {
        'success': True,
        'source': source,
        'data': {
            'last_modified': cache.get('last_modified'),
            'last_checked': cache.get('last_checked'),
            'file_size': cache.get('file_size'),
            'file_size_kb': round((cache.get('file_size') or 0) / 1024, 1),
            'source_url': cache.get('source_url'),
            'pdf_url': public_url,
            'storage_bucket': cache.get('storage_bucket'),
            'storage_path': cache.get('storage_path'),
        },
    }


async def download_yonerge_pdf() -> Optional[bytes]:
   
    
    await get_yonerge_info()

    supabase = _get_supabase_admin_client()
    result = supabase.table('yonerge_cache').select('*').eq('id', 1).single().execute()
    cache = result.data

    try:
        pdf_bytes = supabase.storage.from_(cache['storage_bucket']).download(
            cache['storage_path']
        )
        return pdf_bytes
    except Exception as e:
        print(f"[yonerge] Storage download hatası: {e}")
        return None