from supabase import create_client, Client
from app.core.config import SUPABASE_URL, SUPABASE_KEY, SUPABASE_SERVICE_KEY

# Supabase bağlantısını kuruyoruz
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
supabase_admin: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)