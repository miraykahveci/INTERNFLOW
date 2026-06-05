from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
import io

from app.services.yonerge_service import get_yonerge_info, download_yonerge_pdf

router = APIRouter(prefix="/yonerge", tags=["Yönerge"])


@router.get("/info")
async def yonerge_info():
    
    try:
        result = await get_yonerge_info()
        if not result.get('success'):
            raise HTTPException(
                status_code=503,
                detail=result.get('error', 'Yönerge bilgisi alınamadı'),
            )
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Sunucu hatası: {str(e)}")


@router.get("/download")
async def yonerge_download():
    """
    Yönerge PDF'ini indirir (stream).
    Önce freshness check yapar, sonra Storage'dan stream eder.
    """
    try:
        pdf_bytes = await download_yonerge_pdf()
        if not pdf_bytes:
            raise HTTPException(status_code=404, detail="Yönerge PDF bulunamadı")

        return StreamingResponse(
            io.BytesIO(pdf_bytes),
            media_type="application/pdf",
            headers={
                "Content-Disposition": 'inline; filename="staj_yonergesi.pdf"',
                "Cache-Control": "public, max-age=3600",  
            },
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"PDF indirme hatası: {str(e)}")