import os

# =========================
#  Configurações de Segurança e Básicas
# =========================
# Esta variável SUPERSET_SECRET_KEY DEVE ser configurada no painel do EasyPanel.
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY", "CHANGE-ME-IN-PRODUCTION")

# Essencial para funcionar atrás do proxy reverso do EasyPanel.
ENABLE_PROXY_FIX = True

# Desabilitar o Talisman pode ser útil se o EasyPanel já gerencia headers de segurança (CSP).
TALISMAN_ENABLED = False
CONTENT_SECURITY_POLICY_WARNING = False

# =========================
#  Tradução (i18n) e Fuso Horário
# =========================
# Ativa o português do Brasil como idioma padrão.
BABEL_DEFAULT_LOCALE = "pt_BR"
LANGUAGES = {
    "pt_BR": {"flag": "br", "name": "Português (Brasil)"},
    "en": {"flag": "us", "name": "English"},
}
# Configure SUPERSET_TIMEZONE no EasyPanel ou use o padrão "America/Cuiaba".
BABEL_DEFAULT_TIMEZONE = os.environ.get("SUPERSET_TIMEZONE", "America/Cuiaba")

# =========================
#  Conexão com o Metastore (Banco de Dados do Superset)
# =========================
# O EasyPanel fornecerá estas variáveis automaticamente ao linkar um serviço de banco de dados.
_pg_host = os.environ.get("DATABASE_HOST", "postgres")
_pg_port = os.environ.get("DATABASE_PORT", "5432")
_pg_user = os.environ.get("DATABASE_USER", "superset")
_pg_pass = os.environ.get("DATABASE_PASSWORD", "")
_pg_db   = os.environ.get("DATABASE_DB", "superset")
SQLALCHEMY_DATABASE_URI = f"postgresql+psycopg2://{_pg_user}:{_pg_pass}@{_pg_host}:{_pg_port}/{_pg_db}"
SQLALCHEMY_TRACK_MODIFICATIONS = False

# =========================
#  Conexão com o Redis (Cache e Celery)
# =========================
# O EasyPanel fornecerá estas variáveis ao linkar um serviço Redis.
USE_REDIS = str(os.environ.get("USE_REDIS", "1")).lower() in ("1", "true", "yes")
_rd_host = os.environ.get("REDIS_HOST", "redis")
_rd_port = os.environ.get("REDIS_PORT", "6379")

if USE_REDIS:
    REDIS_URL = f"redis://{_rd_host}:{_rd_port}/0"
    CACHE_CONFIG = {
        "CACHE_TYPE": "RedisCache",
        "CACHE_DEFAULT_TIMEOUT": 300,
        "CACHE_KEY_PREFIX": "superset_",
        "CACHE_REDIS_URL": REDIS_URL,
    }
    CELERY_CONFIG = {
        "broker_url": REDIS_URL,
        "result_backend": REDIS_URL,
    }
else:
    CACHE_CONFIG = {"CACHE_TYPE": "SimpleCache"}

# =========================
#  Feature Flags e Customizações
# =========================
FEATURE_FLAGS = {
    "DASHBOARD_NATIVE_FILTERS": True,
    "ENABLE_TEMPLATE_PROCESSING": True,
    "ALERT_REPORTS": USE_REDIS,
}

# Suas customizações de cores, formatos, etc. (mantidas integralmente)
RATELIMIT_ENABLED = False
DEFAULT_ISO_TIME_FORMAT = "YYYY-MM-DD"
EXTRA_CATEGORICAL_COLOR_SCHEMES = [{"id": "ac_acessorios", "label": "AC Acessórios", "colors": ["#b6c947", "#3067c5", "#e17c3a", "#000000", "#ffffff", "#8fa92f", "#274f98", "#ff9a33", "#222222", "#e6e6e6"]}]
EXTRA_SEQUENTIAL_COLOR_SCHEMES = [{"id": "ac_acessorios_seq", "label": "AC Acessórios (Sequencial)", "colors": ["#e9f0c5", "#d5e48b", "#b6c947", "#86a82f", "#55761a"]}]
COLOR_SCHEME = "AC Acessórios"
CUSTOM_NUMBER_FORMATS = {"Moeda (R$ 2 casas)": "R$,.2f", "Moeda (R$ 0 casas)": "R$,.0f", "Moeda (R$ abreviado)": "R$~s"}
LABEL_COLORS = {"BALCÃO": "#b6c947", "ATACADO": "#3067c5", "VAREJO-SERVIÇO": "#e17c3a"}
