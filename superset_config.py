import os

# =========================
#  Configurações de Segurança e Básicas
# =========================
# Lê a SECRET_KEY diretamente da sua variável de ambiente. Essencial para a segurança.
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY")

# Necessário para o Superset funcionar corretamente atrás do proxy reverso do EasyPanel.
ENABLE_PROXY_FIX = True

# =========================
#  Tradução (i18n) e Fuso Horário
# =========================
# Ativa o português do Brasil como o idioma padrão da interface.
BABEL_DEFAULT_LOCALE = "pt_BR"
LANGUAGES = {
    "pt_BR": {"flag": "br", "name": "Português (Brasil)"},
    "en": {"flag": "us", "name": "English"},
}
# Lê o fuso horário da sua variável de ambiente SUPERSET_TIMEZONE.
BABEL_DEFAULT_TIMEZONE = os.environ.get("SUPERSET_TIMEZONE", "America/Cuiaba")

# =========================
#  Conexão com o Metastore (Banco de Dados do Superset)
# =========================
# Monta a string de conexão usando as variáveis DATABASE_* fornecidas pelo EasyPanel.
_pg_host = os.environ.get("DATABASE_HOST")
_pg_port = os.environ.get("DATABASE_PORT")
_pg_user = os.environ.get("DATABASE_USER")
_pg_pass = os.environ.get("DATABASE_PASSWORD")
_pg_db   = os.environ.get("DATABASE_DB")
SQLALCHEMY_DATABASE_URI = f"postgresql+psycopg2://{_pg_user}:{_pg_pass}@{_pg_host}:{_pg_port}/{_pg_db}"
SQLALCHEMY_TRACK_MODIFICATIONS = False

# =========================
#  Conexão com o Redis (Cache e Tarefas em Background)
# =========================
# Monta a configuração do Redis usando as variáveis REDIS_* fornecidas pelo EasyPanel.
_rd_host = os.environ.get("REDIS_HOST")
_rd_port = os.environ.get("REDIS_PORT")
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

# =========================
#  Feature Flags Essenciais
# =========================
# Ativa funcionalidades úteis e recomendadas do Superset.
FEATURE_FLAGS = {
    "DASHBOARD_NATIVE_FILTERS": True,
    "ENABLE_TEMPLATE_PROCESSING": True,
    "ALERT_REPORTS": True, # Habilita alertas e relatórios, que dependem do Redis.
}

# Suas customizações de cores, formatos, etc. (mantidas integralmente)
RATELIMIT_ENABLED = False
DEFAULT_ISO_TIME_FORMAT = "YYYY-MM-DD"
EXTRA_CATEGORICAL_COLOR_SCHEMES = [{"id": "ac_acessorios", "label": "AC Acessórios", "colors": ["#b6c947", "#3067c5", "#e17c3a", "#000000", "#ffffff", "#8fa92f", "#274f98", "#ff9a33", "#222222", "#e6e6e6"]}]
EXTRA_SEQUENTIAL_COLOR_SCHEMES = [{"id": "ac_acessorios_seq", "label": "AC Acessórios (Sequencial)", "colors": ["#e9f0c5", "#d5e48b", "#b6c947", "#86a82f", "#55761a"]}]
COLOR_SCHEME = "AC Acessórios"
CUSTOM_NUMBER_FORMATS = {"Moeda (R$ 2 casas)": "R$,.2f", "Moeda (R$ 0 casas)": "R$,.0f", "Moeda (R$ abreviado)": "R$~s"}
LABEL_COLORS = {"BALCÃO": "#b6c947", "ATACADO": "#3067c5", "VAREJO-SERVIÇO": "#e17c3a"}
