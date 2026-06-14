"""
InternFlow Backend - Performans Testi
=======================================
Locust ile API yük testi.

Kullanım:
    Terminal 1: uvicorn app.main:app --reload
    Terminal 2: locust -f locustfile.py --host http://localhost:8000
    Browser:    http://localhost:8089
"""

from locust import HttpUser, task, between


class InternFlowUser(HttpUser):
    """Sanal kullanıcıyı simüle eder."""

    # Her istek arasında 1-3 saniye bekleme 
    wait_time = between(1, 3)

    # ============================================================
    # GÖREV 1: Health Check (en sık, en hızlı)
    # ============================================================
    @task(3)
    def health_check(self):
        self.client.get("/health", name="GET /health")

    # ============================================================
    # GÖREV 2: Analysis Health
    # ============================================================
    @task(2)
    def analysis_health(self):
        self.client.get("/api/v1/analysis/health", name="GET /analysis/health")

    # ============================================================
    # GÖREV 3: Analiz Listesi (DB yoğun)
    # ============================================================
    @task(2)
    def list_analyses(self):
        self.client.get("/api/v1/ai/analyses", name="GET /ai/analyses")

    # ============================================================
    # GÖREV 4: Başvuru Listesi
    # ============================================================
    @task(1)
    def list_applications(self):
        self.client.get("/api/v1/applications", name="GET /applications")

    # ============================================================
    # GÖREV 5: Yönerge Bilgisi (External Proxy)
    # ============================================================
    @task(1)
    def yonerge_info(self):
        self.client.get("/api/v1/yonerge/info", name="GET /yonerge/info")