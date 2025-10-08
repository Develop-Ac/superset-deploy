import os

# =========================
#  Segurança / básicos
# =========================
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY") or os.environ.get("SECRET_KEY") or "CHANGE-ME"
ENABLE_PROXY_FIX = True  # útil atrás do EasyPanel / reverse proxy

# (opcional) desabilitar o warning de CSP se você for tratar isso externamente
TALISMAN_ENABLED = False
CONTENT_SECURITY_POLICY_WARNING = False

# ==== i18n / Locale / Timezone ====
BABEL_DEFAULT_LOCALE = "pt"
BABEL_DEFAULT_TIMEZONE = os.environ.get("SUPERSET_TIMEZONE", "America/Cuiaba")
LANGUAGES = {
    "pt": {"flag": "br", "name": "Português (Brasil)"},
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
RATELIMIT_ENABLED = False

# =========================
#  Dica para time formats comuns (SQL Server)
# =========================
DEFAULT_ISO_TIME_FORMAT = "YYYY-MM-DD"

# ---- Paleta AC Acessórios (categorical) ----
EXTRA_CATEGORICAL_COLOR_SCHEMES = [
    {
        "id": "ac_acessorios",
        "label": "AC Acessórios",
        "isDiverging": False,
        "colors": [
            "#b6c947",  # verde
            "#3067c5",  # azul
            "#e17c3a",  # laranja
            "#000000",  # preto 
            "#ffffff",  # branco (use com cuidado em fills)
            "#8fa92f",  # tons derivados (opcional)
            "#274f98",
            "#ff9a33",
            "#222222",
            "#e6e6e6"
        ],
    }
]

# (opcional) uma escala sequencial combinando com a marca
EXTRA_SEQUENTIAL_COLOR_SCHEMES = [
    {
        "id": "ac_acessorios_seq",
        "label": "AC Acessórios (Sequencial)",
        "isDiverging": False,
        "colors": [
            "#e9f0c5", "#d5e48b", "#b6c947", "#86a82f", "#55761a"
        ],
    }
]

# Deixe esta como default no Explore (opcional)
COLOR_SCHEME = "AC Acessórios"

# Formatos de número personalizados (aparecem nos selects de formato)
CUSTOM_NUMBER_FORMATS = {
    # usa separadores do pt-BR e 2 casas
    "Moeda (R$ 2 casas)": "R$,.2f",
    # sem casas decimais
    "Moeda (R$ 0 casas)": "R$,.0f",
    # abreviado: mil (k), milhão (M), etc.
    "Moeda (R$ abreviado)": "R$~s",
}

# ---- Cores fixas por label ----
LABEL_COLORS = {
    "BALCÃO": "#b6c947",         # verde
    "ATACADO": "#3067c5",        # azul
    "VAREJO-SERVIÇO": "#e17c3a", # laranja
}

