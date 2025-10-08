import os

# --- Secret (obrigatório em produção) ---
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY") or os.environ.get("SECRET_KEY") or "CHANGE-ME"

# --- Carregar exemplos (opcional) ---
LOAD_EXAMPLES = str(os.environ.get("SUPERSET_LOAD_EXAMPLES", "false")).lower() in ("1", "true", "yes", "y")

# --- Postgres (metastore) ---
_pg_host = os.environ.get("DATABASE_HOST", "postgres")
_pg_port = os.environ.get("DATABASE_PORT", "5432")
_pg_user = os.environ.get("DATABASE_USER", "superset")
_pg_pass = os.environ.get("DATABASE_PASSWORD", "")
_pg_db   = os.environ.get("DATABASE_DB", "superset")

SQLALCHEMY_DATABASE_URI = f"postgresql+psycopg2://{_pg_user}:{_pg_pass}@{_pg_host}:{_pg_port}/{_pg_db}"

# --- Redis (cache + celery) ---
_rd_host = os.environ.get("REDIS_HOST", "redis")
_rd_port = os.environ.get("REDIS_PORT", "6379")
# Use db 0 para cache; 1 e 2 para celery (boa prática, como você fez)
REDIS_CACHE_URL = f"redis://{_rd_host}:{_rd_port}/0"
REDIS_BROKER_URL = f"redis://{_rd_host}:{_rd_port}/1"
REDIS_RESULT_URL = f"redis://{_rd_host}:{_rd_port}/2"

CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_DEFAULT_TIMEOUT": 300,
    "CACHE_KEY_PREFIX": "superset_",
    "CACHE_REDIS_URL": REDIS_CACHE_URL,
}

# Celery (filas / relatórios / thumbnails)
CELERY_BROKER_URL = REDIS_BROKER_URL
CELERY_RESULT_BACKEND = REDIS_RESULT_URL

# Opcional: classe de config explícita (não é obrigatório nas versões atuais)
class CeleryConfig(object):
    broker_url = REDIS_BROKER_URL
    result_backend = REDIS_RESULT_URL
CELERY_CONFIG = CeleryConfig

# Rodando atrás de proxy/reverso do EasyPanel
ENABLE_PROXY_FIX = True

BABEL_DEFAULT_LOCALE = "pt_BR"
BABEL_DEFAULT_TIMEZONE = "America/Cuiaba"
LANGUAGES = {
  "pt_BR": {"flag": "br", "name": "Português (Brasil)"},
  "en": {"flag": "us", "name": "English"},
}

