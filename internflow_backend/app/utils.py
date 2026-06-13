"""
InternFlow Utility Functions
============================
Tek görevli, pure helper fonksiyonlar.
Yan etkisiz, kolay test edilebilir.
"""
from datetime import date, timedelta


# ===========================================================
# Tarih / İş Günü Hesaplamaları
# ===========================================================

def calculate_business_days(start: date, end: date) -> int:
    """
    İki tarih arasındaki iş günü sayısını hesaplar (hafta sonları hariç).
    
    Args:
        start: Başlangıç tarihi (dahil)
        end:   Bitiş tarihi (dahil)
    
    Returns:
        İş günü sayısı (Pazartesi-Cuma arası)
    """
    if end < start:
        return 0
    
    days = 0
    current = start
    while current <= end:
        if current.weekday() < 5:  # Pazartesi=0, Cuma=4
            days += 1
        current += timedelta(days=1)
    return days


# ===========================================================
# Staj Durum Geçişi (State Machine)
# ===========================================================

# Staj statüsü için izinli geçiş haritası
VALID_STATUS_TRANSITIONS = {
    "pending":   ["approved", "rejected"],
    "approved":  ["active"],
    "active":    ["completed"],
    "rejected":  ["pending"],   # Yeniden başvuru
    "completed": [],             # Terminal state
}


def is_valid_status_transition(current: str, new: str) -> bool:
    """
    Bir staj durumundan diğerine geçişin geçerli olup olmadığını kontrol eder.
    
    Args:
        current: Mevcut durum
        new:     Hedef durum
    
    Returns:
        Geçiş geçerliyse True
    """
    return new in VALID_STATUS_TRANSITIONS.get(current, [])


def get_allowed_transitions(current: str) -> list[str]:
    """Bir durumdan yapılabilecek tüm geçişleri döner."""
    return VALID_STATUS_TRANSITIONS.get(current, [])