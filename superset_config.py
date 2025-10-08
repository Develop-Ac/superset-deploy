import os

# =========================
#  Segurança / básicos
# =========================
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY") or os.environ.get("SECRET_KEY") or "CHANGE-ME"
ENABLE_PROXY_FIX = True  # útil atrás do EasyPanel / reverse proxy

# (opcional) desabilitar o warning de CSP se você for tratar isso externamente
TALISMAN_ENABLED = False
CONTENT_SECURITY_POLICY_WARNING = False

# =========================
#  Idioma e timezone
# =========================
BABEL_DEFAULT_LOCALE = "pt_BR"
BABEL_DEFAULT_TIMEZONE = os.environ.get("SUPERSET_TIMEZONE", "America/Cuiaba")
LANGUAGES = {
    "pt_BR": {"flag": "br", "name": "Português (Brasil)"},
    "en": {"flag": "us", "name": "English"},
}

# =========================
#  Metastore (Postgres)
# =========================
_pg_host = os.environ.get("DATABASE_HOST", "postgres")
_pg_port = os.environ.get("DATABASE_PORT", "5432")
_pg_user = os.environ.get("DATABASE_USER", "superset")
_pg_pass = os.environ.get("DATABASE_PASSWORD", "")
_pg_db   = os.environ.get("DATABASE_DB", "superset")

SQLALCHEMY_DATABASE_URI = f"postgresql+psycopg2://{_pg_user}:{_pg_pass}@{_pg_host}:{_pg_port}/{_pg_db}"
SQLALCHEMY_TRACK_MODIFICATIONS = False

# =========================
#  Redis (cache/celery) com fallback
# =========================
# Defina USE_REDIS=0 no EasyPanel se ainda não tiver Redis funcional.
USE_REDIS = str(os.environ.get("USE_REDIS", "1")).lower() in ("1", "true", "yes", "y")

_rd_host = os.environ.get("REDIS_HOST", "redis")
_rd_port = os.environ.get("REDIS_PORT", "6379")

if USE_REDIS:
    REDIS_CACHE_URL   = f"redis://{_rd_host}:{_rd_port}/0"
    REDIS_BROKER_URL  = f"redis://{_rd_host}:{_rd_port}/1"
    REDIS_RESULT_URL  = f"redis://{_rd_host}:{_rd_port}/2"

    CACHE_CONFIG = {
        "CACHE_TYPE": "RedisCache",
        "CACHE_DEFAULT_TIMEOUT": 300,
        "CACHE_KEY_PREFIX": "superset_",
        "CACHE_REDIS_URL": REDIS_CACHE_URL,
    }

    CELERY_BROKER_URL = REDIS_BROKER_URL
    CELERY_RESULT_BACKEND = REDIS_RESULT_URL

    class CeleryConfig(object):
        broker_url = REDIS_BROKER_URL
        result_backend = REDIS_RESULT_URL

    CELERY_CONFIG = CeleryConfig
else:
    # Fallback para SimpleCache (sem Redis). Evita erro de conexão e permite iniciar.
    CACHE_CONFIG = {"CACHE_TYPE": "SimpleCache"}
    CELERY_BROKER_URL = None
    CELERY_RESULT_BACKEND = None
    CELERY_CONFIG = None

# =========================
#  Feature Flags úteis
# =========================
FEATURE_FLAGS = {
    "DASHBOARD_NATIVE_FILTERS": True,
    "ENABLE_TEMPLATE_PROCESSING": True,
    "ALERT_REPORTS": USE_REDIS,  # precisa de Celery/Redis
}

# =========================
#  Ajustes de desempenho
# =========================
# Evita warnings de rate limit sem backend
RATELIMIT_ENABLED = false

# =========================
#  Dica para time formats comuns (SQL Server)
# =========================
DEFAULT_ISO_TIME_FORMAT = "YYYY-MM-DD"

COLOR_SCHEMES = {
    "AC Acessórios": {
        "id": "ac-acessorios",
        "label": "AC Acessórios",
        "description": "Paleta de cores corporativa da AC Acessórios",
        "colors": [
            "#3067c5",  # azul principal
            "#b6c947",  # verde AC
            "#de7800",  # laranja AC
            "#000000",  # preto
            "#ffffff",  # branco
            "#5a7bd3",  # azul secundário
            "#92aa3d",  # verde oliva
            "#f3a24a",  # laranja claro
            "#666666",  # cinza
            "#9bb6f8",  # azul claro
            "#d0db80"   # verde claro
        ],
        "is_default": True  # define como padrão para novos gráficos
    }
}
